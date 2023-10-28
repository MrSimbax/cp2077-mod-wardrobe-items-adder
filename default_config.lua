return {
    version = 3,
    blacklist = {
        "Items.TightJumpsuit_01_test_01", -- looks broken
        "TEST.ItemPass_FaceArmor", -- duplicate of Items.Visor_01_basic_01
        "TEST.ItemPass_FeetArmor", -- duplicate of Items.CasualShoes_01_basic_01
        "TEST.ItemPass_HeadArmor", -- duplicate of Items.Cap_01_basic_01
        "TEST.ItemPass_InnerChestArmor", -- duplicate of Items.Shirt_01_basic_01
        "TEST.ItemPass_LegArmor", -- duplicate of Items.Pants_01_basic_01
        "TEST.ItemPass_OuterChestArmor", -- duplicate of Items.Jacket_01_basic_01
        "Items.q203_samurai_jacket", -- broken duplicate of Items.SQ031_Samurai_Jacket
        "Items.q204_samurai_jacket", -- broken duplicate of Items.SQ031_Samurai_Jacket
        "Items.mq017_SameraiJacket", -- duplicate of Items.MQ017_Samerai_Jacket although with a different name ("Fake SEMURAI jacket")
        "Items.q301_fia_pants", -- duplicate of Items.SQ030_MaxTac_Pants with a different name/description
        "Items.q301_fia_helmet", -- duplicate of Items.SQ030_MaxTac_Helmet with a different name/description
        "Items.q301_kurts_militia_helmet", -- duplicate of Items.SQ030_MaxTac_Helmet with a different name/description
        "Items.q301_fia_chest", -- duplicate of Items.SQ030_MaxTac_Chest with a different name/description
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
        mustNotBeLifepathDuplicate = true,
    },
    showUi = true,
    showAdvancedSettings = false,
    rememberLastAddedItems = true,
}
