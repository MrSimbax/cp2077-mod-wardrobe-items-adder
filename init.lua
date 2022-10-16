local Logger = require("logger"):init(1, '[WardrobeItemsAdder] ')
local Filters = require("filters")
local Ui = require("ui")
local Utils = require("utils")

local Mod = {}

function Mod:loadConfig ()
    local configChunk, errorMessage = loadfile("config.lua", "t", {})
    if not configChunk then
        Logger:warn("Could not load configuration file: %s", errorMessage)
        Logger:info("Trying to load the default configuration")
        configChunk, errorMessage = loadfile("default_config.lua", "t", {})
        if not configChunk then
            Logger:error("Could not load the default configuration: %s", errorMessage)
            return false
        end
    end
    local config = configChunk()
    if not config or type(config) ~= "table" then
        Logger:error("Bad configuration")
        return false
    end
    self.config = config
    self:updateBlacklistSet()
    self:saveConfig()
    return true
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

    for filterName, filter in pairs(self.filters) do
        if self.config.isFilterEnabled[filterName] and not filter.condition(itemId) then
            return false, filter.failureMessage
        end
    end

    if self.config.isFilterEnabled.mustNotBeOnInternalBlacklist and wardrobeSystem:IsItemBlacklisted(itemId) then
        return false, "item is on wardrobe system's blacklist"
    end

    local success = wardrobeSystem:StoreUniqueItemIDAndMarkNew(itemId)

    if not success then
        return false, "wardrobe system refused to store new item, reason unknown (is it already in the wardrobe?)"
    end

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
            Logger:debug("Item \"%s\" was not added to wardrobe: %s.", TDBID.ToStringDEBUG(tweakDBID), errorMessage)
        end
    end
end

function Mod:isBlacklistedByMod (tweakDBID)
    return self.blacklistSet[self.tweakDbidToPathTable[TDBID.ToStringDEBUG(tweakDBID)]]
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
        self.tweakDbidToPathTable[TDBID.ToStringDEBUG(tweakDBID)] = path
        ::continue::
    end
end

function Mod:new ()
    self.initialized = false

    registerForEvent("onInit", function ()
        if not Mod:loadConfig() then
            Logger:error("Mod will not work without configuration file")
            return
        end

        Logger.logLevel = self.config.logLevel

        self.filters = {
            mustHaveClothingCategory = Filters.makeFilter(Filters.isClothingItem, "item does not have the Clothing category"),
            mustHaveDisplayName = Filters.makeFilter(Filters.tweakDbidToitemIdFilter(Filters.hasDisplayName), "item does not have displayName"),
            mustHaveAppearanceName = Filters.makeFilter(Filters.tweakDbidToitemIdFilter(Filters.hasAppearanceName), "item does not have appearanceName"),
            mustNotBeCraftingSpec = Filters.makeFilter(Filters.notFilter(Filters.tweakDbidToitemIdFilter(Filters.isCraftingSpec)), "item is a crafting spec"),
            mustNotBeOnBlacklist = Filters.makeFilter(Filters.notFilter(Filters.tweakDbidToitemIdFilter(function (tweakDBID)
                return self:isBlacklistedByMod(tweakDBID)
            end)), "item is blacklisted by the mod")
        }

        Override('PlayerPuppet', 'OnMakePlayerVisibleAfterSpawn', function (player, evt, wrapped)
            wrapped(evt)
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
