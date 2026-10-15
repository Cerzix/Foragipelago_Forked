from test.bases import WorldTestBase


class TestDeathLinkOn(WorldTestBase):
    game = "Forager"
    options = {"death_link": True}

    def test_slot_data_has_death_link(self) -> None:
        self.assertEqual(self.world.fill_slot_data()["death_link"], 1)


class TestDeathLinkOff(WorldTestBase):
    game = "Forager"

    def test_death_link_is_off_by_default(self) -> None:
        self.assertEqual(self.world.fill_slot_data()["death_link"], 0)
