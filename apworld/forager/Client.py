import asyncio
import time
import Utils
import websockets
import functools
from copy import deepcopy
from typing import Iterable
from NetUtils import decode, encode, JSONtoTextParser, JSONMessagePart, NetworkItem, NetworkPlayer
from MultiServer import Endpoint
from CommonClient import CommonContext, gui_enabled, ClientCommandProcessor, logger, get_base_parser, server_loop, ClientStatus
import aiohttp.web

DEBUG = True

FILLER_IDS = range(400, 600) # Filler items and traps, the mod applies them in the order they were received

# TrapLink : trap names from other games that Forager can play, with the Forager trap item id
TRAP_LINK_NAMES: dict[str, int] = {
    "Energy Drain Trap": 500, "Exhaustion Trap": 500, "Tired Trap": 500, "Fatigue Trap": 500, "Hunger Trap": 500,
    "Slowness Trap": 501, "Slow Trap": 501, "Slowdown Trap": 501, "Freeze Trap": 501, "Ice Trap": 501,
    "Stun Trap": 501, "Paralyze Trap": 501,
    "Tax Trap": 502, "Money Trap": 502, "Coin Trap": 502, "Robbery Trap": 502, "Theft Trap": 502,
}

class ForagerJSONToTextParser(JSONtoTextParser):
    def _handle_color(self, node: JSONMessagePart):
        return self._handle_text(node)  # No colors for the in-game text



class ForagerContext(CommonContext):
    command_processor = ClientCommandProcessor
    game = "Forager"

    def __init__(self, server_address, password):
        super().__init__(server_address, password)
        self.http_task = None
        self.gamejsontotext = ForagerJSONToTextParser(self)
        self.autoreconnect_task = None
        self.endpoint = None
        self.items_handling = 0b111
        self.room_info = None
        self.connected_msg = None
        self.game_connected = False
        self.awaiting_info = False
        self.full_inventory: list[any] = []
        self.server_msgs: list[any] = []
        self.slot_data = {}
        self.goal : str = "level"
        self.goalLevel : int = 65
        self.easierCraft : int = 0
        self.pending_death : str | None = None # DeathLink received, waiting for the mod to poll it
        self.pending_traps : list[int] = [] # TrapLink traps received, waiting for the mod to poll them

    async def server_auth(self, password_requested: bool = False):
        if password_requested and not self.password:
            await super(ForagerContext, self).server_auth(password_requested)

        await self.get_username()
        await self.send_connect()

    async def disconnect(self, allow_autoreconnect: bool = False):
        await super().disconnect(allow_autoreconnect)


    def is_connected(self) -> bool:
        return self.server and self.server.socket.open

    def on_print_json(self, args: dict):
        text = self.gamejsontotext(deepcopy(args["data"]))
        msg = {"cmd": "PrintJSON", "data": [{"text": text}], "type": "Chat"}
        self.server_msgs.append(encode([msg]))

        if self.ui:
            self.ui.print_json(args["data"])
        else:
            text = self.jsontotextparser(args["data"])
            logger.info(text)

    def update_items(self):
        # just to be safe - we might still have an inventory from a different room
        if not self.is_connected():
            return

        self.server_msgs.append(encode([{"cmd": "ReceivedItems", "index": 0, "items": self.full_inventory}]))

    def on_package(self, cmd: str, args: dict):
        super().on_package(cmd, args)  # Import to ensure Universal Tracker gets the required information it needs.
        if cmd == "Connected":
            json = args
            # This data is not needed and causes the game to freeze for long periods of time in large asyncs.
            if "slot_info" in json.keys():
                json["slot_info"] = {}
            if "players" in json.keys():
                me: NetworkPlayer
                for n in json["players"]:
                    if n.slot == json["slot"] and n.team == json["team"]:
                        me = n
                        break

                # Only put our player info in there as we actually need it
                json["players"] = [me]
            self.slot_data = json["slot_data"]
            self.goalLevel = self.slot_data["required_level"]
            if ("easier_craft" in self.slot_data and self.slot_data["easier_craft"]):
                self.easierCraft = 1
            self.pending_death = None # Don't kill the player for a death from a previous connection
            self.pending_traps.clear()
            asyncio.create_task(self.update_link_tags(bool(self.slot_data.get("death_link", False)),
                                                      bool(self.slot_data.get("trap_link", False))))
            if DEBUG:
                print(json)
            self.connected_msg = encode([json])
            if self.awaiting_info:
                self.server_msgs.append(self.room_info)
                self.update_items()
                self.awaiting_info = False

        elif cmd == "RoomUpdate":
            # Same story as above
            json = args
            if "players" in json.keys():
                json["players"] = []

            self.server_msgs.append(encode(json))

        elif cmd == "ReceivedItems":
            if args["index"] == 0:
                self.full_inventory.clear()

            for item in args["items"]:
                self.full_inventory.append(NetworkItem(*item))

            self.server_msgs.append(encode([args]))

        elif cmd == "Bounced":
            self.on_trap_link(args)

        elif cmd == "RoomInfo":
            self.seed_name = args["seed_name"]
            self.room_info = encode([args])

        else:
            if cmd != "PrintJSON":
                self.server_msgs.append(encode([args]))

    def make_gui(self):
        ui = super().make_gui()
        ui.base_title = "Archipelago Forager Client"
        return ui
    
    async def locationHandler(self, request: aiohttp.web.Request) -> aiohttp.web.Response:
        requestjson = await request.json()
        try:
            await self.check_locations(requestjson["Locations"])
        except:
            pass
        localResponse = aiohttp.web.json_response({"message": "This is a placeholder JSON response."},status=200)
        return localResponse
    
    async def itemsHandler(self, request: aiohttp.web.Request) -> aiohttp.web.Response:
        """handle GET at /Items"""
        response = self.build_item_response()
        return aiohttp.web.json_response(response)
    
    async def datapackageHandler(self, request: aiohttp.web.Request) -> aiohttp.web.Response:
        """handle GET at /Datapackage"""
        """Anything in slot data or anything required on connection."""
        response = self.build_datapackage_response()
        return aiohttp.web.json_response(response)
    
    async def goalHandler(self, request: aiohttp.web.Request) -> aiohttp.web.Response:
        """Handles POST at /Goal"""
        message = [{"cmd": "StatusUpdate", "status": ClientStatus.CLIENT_GOAL}]
        await self.send_msgs(message)
        return aiohttp.web.json_response({"message": "ok"})

    async def update_link_tags(self, death_link: bool, trap_link: bool):
        """Turns the DeathLink and TrapLink tags on/off, and tells the server if they changed"""
        old_tags = self.tags.copy()
        for tag, enabled in (("DeathLink", death_link), ("TrapLink", trap_link)):
            if enabled:
                self.tags.add(tag)
            else:
                self.tags.discard(tag)
        if old_tags != self.tags and self.server and not self.server.socket.closed:
            await self.send_msgs([{"cmd": "ConnectUpdate", "tags": self.tags}])

    def on_trap_link(self, args: dict) -> None:
        """Another linked player received a trap, the mod plays the Forager version on its next poll"""
        data = args.get("data", {})
        if "TrapLink" not in self.tags or "TrapLink" not in args.get("tags", []):
            return
        if self.slot is None or data.get("source") == self.player_names.get(self.slot):
            return
        trap_id = TRAP_LINK_NAMES.get(data.get("trap_name", ""))
        if trap_id is not None:
            logger.info(f"TrapLink: {data['trap_name']} from {data.get('source', 'someone')}")
            self.pending_traps.append(trap_id)

    async def trapHandler(self, request: aiohttp.web.Request) -> aiohttp.web.Response:
        """Handles POST at /Trap : {"Trap" : id}, the mod played a trap item, send it to the TrapLink players"""
        try:
            trap_id = int((await request.json())["Trap"])
        except (ValueError, KeyError, TypeError):
            return aiohttp.web.json_response({"message": "invalid trap"}, status=400)
        if "TrapLink" in self.tags and self.slot is not None:
            trap_name = self.item_names.lookup_in_game(trap_id, self.game)
            await self.send_msgs([{
                "cmd": "Bounce", "tags": ["TrapLink"],
                "data": {"time": time.time(), "source": self.player_names[self.slot], "trap_name": trap_name}
            }])
            logger.info(f"TrapLink: sent {trap_name}")
        return aiohttp.web.json_response({"message": "ok"})

    def on_deathlink(self, data: dict) -> None:
        """Another linked player died, the mod kills the player on its next poll."""
        super().on_deathlink(data)
        self.pending_death = data.get("cause") or f"{data.get('source', 'Someone')} died"

    async def deathHandler(self, request: aiohttp.web.Request) -> aiohttp.web.Response:
        """Handles POST at /Death, the player died in Forager"""
        if "DeathLink" in self.tags:
            await self.send_death(f"{self.player_names[self.slot]} died in Forager")
        return aiohttp.web.json_response({"message": "ok"})

    async def deathpollHandler(self, request: aiohttp.web.Request) -> aiohttp.web.Response:
        """Handles GET at /Deathpoll : {"Death" : 1, "Cause" : "...", "Traps" : [501]}, every received DeathLink and
        TrapLink trap is only sent once"""
        cause, self.pending_death = self.pending_death, None
        traps, self.pending_traps = self.pending_traps, []
        return aiohttp.web.json_response({"Death": int(cause is not None), "Cause": cause or "", "Traps": traps})

    def build_item_response(self):
        """
        expected return value to be like:
        {"Gear" : {"pickaxe" : 3, "sword" : 2}, "Skills" : [0,1,0,0,1,...]}
        "Skills is a 64 long array" 
        """
        skills = [0 for i in range(64)]
        gear = {}
        filler = []
        for item in self.items_received:
            if(item[0] >= 300 and item[0] < 364):
                skills[item[0] - 300] = 1
            elif(item[0] >= 249 and item[0] <= 265):
                name = self.item_names["Forager"][item[0]]
                if("Progressive" in name):
                    name = name[12:]
                name = name.lower()
                gear[name] = gear.get(name,0) + 1
            elif(item[0] in FILLER_IDS):
                filler.append(item[0])
        itemmessage = {
            "Gear" : gear,
            "Skills" : skills,
            "Filler" : filler
        }
        return itemmessage
    
    def build_datapackage_response(self):
        """
        Expected return value to be like: 
        {"Gear" : {"pickaxe" : 3, "sword" : 2}, "Goal" : "level", "GoalLevel" : 46}
        """
        gear = {}
        self.slot
        gear_ids = [17,209,215,228,238,248,258,268,278,286]
        gear_names = ["boots","pickaxe","shovel","sword","bow","amulet","wallet","gloves","book","backpack"]
        for loc in self.checked_locations:
            if loc <= 286:
                for i in range(10):
                    if loc <= gear_ids[i]:
                        name = gear_names[i]
                        gear[name] = gear.get(name,0) + 1
                        break
        itemmessage = {
            "Gear" : gear,
            "Goal" : self.goal,
            "GoalLevel" : self.goalLevel,
            "EasierCraft" : self.easierCraft
        }
        return itemmessage





def launch():
    async def main():
        from .Server import ArchiHandler, http_server_loop
        parser = get_base_parser()
        args = parser.parse_args()

        ctx = ForagerContext(args.connect, args.password)
        logger.info("Starting the Forager proxy server")
        server = ArchiHandler(ctx)
        ctx.httpServer_task = asyncio.create_task(http_server_loop(server), name="http server loop")
        ctx.server_task = asyncio.create_task(server_loop(ctx), name="server loop")
        if gui_enabled:
            ctx.run_gui()
        ctx.run_cli()

        await ctx.exit_event.wait()
        await ctx.shutdown()
    Utils.init_logging("ForagerClient")
    asyncio.run(main())