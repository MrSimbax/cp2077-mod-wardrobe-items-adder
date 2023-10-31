-- Wardrobe Items Adder v1.4.0
local Logger = require("logger"):init(1, '[WardrobeItemsAdder] ')
local Filters = require("filters")
local Ui = require("ui")
local Utils = require("utils")
local defaultConfig = require("default_config")

local Mod = {}

local ErrorID =
{
    invalidTweakDbid = 0,
    wardrobeSystemUnavailable = 1,
    invalidItemId = 2,
    failedFilter = 3,
    itemAlreadyInWardrobe = 4,
    unknownReason = 5
}

local function makeErrorObject (id, message)
    return {id = id, message = message}
end

function Mod:loadConfig ()
    local configChunk, errorMessage = loadfile("config.lua", "t", {})
    if not configChunk then
        Logger:warn("Could not load the configuration file: %s", errorMessage)
        return Mod:loadDefaultConfig()
    end
    return Mod:runConfig(configChunk)
end

function Mod:loadDefaultConfig ()
    Logger:info("Loading the default configuration")
    configChunk, errorMessage = loadfile("default_config.lua", "t", {})
    if not configChunk then
        Logger:error("Could not load the default configuration: %s", errorMessage)
        return false
    end
    return Mod:runConfig(configChunk)
end

function Mod:runConfig (configChunk)
    local config = configChunk()
    if not config or type(config) ~= "table" then
        Logger:error("Bad configuration")
        self.config = nil
        return false
    end

    local function makeIndexAccessFunction (defaultTable)
        return function (table, key)
            if rawget(table, key) == nil and defaultTable[key] ~= nil then
                rawset(table, key, Utils.copy(defaultTable[key]))
            end
            return rawget(table, key)
        end
    end
    setmetatable(config, {__index = makeIndexAccessFunction(defaultConfig)})
    setmetatable(config.isFilterEnabled, {__index = makeIndexAccessFunction(defaultConfig.isFilterEnabled)})

    self.config = config

    local configVersion = rawget(config, "version")
    if not configVersion or configVersion < defaultConfig.version then
        if not config.blacklistModifiedByUser then
            self:restoreDefaultBlacklist()
        end
    end

    self:updateBlacklistSet()
    self:updateLogLevel()
    config.version = defaultConfig.version
    self:saveConfig()
    return true
end

function Mod:restoreDefaultBlacklist ()
    self.config.blacklist = Utils.copy(defaultConfig.blacklist)
    self.config.blacklistModifiedByUser = false
end

function Mod:saveConfig ()
    if not self.config then
        return false
    end
    local file, errorMessage = io.open("config.lua", "w")
    if not file then
        Logger:error("Could not save the current configuration: %s", errorMessage)
        return false, errorMessage
    end
    file:write("return ")
    Utils.serialize(file, self.config)
    file:close()
    return true
end

function Mod:doesItemPassFilters (itemId)
    for _, filter in ipairs(self.filters) do
        if self.config.isFilterEnabled[filter.configKey] and not filter.condition(itemId) then
            return false, makeErrorObject(ErrorID.failedFilter, filter.failureMessage)
        end
    end
    return true
end

function Mod:addClothToWardrobe (itemTweakDbid)
    if not TDBID.IsValid(itemTweakDbid) then
        return false, makeErrorObject(ErrorID.invalidTweakDbid, "invalid TweakDBID")
    end

    local wardrobeSystem = Game.GetWardrobeSystem()
    if not wardrobeSystem then
        return false, makeErrorObject(ErrorID.wardrobeSystemUnavailable, "the wardrobe system is unavailable")
    end

    local itemId = ItemID.new(itemTweakDbid)
    if not ItemID.IsValid(itemId) then
        return false, makeErrorObject(ErrorID.invalidItemId, "invalid ItemID")
    end

    local storedItemId = wardrobeSystem:GetStoredItemID(itemTweakDbid)
    if ItemID.IsValid(storedItemId) then
        local storedItemPath = storedItemId.id.value
        return false, makeErrorObject(ErrorID.itemAlreadyInWardrobe, string.format("item or its duplicate (\"%s\") is already in the wardrobe", storedItemPath))
    end

    local success, errorObject = self:doesItemPassFilters(itemId)
    if not success then
        return success, errorObject
    end

    success = wardrobeSystem:StoreUniqueItemID(itemId)
    if not success then
        return false, makeErrorObject(ErrorID.unknownReason, "storing item in the wardrobe unsuccessful, reason unknown")
    end

    WardrobeSystem.SendWardrobeAddItemRequest(itemId)

    return true
end

function Mod:findEquivalentItems (itemTweakDbid)
    local itemPath = itemTweakDbid.value
    local appearanceName = TweakDB:GetFlat(itemPath..".appearanceName")
    if not Utils.isValidCname(appearanceName) then
        return {}
    end
    appearanceName = appearanceName.value

    local equivalentItemPaths = {}
    for _, equivalentItemPath in ipairs(self.appearances[appearanceName] or {}) do
        if equivalentItemPath ~= itemPath then
            table.insert(equivalentItemPaths, equivalentItemPath)
        end
    end
    return equivalentItemPaths
end

function Mod:addEquivalentClothesToWardrobe (itemTweakDbid)
    local equivalentItemPaths = self:findEquivalentItems(itemTweakDbid)
    for _, equivalentItemPath in ipairs(equivalentItemPaths) do
        Logger:debug("\tAdding item with the same appearance: \"%s\".", equivalentItemPath)
        local success, errorObject = self:addClothToWardrobe(TweakDBID.new(equivalentItemPath))
        if success then
            return equivalentItemPath
        else
            Logger:debug("\t\tItem \"%s\" was not added to the wardrobe: %s.", equivalentItemPath, errorObject.message)
        end
    end
    return nil
end

-- Adds clothes from a user-specified list of items
function Mod:addClothesToWardrobe (paths)
    for _, path in ipairs(paths) do
        Logger:info("Adding item \"%s\" to the wardrobe.", path)
        local tweakDbid = TweakDBID.new(path)
        local success, errorObject = self:addClothToWardrobe(tweakDbid)
        if not success then
            Logger:warn("Item \"%s\" was not added to the wardrobe: %s.", path, errorObject.message)
            if errorObject.id == ErrorID.failedFilter then
                local equivalentItem = self:addEquivalentClothesToWardrobe(tweakDbid)
                if equivalentItem then
                    Logger:warn("Added item \"%s\" instead, which has the same appearance.", equivalentItem)
                end
            end
        end
    end
end

-- Adds clothing items which are stored in the internal game database
function Mod:addAllClothesToWardrobe ()
    local clothingRecords = TweakDB:GetRecords("gamedataClothing_Record")
    for _, itemRecord in ipairs(clothingRecords) do
        local tweakDbid = itemRecord:GetID()
        local success, errorObject = self:addClothToWardrobe(tweakDbid)
        if not success then
            Logger:debug("Item \"%s\" was not added to the wardrobe: %s.", tweakDbid.value, errorObject.message)
        end
    end
end

-- Remove all clothing items which are stored in the wardrobe system
function Mod:removeAllClothesFromWardrobe ()
    local wardrobeSystem = Game.GetWardrobeSystem()
    if not wardrobeSystem then
        return false, "wardrobe system is unavailable"
    end

    local itemIds = wardrobeSystem:GetStoredItemIDs()
    for _,itemId in pairs(itemIds) do
        wardrobeSystem:ForgetItemID(itemId)
    end
end

function Mod:isBlacklistedByMod (tweakDbid)
    return self.blacklistSet[tweakDbid.value]
end

function Mod:showUi ()
    if self.initialized then
        self.config.showUi = true
        self:saveConfig()
    end
end

function Mod:updateBlacklistSet ()
    self.blacklistSet = {}
    for _, path in ipairs(self.config.blacklist) do
        local tweakDbid = TweakDBID.new(path)
        if not TDBID.IsValid(tweakDbid) then
            Logger:warn("path %s is not a valid TweakDBID, skipping from blacklist", path)
            goto continue
        end
        self.blacklistSet[path] = true
        ::continue::
    end
end

function Mod:updateLogLevel ()
    Logger.logLevel = self.config.logLevel
end

function Mod:isItemRemovalEnabled ()
    if self.canForgetItems == nil then
        local wardrobeSystem = Game.GetWardrobeSystem()
        self.canForgetItems = (wardrobeSystem and wardrobeSystem.ForgetItemID ~= nil)
    end
    return self.canForgetItems
end

local function buildAppearances ()
    local appearances = {}
    local clothingRecords = TweakDB:GetRecords("gamedataClothing_Record")
    for _, itemRecord in ipairs(clothingRecords) do
        local tweakDbid = itemRecord:GetID()
        local appearanceName = TweakDB:GetFlat(tweakDbid..".appearanceName")
        if Utils.isValidCname(appearanceName) then
            appearanceName = appearanceName.value
            if appearances[appearanceName] then
                table.insert(appearances[appearanceName], tweakDbid.value)
            else
                appearances[appearanceName] = {tweakDbid.value}
            end
        end
    end
    return appearances
end

function Mod:verifyAppearances()
    for appearanceName, paths in pairs(self.appearances) do
        local hasDuplicates = (#paths > 1)
        if hasDuplicates then
            local passingItems = {}
            for _, path in ipairs(paths) do
                if self:doesItemPassFilters(ItemID.FromTDBID(path)) then
                    table.insert(passingItems, path)
                end
            end
            if #passingItems > 1 then
                Logger:debug("Items {%s} have the same appearanceName \"%s\" but multiple of them pass through the filters."..
                             " Some of them might be broken.", table.concat(passingItems, ", "), appearanceName)
            end
        end
    end
end

function Mod:new ()
    self.initialized = false
    self.canForgetItems = nil

    registerForEvent("onInit", function ()
        if not self:loadConfig() then
            Logger:error("Mod will not work without configuration file")
            return
        end

        self.filters = {
            Filters.makeFilter(Filters.changeInputFromTweakDbidToItemId(Filters.doesItemExist), "mustExist", "item does not exist"),
            Filters.makeFilter(Filters.isClothingItem, "mustHaveClothingCategory", "item does not have the Clothing category"),
            Filters.makeFilter(Filters.changeInputFromTweakDbidToItemId(Filters.hasDisplayName), "mustHaveDisplayName", "item does not have displayName"),
            Filters.makeFilter(Filters.changeInputFromTweakDbidToItemId(Filters.hasAppearanceName), "mustHaveAppearanceName", "item does not have appearanceName"),
            Filters.makeFilter(Filters.negate(Filters.changeInputFromTweakDbidToItemId(Filters.isCraftingSpec)), "mustNotBeCraftingSpec", "item is/was probably a crafting spec"),
            Filters.makeFilter(Filters.negate(Filters.changeInputFromTweakDbidToItemId(Filters.isLifepathDuplicate)), "mustNotBeLifepathDuplicate", "item is probably a duplicate of a lifepath item"),
            Filters.makeFilter(Filters.negate(Filters.changeInputFromTweakDbidToItemId(function (tweakDbid) return self:isBlacklistedByMod(tweakDbid) end)), "mustNotBeOnBlacklist", "item is blacklisted by the mod"),
            Filters.makeFilter(Filters.negate(Filters.isOnInternalBlacklist), "mustNotBeOnInternalBlacklist", "item is on the wardrobe system's blacklist")
        }

        self.appearances = buildAppearances()
        self:verifyAppearances()

        if self:isItemRemovalEnabled() then
            Override('WardrobeSystem','GetFilteredInventoryItemsData', function(wardrobeSystem, equipmentArea)
                local result = {}

                local inventoryManager = InventoryDataManagerV2:new();
                inventoryManager:Initialize(Game.GetPlayer());

                local itemIds = wardrobeSystem:GetFilteredStoredItemIDs(equipmentArea)
                for _,itemId in pairs(itemIds) do
                    table.insert(result,inventoryManager:GetInventoryItemDataFromItemID(itemId))
                end
                return result
            end)
        end

        ObserveAfter('PlayerPuppet', 'OnMakePlayerVisibleAfterSpawn', function ()
            if self.config.addAllClothesOnPlayerSpawn then
                self:addAllClothesToWardrobe()
                Logger:debug("Added all clothes to the wardrobe because of OnMakePlayerVisibleAfterSpawn event.")
            end
        end)

        Ui:init(self)

        self.initialized = true
    end)

    registerForEvent("onOverlayOpen", function ()
        if not self.initialized or not self.config.showUi then
            return
        end
        Ui:onOverlayOpen()
    end)

    registerForEvent("onOverlayClose", function ()
        if not self.initialized or not self.config.showUi then
            return
        end
        Ui:onOverlayClose()
    end)

	registerForEvent("onDraw", function ()
        if not self.initialized or not self.config.showUi then
            return
        end
        Ui:onDraw()
    end)

    registerForEvent("onShutdown", function ()
        self.initialized = false
    end)

    return Mod
end

return Mod:new()
