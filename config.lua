return {
    logLevel = 2,
    tweakDbidToPathTable = {
        ["<TDBID:FB1A237B:1E>"] = "Items.TightJumpsuit_01_test_01",
    },
    blacklist = {
        ["Items.TightJumpsuit_01_test_01"] = true,
    },
    isFilterEnabled = {
        mustNotBeOnBlacklist = true,
        mustHaveAppearanceName = true,
        mustHaveClothingCategory = true,
        mustNotBeCraftingSpec = true,
        mustNotBeOnInternalBlacklist = true,
        mustHaveDisplayName = true,
    },
    showAdvancedSettings = true,
    addAllClothesOnPlayerSpawn = true,
    showUi = true,
}
