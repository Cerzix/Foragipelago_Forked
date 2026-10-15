from dataclasses import dataclass
from Options import PerGameCommonOptions, Toggle, Range, Choice, OptionGroup, DeathLink


class GameMode(Choice):
    #"""Enable alternative game modes:
    #Default - Forager's main goal is to level up to a certain level to reach goal.
    #"""
    display_name = "Game Mode"
    internal_name = "game_mode"
    option_default = 0
    default = 0

class RequiredLevel(Range):
    """
    Choose what level is required to beat the game.
    """
    display_name = "Required Level"
    internal_name = "required_level"
    default = 65
    range_start = 40
    range_end = 65

class EasierCraft(Toggle):
    """
    Make the main early game materials requires less ressources.
    """
    display_name = "Easier Crafting"
    internal_name = "easier_craft"

class FillerSlots(Range):
    """
    How many locations hold filler items (coins, resources, food, buffs...) and traps.
    There are more tools and skills than locations, so every filler slot leaves out one skill that isn't
    needed to beat the game. Those skills can't be bought then.
    """
    display_name = "Filler Slots"
    internal_name = "filler_slots"
    default = 10
    range_start = 0
    range_end = 60

class TrapPercentage(Range):
    """
    Percentage of the filler items that are traps (Energy Drain, Slowness, Tax).
    """
    display_name = "Trap Percentage"
    internal_name = "trap_percentage"
    default = 20
    range_start = 0
    range_end = 100

class TrapLink(Toggle):
    """
    Whether your received traps are linked to other players.
    You will also receive linked traps from other players with Trap Link enabled, when Forager has a similar trap.
    """
    display_name = "Trap Link"
    internal_name = "trap_link"

@dataclass
class ForagerOptions(PerGameCommonOptions):
    game_mode: GameMode
    required_level: RequiredLevel
    easier_craft: EasierCraft
    death_link: DeathLink
    filler_slots: FillerSlots
    trap_percentage: TrapPercentage
    trap_link: TrapLink


forager_option_groups: list[OptionGroup] = [
    OptionGroup("Main Forager Options", [RequiredLevel,EasierCraft,DeathLink]),
    OptionGroup("Filler & Traps", [FillerSlots,TrapPercentage,TrapLink]),
]