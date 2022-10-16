return {
    showAdvancedSettings = false,
    logLevel = 2,
    showUi = true,
    isFilterEnabled = {
        mustNotBeCraftingSpec = true,
        mustHaveDisplayName = true,
        mustNotBeOnInternalBlacklist = true,
        mustNotBeOnBlacklist = true,
        mustHaveAppearanceName = true,
        mustHaveClothingCategory = true,
    },
    tweakDbidToPathTable = {
        ["<TDBID:FB1A237B:1E>"] = "Items.TightJumpsuit_01_test_01",
    },
    blacklist = {
        ["Items.TightJumpsuit_01_test_01"] = true,
    },
    addAllClothesOnPlayerSpawn = false,
}
