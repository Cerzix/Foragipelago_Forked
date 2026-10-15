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


def item_names_of(world: "ForagerWorld", classification: str, category: str) -> list[str]:
    """Names of the items of a classification in an items.json category."""
    return [name for name, item_category in world.item_class_sets.get(classification, {}).items()
            if item_category == category]


def weighted_names(world: "ForagerWorld", category: str) -> tuple[list[str], list[int]]:
    """Names and weights of the items of an items.json category (Filler, Traps)."""
    items: dict = world.json_tables["items"][category]
    return list(items), [data["weight"] for data in items.values()]


def random_filler_name(world: "ForagerWorld") -> str:
    names, weights = weighted_names(world, "Filler")
    return world.random.choices(names, weights)[0]


def create_world_items(world: "ForagerWorld"):
    """Fill every location, in order of priority:
    1. Every progression item, with its full count (progressive tools)
    2. Every other progressive tool, with its full count, so no tool tier is ever missing
    3. The filler slots (filler_slots option), with filler items or traps (trap_percentage option)
    4. Every other skill, once each and in a random order, until the locations run out
    5. More filler, if there are still locations left
    There are more of these items than locations (149 for 140 locations at level 65), so the last skills are left
    out. Only at the lowest required levels the tools don't fit either, then random tool tiers are left out."""
    locations_to_fill: int = len(world.multiworld.get_unfilled_locations(world.player))
    item_tables: dict = world.json_tables["items"]
    categories: dict[str, str] = {name: category for class_set in world.item_class_sets.values()
                                  for name, category in class_set.items()}

    def count_of(name: str) -> int:
        return item_tables[categories[name]][name].get("count", 1)

    progression: list[str] = []
    for name in item_names_of(world, "Progression", "Tools") + item_names_of(world, "Progression", "Skills"):
        progression += [name] * count_of(name)

    tool_counts: dict[str, int] = {name: count_of(name) for name in
                                   item_names_of(world, "Useful", "Tools") + item_names_of(world, "Filler", "Tools")}
    tools_room: int = locations_to_fill - len(progression)
    while sum(tool_counts.values()) > max(tools_room, 0):
        # Not enough locations for every tool tier, the top tier of a random tool goes
        trimmed: str = world.random.choice([name for name, count in tool_counts.items() if count > 0])
        tool_counts[trimmed] -= 1
    tools: list[str] = [name for name, count in tool_counts.items() for _ in range(count)]

    skills: list[str] = item_names_of(world, "Useful", "Skills")
    filler_skills: list[str] = item_names_of(world, "Filler", "Skills")
    world.random.shuffle(skills)
    world.random.shuffle(filler_skills)
    skills += filler_skills

    room_left: int = max(locations_to_fill - len(progression) - len(tools), 0)
    filler_count: int = min(world.options.filler_slots.value, room_left)
    skills = skills[:room_left - filler_count]
    filler_count = room_left - len(skills)  # Also fills what the skills can't

    trap_names, trap_weights = weighted_names(world, "Traps")
    filler: list[str] = []
    for _ in range(filler_count):
        if world.random.randrange(100) < world.options.trap_percentage.value:
            filler.append(world.random.choices(trap_names, trap_weights)[0])
        else:
            filler.append(random_filler_name(world))

    item_names: list[str] = progression + tools + skills + filler
    world.multiworld.itempool += [world.create_item(name) for name in item_names]
