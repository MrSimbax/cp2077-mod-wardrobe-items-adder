return {
    blacklist = {
        ["Items.TightJumpsuit_01_test_01"] = true,
    },
    addAllClothesOnPlayerSpawn = false,
    logLevel = 2,
    isFilterEnabled = {
        mustNotBeOnInternalBlacklist = true,
        mustNotBeOnBlacklist = true,
        mustHaveAppearanceName = true,
        mustHaveDisplayName = true,
        mustNotBeCraftingSpec = true,
        mustHaveClothingCategory = true,
    },
    showUi = true,
    showAdvancedSettings = false,
    rememberLastItems = true,
}
