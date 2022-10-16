return {
    version = 1,
    blacklist = {
        "Items.TightJumpsuit_01_test_01",
    },
    blacklistModifiedByUser = false,
    addAllClothesOnPlayerSpawn = false,
    logLevel = 2,
    isFilterEnabled = {
        mustExist = true,
        mustNotBeOnInternalBlacklist = true,
        mustNotBeOnBlacklist = true,
        mustHaveAppearanceName = true,
        mustHaveDisplayName = true,
        mustNotBeCraftingSpec = true,
        mustHaveClothingCategory = true,
    },
    showUi = true,
    showAdvancedSettings = false,
    rememberLastAddedItems = true,
}
