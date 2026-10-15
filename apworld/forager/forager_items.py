from typing import TYPE_CHECKING

from BaseClasses import Item, ItemClassification as IC

from .forager_constants import GAME_NAME

if TYPE_CHECKING:
    from worlds.forager import ForagerWorld

LEATHER_ITEMS: dict[str,int] = {"Foraging" : 1, "Sewing" : 1, "Progressive Backpack" : 1}
ROYAL_CLOTHING_ITEMS: dict[str,int] = LEATHER_ITEMS | {"Craftsmanship" : 1, "Prospecting" : 1, "Progressive Backpack" : 2} 
PLASTIC_ITEMS: dict[str,int] = ROYAL_CLOTHING_ITEMS | {"Drilling" : 1, "Manufacturing" : 1, "Progressive Backpack" : 3, "Progressive Shovel" : 2}
STEEL_ITEMS: dict[str,int] = {"Industry" : 1,"Progressive Backpack" : 1}
ROYAL_STEEL_ITEMS: dict[str,int] = STEEL_ITEMS | {"Craftsmanship" : 1, "Prospecting" : 1, "Progressive Backpack" : 2}
ELECTRONICS_ITEMS: dict[str,int] = ROYAL_STEEL_ITEMS | {"Manufacturing" : 1, "Progressive Backpack" : 3}
VOID_ITEMS: dict[str,int] = ROYAL_STEEL_ITEMS | {"Summoning" : 1, "Combat" : 1, "Storage" : 1}
VOID_STEEL_ITEMS: dict[str,int] = VOID_ITEMS | {"Transmutation" : 1, "Spirituality" : 1, "Progressive Sword" : 6}
COSMIC_STEEL_ITEMS: dict[str,int] = VOID_STEEL_ITEMS | {"Astrology" : 1}
NUCLEAR_ITEMS: dict[str,int] = COSMIC_STEEL_ITEMS | {"Physics" : 1}

DIG_ARCHEOLOGY: dict[str,int] = {"Progressive Shovel" : 3, "Prospecting" : 1}


class ForagerItem(Item):
    game: str = GAME_NAME

    def __init__(self, name: str, classification: IC, code: int, player: int):
        super().__init__(name, classification, code, player)


def item_names_of(world: "ForagerWorld", classification: str, tools: bool) -> list[str]:
    """Names of the items of a classification, either only the Tools or everything but the Tools."""
    return [name for name, category in world.item_class_sets.get(classification, {}).items()
            if (category == "Tools") == tools and category not in ["Seals", "Relics"]]


def create_world_items(world: "ForagerWorld"):
    """Fill every location, in order of priority:
    1. Every progression item, with its full count (progressive tools)
    2. Every other progressive tool, with its full count, so no tool tier is ever missing
    3. Every other skill, once each and in a random order, until the locations run out
    4. Filler, if there are still locations left
    There are more of these items than locations (149 for 140 locations at level 65), so the last skills are left
    out. Only at the lowest required levels the tools don't fit either, then random tool tiers are left out."""
    locations_to_fill: int = len(world.multiworld.get_unfilled_locations(world.player))
    item_tables: dict = world.json_tables["items"]
    categories: dict[str, str] = {name: category for class_set in world.item_class_sets.values()
                                  for name, category in class_set.items()}

    def count_of(name: str) -> int:
        return item_tables[categories[name]][name].get("count", 1)

    progression: list[str] = []
    for name in item_names_of(world, "Progression", True) + item_names_of(world, "Progression", False):
        progression += [name] * count_of(name)

    tool_counts: dict[str, int] = {name: count_of(name) for name in
                                   item_names_of(world, "Useful", True) + item_names_of(world, "Filler", True)}
    tools_room: int = locations_to_fill - len(progression)
    while sum(tool_counts.values()) > max(tools_room, 0):
        # Not enough locations for every tool tier, the top tier of a random tool goes
        trimmed: str = world.random.choice([name for name, count in tool_counts.items() if count > 0])
        tool_counts[trimmed] -= 1
    tools: list[str] = [name for name, count in tool_counts.items() for _ in range(count)]

    useful_skills: list[str] = item_names_of(world, "Useful", False)
    filler_skills: list[str] = [name for name in item_names_of(world, "Filler", False)
                                if name != world.get_filler_item_name()]
    world.random.shuffle(useful_skills)
    world.random.shuffle(filler_skills)

    item_names: list[str] = (progression + tools + useful_skills + filler_skills)[:max(locations_to_fill,
                                                                                       len(progression))]
    item_names += [world.get_filler_item_name()] * (locations_to_fill - len(item_names))

    world.multiworld.itempool += [world.create_item(name) for name in item_names]