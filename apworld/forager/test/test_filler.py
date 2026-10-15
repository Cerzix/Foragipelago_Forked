from collections import Counter

from test.bases import WorldTestBase


class ForagerFillerTestBase(WorldTestBase):
    game = "Forager"

    def pool_counts(self) -> Counter:
        return Counter(item.name for item in self.multiworld.get_items() if item.code is not None)

    def count_of(self, category: str) -> int:
        pool = self.pool_counts()
        return sum(pool[name] for name in self.world.json_tables["items"][category])


class TestDefaultFiller(ForagerFillerTestBase):
    options = {"required_level": 65}

    def test_filler_slots_are_filled(self) -> None:
        self.assertEqual(self.count_of("Filler") + self.count_of("Traps"), 10)

    def test_every_tool_tier_is_still_in_the_pool(self) -> None:
        pool = self.pool_counts()
        for name, data in self.world.json_tables["items"]["Tools"].items():
            with self.subTest(name):
                self.assertEqual(pool[name], data["count"])


class TestNoFiller(ForagerFillerTestBase):
    options = {"required_level": 65, "filler_slots": 0}

    def test_no_filler(self) -> None:
        self.assertEqual(self.count_of("Filler") + self.count_of("Traps"), 0)


class TestOnlyTraps(ForagerFillerTestBase):
    options = {"required_level": 65, "filler_slots": 20, "trap_percentage": 100}

    def test_every_filler_is_a_trap(self) -> None:
        self.assertEqual(self.count_of("Traps"), 20)
        self.assertEqual(self.count_of("Filler"), 0)

    def test_trap_classification(self) -> None:
        traps = [item for item in self.multiworld.get_items() if item.name in self.world.json_tables["items"]["Traps"]]
        self.assertTrue(all(item.trap for item in traps))


class TestNoTraps(ForagerFillerTestBase):
    options = {"required_level": 65, "filler_slots": 20, "trap_percentage": 0}

    def test_no_traps(self) -> None:
        self.assertEqual(self.count_of("Traps"), 0)
        self.assertEqual(self.count_of("Filler"), 20)


class TestMaxFiller(ForagerFillerTestBase):
    """More filler slots than skills to leave out : the progression skills are never removed"""
    options = {"required_level": 65, "filler_slots": 60}

    def test_progression_skills_stay(self) -> None:
        pool = self.pool_counts()
        for name, data in self.world.json_tables["items"]["Skills"].items():
            if data["classification"] == "Progression":
                with self.subTest(name):
                    self.assertEqual(pool[name], 1)
