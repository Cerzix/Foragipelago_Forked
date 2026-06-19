from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import threading
from urllib.parse import urlparse, parse_qs

gear_index = {
    "pickaxe": 0,
    "shovel": 1,
    "sword": 2,
    "bow": 3,
    "lightning": 4,
    "ice": 5,
    "fire": 6,
    "amulet": 7,
    "boot": 8,
    "glove": 9,
    "book": 10,
    "backpack" : 11,
    "wallet" : 12,
    "nerdy_glasses": 13,
    "top_hat" : 14,
    "pink_bow" : 15,
    "lantern" : 16,
    "skull_key" : 17,
    "skeleton_mask" : 18,
    "fairy_aura" : 19,
    "quiver" : 20,
    "vampire_wings" : 21,
    "shield" : 22,
    "magic_scepter" : 23,
    "holy_relic": 24,
    "ancient" : 25,
    "fire" : 26,
    "frozen_galaxy":27,
    "skull":28,
    "ancient_galaxy":29,
    "fire_galaxy":30,
    "frozen_galaxy":31,
    "skull_galaxy":32,
    "museum": 33,
    "death": 34,
    "obliterator": 35,
    "fish_net" : 36,
    "merchant_medallion" : 37,
    "lunar_medalion": 38,
    "hammer": 39,
    "fishing": 40
}

skill_index = {
    "industry" : 0,
    "capentry" : 1,
    "masonry": 2,
    "machinery" : 3,
    "sewing": 4,
    "craftsmenship": 5,
    "manufacturing": 6,
    "drilling": 7,
    "textiles" : 8,
    "smelting" : 9,
    "railroads" : 10,
    "automation": 11,
    "jewlery": 12,
    "physics": 13,
    "engineering": 14,
    "lasers": 15,
    "economy" : 16,
    "storage" : 17,
    "gambling" : 18,
    "optics": 19,
    "trade" : 20,
    "banking" : 21,
    "management" : 22,
    "architecture" : 23,
    "bargin" :24,
    "capitalsim" : 25,
    "treasury" : 26,
    "autorepair": 27,
    "supply": 28,
    "artistry": 29,
    "colonization" : 30,
    "logistics" : 31,
    "foraging" : 32,
    "gathering" : 33,
    "farming" : 34,
    "pet": 35,
    "hunting" :36,
    "fishing" : 37,
    "mining" : 38,
    "geology" : 39,
    "ballistics" : 40,
    "cooking" : 41,
    "calciverous" : 42,
    "prospecting" : 43,
    "looting" : 44,
    "gluttony": 45,
    "prowess" : 46,
    "deposit" : 47,
    "magic" : 48,
    "alchemy": 49,
    "inscription" : 50,
    "thaumaturgy" : 51,
    "combat" : 52,
    "evasion" : 53,
    "reagency" : 54,
    "faith" : 55,
    "renewal" : 56,
    "spellbind" : 57,
    "transmutation" : 58,
    "conjuration" : 59,
    "destruction" : 60,
    "spirituality" : 61,
    "summoning" : 62,
    "astrology" : 63
}

shared_data = {
    "global_gears" : [114, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, 148, 154, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4],
    "global_level": 1,
    "global_skills" : [1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
    "archi_level" : 1,
    "archi_gears" : [114, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, 148, 154, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4],
    "archi_skills": [1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
    "forager_gears": [114, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, 148, 154, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4],
    "forager_level": 1,
    "forager_skills": [1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
    "foragerHasUpdate": False,
    "archiHasUpdate": False,
}

class ArchiHandler(BaseHTTPRequestHandler):

    def __init__(self, *args, **kwargs):

        # works with shared_data now
        #self.global_gears = [114, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, 148, 154, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4]
        #self.global_level = 1
        #self.archi_gears = []
        #self.archi_level = 1
        #self.forager_gears = []
        #self.forager_level = 1
        #self.foragerHasUpdate = False
        #self.archieHasUpdate = False


        super().__init__(*args, **kwargs)

    def do_POST(self):
        parsed_path = urlparse(self.path)
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        if parsed_path.path == "/gear":
            gears = post_data.decode('utf-8')
            gears = gears.split('{')[2].split('}')[0][1:].split(',')
            g_gears = []
            for gear in gears:
                g_gears.append(gear)
            print(g_gears)
            shared_data["forager_gears"] = g_gears
            self.foragerHasGearUpdate()

        elif parsed_path.path == "/level":
            level = int(post_data.decode('utf-8'))
            shared_data["forager_level"] = level
        
        elif parsed_path.path == "/check":
            check = post_data.decode('utf-8')
            print(check)


        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"OK")

    def do_GET(self):
        parsed_path = urlparse(self.path)
        if parsed_path.path == "/hasUpdate":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(str(shared_data["archiHasUpdate"]).encode())
        elif parsed_path.path == "/updateGear":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(str(shared_data["global_gears"]).encode())
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Not Found")

    def foragerHasGearUpdate(self):
        diff_list = []
        diff = False
        print(type(self.forager_gears))
        if len(self.forager_gears) == 41:
            for i in range(41):
                diff_list.append(int(self.forager_gears[i]) - int(shared_data["global_gears"][i]))
                if diff_list[i] != 0:
                    diff = True

        print(diff_list)
        print(diff)
def start_HTTP_Server():
    print("Starting")
    server = HTTPServer(('0.0.0.0', 8000), ArchiHandler)

    threading.Thread(target=server.serve_forever, daemon=True).start()

    cmd=""

    while(cmd != "stop"):
        cmd = input("> ")
        values = cmd.split(" ")

        if values[0].lower() == 'set':
            if values[1].lower() == 'level':
                shared_data['archi_level'] = values[2]
                shared_data['archiHasUpdate'] = True
            if values[1].lower() == 'gear':
                shared_data['archiHasUpdate'] = True
                if values[2].lower() in gear_index:
                    shared_data['global_gears'][gear_index[values[2]]] = int(values[3])
            if values[1].lower() == 'skills':
                shared_data['archiHasUpdate'] = True
                print("Setting skills")

        if values[0].lower() == 'get':
            if values[1].lower() == 'level':
                print(shared_data['archi_level'])
            if values[1].lower() == 'gear':
                print(shared_data['global_gears'])
            if values[1].lower() == 'skills':
                print(shared_data['archi_skills'])
start_HTTP_Server()