-- Wardrobe Items Adder v1.2.1
local Logger = require("logger"):init(1, '[WardrobeItemsAdder] ')
local Filters = require("filters")
local Ui = require("ui")
local Utils = require("utils")
local defaultConfig = require("default_config")

local Mod = {}

function Mod:loadConfig ()
    local configChunk, errorMessage = loadfile("config.lua", "t", {})
    if not configChunk then
        Logger:warn("Could not load configuration file: %s", errorMessage)
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
        Logger:error("Could not save current configuration: %s", errorMessage)
        return false, errorMessage
    end
    file:write("return ")
    Utils.serialize(file, self.config)
    file:close()
    return true
end

function Mod:addClothToWardrobe (itemTid)
    if not TDBID.IsValid(itemTid) then
        return false, "not valid TweakDBID"
    end

    local wardrobeSystem = Game.GetWardrobeSystem()
    if not wardrobeSystem then
        return false, "wardrobe system is unavailable"
    end

    local itemId = ItemID.new(itemTid)
    if not ItemID.IsValid(itemId) then
        return false, "not valid ItemID"
    end

    for _, filter in ipairs(self.filters) do
        if self.config.isFilterEnabled[filter.configKey] and not filter.condition(itemId) then
            return false, filter.failureMessage
        end
    end

    if self.config.isFilterEnabled.mustNotBeOnInternalBlacklist and wardrobeSystem:IsItemBlacklisted(itemId) then
        return false, "item is on wardrobe system's blacklist"
    end

    local uniqueItemId = wardrobeSystem:GetStoredItemID(itemTid)
    if ItemID.IsValid(uniqueItemId) then
        local uniqueTdbid = Utils.TdbidToString(uniqueItemId.id)
        if not self.duplicates[uniqueTdbid] then
            self.duplicates[uniqueTdbid] = {[Utils.TdbidToString(itemTid)] = true}
        else
            self.duplicates[uniqueTdbid][Utils.TdbidToString(itemTid)] =  true
        end
        return false, "item or its duplicate is already in the wardrobe"
    end

    local success = wardrobeSystem:StoreUniqueItemID(itemId)
    if not success then
        return false, "storing item in the wardrobe unsuccessful, reason unknown"
    end

    -- Not sure what it does but apparently this cannot fail after successful StoreUniqueItemId()
    WardrobeSystem.SendWardrobeAddItemRequest(itemId)

    uniqueItemId = wardrobeSystem:GetStoredItemID(itemTid)
    self.duplicates[Utils.TdbidToString(uniqueItemId.id)] = {[Utils.TdbidToString(itemTid)] = true}

    return true
end

-- Adds clothes from a user-specified list of items
function Mod:addClothesToWardrobe (clothes)
    for _, path in ipairs(clothes) do
        Logger:info("Adding item \"%s\" to wardrobe.", path)
        local tweakDBID = TweakDBID.new(path)
        local success, errorMessage = self:addClothToWardrobe(tweakDBID)
        if not success then
            Logger:warn("Item \"%s\" was not added to wardrobe: %s.", path, errorMessage)
        end
    end
end

-- Adds clothing items which are stored in the internal game database
function Mod:addAllClothesToWardrobe ()
    local clothingRecords = TweakDB:GetRecords("gamedataClothing_Record")
    for _, itemRecord in ipairs(clothingRecords) do
        local tweakDBID = itemRecord:GetID()
        local success, errorMessage = self:addClothToWardrobe(tweakDBID)
        if not success then
            -- Note: path cannot be retrieved from TDBID as it is some kind of hash
            Logger:debug("Item \"%s\" was not added to wardrobe: %s.", Utils.TdbidToString(tweakDBID), errorMessage)
        end
    end
    self:printDuplicates()
end

function Mod:printDuplicates ()
    for uniqueTdbid, tdbids in pairs(self.duplicates) do
        local hasDuplicates = (next(tdbids, next(tdbids)) ~= nil)
        if hasDuplicates then
            local tdbidsAsStrings = {}
            for tdbid, _ in pairs(tdbids) do
                table.insert(tdbidsAsStrings, string.format("%q", tdbid))
            end
            Logger:debug("Items {%s} have the same unique item ID \"%s\".", table.concat(tdbidsAsStrings, ", "), uniqueTdbid)
        end
    end
end

function Mod:isBlacklistedByMod (tweakDBID)
    return self.blacklistSet[self.tweakDbidToPathTable[Utils.TdbidToString(tweakDBID)]]
end

function Mod:showUi ()
    if self.initialized then
        self.config.showUi = true
        self:saveConfig()
    end
end

function Mod:updateBlacklistSet ()
    self.blacklistSet = {}
    self.tweakDbidToPathTable = {}
    for _, path in ipairs(self.config.blacklist) do
        local tweakDBID = TweakDBID.new(path)
        if not TDBID.IsValid(tweakDBID) then
            Logger:warn("path %s is not a valid TweakDBID, skipping from blacklist")
            goto continue
        end
        self.blacklistSet[path] = true
        self.tweakDbidToPathTable[Utils.TdbidToString(tweakDBID)] = path
        ::continue::
    end
end

function Mod:updateLogLevel ()
    Logger.logLevel = self.config.logLevel
end

function Mod:new ()
    self.initialized = false
    self.duplicates = {}

    registerForEvent("onInit", function ()
        if not Mod:loadConfig() then
            Logger:error("Mod will not work without configuration file")
            return
        end

        self.filters = {
            Filters.makeFilter(Filters.tweakDbidToitemIdFilter(Filters.doesItemExist), "mustExist", "item does not exist"),
            Filters.makeFilter(Filters.isClothingItem, "mustHaveClothingCategory", "item does not have the Clothing category"),
            Filters.makeFilter(Filters.tweakDbidToitemIdFilter(Filters.hasDisplayName), "mustHaveDisplayName", "item does not have displayName"),
            Filters.makeFilter(Filters.tweakDbidToitemIdFilter(Filters.hasAppearanceName), "mustHaveAppearanceName", "item does not have appearanceName"),
            Filters.makeFilter(Filters.notFilter(Filters.tweakDbidToitemIdFilter(Filters.isCraftingSpec)), "mustNotBeCraftingSpec", "item is a crafting spec"),
            Filters.makeFilter(Filters.notFilter(Filters.tweakDbidToitemIdFilter(function (tweakDBID)
                return self:isBlacklistedByMod(tweakDBID)
            end)), "mustNotBeOnBlacklist", "item is blacklisted by the mod")
        }

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
