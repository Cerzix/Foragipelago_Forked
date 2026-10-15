"""Mock of the Archipelago Forager Client's local HTTP API, to test the mod without an Archipelago server.

It answers the same endpoints as the real client (worlds/forager/Client.py), on the same port:
    GET  /Items        -> {"Gear": {"pickaxe": 2, ...}, "Skills": [0, 1, ...]}  (64 skills)
    GET  /Datapackage  -> {"Gear": {<gear>: <crafting checks done>}, "Goal": "level", "GoalLevel": 65, "EasierCraft": 0}
    POST /Locations    <- {"Locations": [202, 302, ...]}
    POST /Goal
    POST /Death        the player died (DeathLink)
    GET  /Deathpoll    -> {"Death": 1, "Cause": "..."} once after the "kill" command, else {"Death": 0, "Cause": ""}

Do not run it at the same time as the real Forager Client, both use port 8000.
Type "help" in the console for the commands.
"""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import threading

PORT = 8000

# Progressive item counts in the apworld, keyed by the names the mod uses
gear_max = {
    "pickaxe": 8, "shovel": 5, "sword": 8, "bow": 8, "amulet": 8, "wallet": 8, "gloves": 8, "book": 8,
    "boots": 8, "backpack": 5, "fire rod": 2, "thunder rod": 2, "ice rod": 2, "necro rod": 2,
    "hammer": 1, "fishing rod": 1, "obliterator": 1,
}

skill_names = [
    "industry", "carpentry", "masonry", "machinery", "sewing", "craftsmanship", "manufacturing", "drilling",
    "textiles", "smelting", "railroads", "automation", "jewelry", "physics", "engineering", "lasers",
    "economy", "storage", "gambling", "optics", "trade", "banking", "management", "architecture",
    "bargain", "capitalism", "treasury", "autorepair", "supply", "artistry", "colonization", "logistics",
    "foraging", "gathering", "farming", "pet", "hunting", "fishing", "mining", "geology",
    "ballistics", "cooking", "calciverous", "prospecting", "looting", "gluttony", "prowess", "deposit",
    "magic", "alchemy", "inscription", "thaumaturgy", "combat", "evasion", "reagency", "faith",
    "renewal", "spellbind", "transmutation", "conjuration", "destruction", "spirituality", "summoning", "astrology",
]

# Crafting location ids of the apworld (data/locations.json), the datapackage counts the checked ones per gear
gear_locations = {
    "boots": range(10, 18), "pickaxe": range(202, 210), "shovel": range(211, 216), "sword": range(221, 229),
    "bow": range(231, 239), "amulet": range(241, 249), "wallet": range(251, 259), "gloves": range(261, 269),
    "book": range(271, 279), "backpack": range(282, 287),
    "hammer": range(299, 300), "fishing rod": range(300, 301), "obliterator": range(301, 302),
}
datapackage_gear = ["boots", "pickaxe", "shovel", "sword", "bow", "amulet", "wallet", "gloves", "book", "backpack"]

lock = threading.Lock()
state = {
    "gear": {},
    "skills": [0] * 64,
    "checked": set(),
    "goal_level": 65,
    "easier_craft": 0,
    "goaled": False,
    "pending_death": None,
    "deaths": 0,
}


def location_name(loc: int) -> str:
    if 302 <= loc <= 365:
        return f"Level {loc - 300}"
    for name, ids in gear_locations.items():
        if loc in ids:
            return f"{name} craft #{ids.index(loc) + 1}"
    return "not a location in the apworld"


class ClientHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass  # Keep the console readable, every request is not interesting

    def send_json(self, data):
        body = json.dumps(data).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        with lock:
            if self.path == "/Items":
                return self.send_json({"Gear": dict(state["gear"]), "Skills": list(state["skills"])})
            if self.path == "/Datapackage":
                gear = {}
                for name in datapackage_gear:
                    done = sum(1 for loc in gear_locations[name] if loc in state["checked"])
                    if done:
                        gear[name] = done
                return self.send_json({"Gear": gear, "Goal": "level", "GoalLevel": state["goal_level"],
                                       "EasierCraft": state["easier_craft"]})
            if self.path == "/Deathpoll":
                cause, state["pending_death"] = state["pending_death"], None
                return self.send_json({"Death": int(cause is not None), "Cause": cause or ""})
        self.send_response(404)
        self.end_headers()

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length).decode("utf-8")
        if self.path == "/Locations":
            try:
                locations = json.loads(body)["Locations"]
            except (ValueError, KeyError, TypeError):
                print(f"\n[mod] invalid /Locations body: {body!r}")
                self.send_response(400)
                self.end_headers()
                return
            with lock:
                new = [loc for loc in locations if loc not in state["checked"]]
                state["checked"].update(locations)
            for loc in new:
                print(f"\n[mod] check {loc} : {location_name(loc)}")
            return self.send_json({"message": "ok"})
        if self.path == "/Goal":
            with lock:
                first = not state["goaled"]
                state["goaled"] = True
            if first:
                print("\n[mod] GOAL COMPLETED")
            return self.send_json({"message": "ok"})
        if self.path == "/Death":
            with lock:
                state["deaths"] += 1
            print(f"\n[mod] player died, a DeathLink would be sent (death #{state['deaths']})")
            return self.send_json({"message": "ok"})
        self.send_response(404)
        self.end_headers()


HELP = """Commands:
  give <gear> [amount]   send progressive gear (names: """ + ", ".join(gear_max) + """)
  skill <name|index|all> send a skill
  goal <level>           set the goal level of the datapackage
  easy <on|off>          toggle EasierCraft in the datapackage
  uncheck <id|all>       forget checked locations (to test the resync)
  kill [cause]           send a DeathLink to the mod
  status                 show what was sent and received
  stop                   quit"""


def run_console():
    while True:
        try:
            cmd = input("> ").strip()
        except EOFError:
            return
        if not cmd:
            continue
        parts = cmd.split()
        verb, args = parts[0].lower(), parts[1:]
        with lock:
            if verb == "stop":
                return
            elif verb == "help":
                print(HELP)
            elif verb == "give" and args:
                amount = 1
                if args[-1].isdigit():
                    amount = int(args.pop())
                name = " ".join(args).lower()
                if name not in gear_max:
                    print(f"Unknown gear {name!r}")
                    continue
                state["gear"][name] = state["gear"].get(name, 0) + amount
                print(f"{name} : {state['gear'][name]} received (the apworld has {gear_max[name]})")
            elif verb == "skill" and args:
                arg = args[0].lower()
                if arg == "all":
                    state["skills"] = [1] * 64
                    print("All skills sent")
                    continue
                index = int(arg) if arg.isdigit() else (skill_names.index(arg) if arg in skill_names else -1)
                if not 0 <= index < 64:
                    print(f"Unknown skill {arg!r}")
                    continue
                state["skills"][index] = 1
                print(f"Skill {skill_names[index]} ({index}) sent")
            elif verb == "goal" and args and args[0].isdigit():
                state["goal_level"] = int(args[0])
                print(f"Goal level : {state['goal_level']}")
            elif verb == "easy" and args:
                state["easier_craft"] = 1 if args[0].lower() == "on" else 0
                print(f"EasierCraft : {state['easier_craft']}")
            elif verb == "uncheck" and args:
                if args[0] == "all":
                    state["checked"].clear()
                elif args[0].isdigit():
                    state["checked"].discard(int(args[0]))
                print(f"{len(state['checked'])} checked locations left")
            elif verb == "kill":
                state["pending_death"] = " ".join(args) or "Tester died in another game"
                print(f"DeathLink queued : {state['pending_death']}")
            elif verb == "status":
                print("Gear received :", state["gear"] or "nothing")
                print("Skills received :", [skill_names[i] for i in range(64) if state["skills"][i]] or "nothing")
                print("Checked :", sorted(state["checked"]) or "nothing")
                print(f"Goal level : {state['goal_level']}, goal done : {state['goaled']}, "
                      f"EasierCraft : {state['easier_craft']}, deaths sent by the mod : {state['deaths']}")
            else:
                print(HELP)


def main():
    server = ThreadingHTTPServer(("127.0.0.1", PORT), ClientHandler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    print(f"Mock Forager Client listening on http://127.0.0.1:{PORT}/ , type help for the commands")
    try:
        run_console()
    finally:
        server.shutdown()


if __name__ == "__main__":
    main()
