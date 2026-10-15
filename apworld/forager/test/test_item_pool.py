from collections import Counter

from test.bases import WorldTestBase


class ForagerItemPoolTestBase(WorldTestBase):
    game = "Forager"

    def pool_counts(self) -> Counter:
        return Counter(item.name for item in self.multiworld.get_items() if item.code is not None)

    def tool_counts(self) -> dict[str, int]:
        return {name: data["count"] for name, data in self.world.json_tables["items"]["Tools"].items()}


class TestFullGoal(ForagerItemPoolTestBase):
    options = {"required_level": 65}

    def test_every_tool_tier_is_in_the_pool(self) -> None:
        pool = self.pool_counts()
        for name, count in self.tool_counts().items():
            with self.subTest(name):
                self.assertEqual(pool[name], count)

    def test_no_duplicate_skills(self) -> None:
        pool = self.pool_counts()
        for name in self.world.json_tables["items"]["Skills"]:
            with self.subTest(name):
                self.assertLessEqual(pool[name], 1)

    def test_every_progression_skill_is_in_the_pool(self) -> None:
        pool = self.pool_counts()
        for name, data in self.world.json_tables["items"]["Skills"].items():
            if data["classification"] == "Progression":
                with self.subTest(name):
                    self.assertEqual(pool[name], 1)


class TestSmallestFullGearGoal(TestFullGoal):
    """Lowest level with enough locations for every tool tier."""
    options = {"required_level": 42}


class TestLowestGoal(ForagerItemPoolTestBase):
    """Not enough locations for every tool tier : only non progression tool tiers get left out."""
    options = {"required_level": 40}

    def test_progression_tools_are_complete(self) -> None:
        pool = self.pool_counts()
        for name, data in self.world.json_tables["items"]["Tools"].items():
            if data["classification"] == "Progression":
                with self.subTest(name):
                    self.assertEqual(pool[name], data["count"])

    def test_pool_matches_locations(self) -> None:
        locations = [loc for loc in self.multiworld.get_locations(self.player) if loc.address is not None]
        self.assertEqual(sum(self.pool_counts().values()), len(locations))

    def test_filler_is_nothing(self) -> None:
        self.assertEqual(self.world.get_filler_item_name(), "Nothing!")
