local Utils = require("utils")

local Filters = {}

function Filters.hasDisplayName (tweakDbid)
    local locKey = TweakDB:GetFlat(tweakDbid..".displayName")
    return locKey ~= nil and locKey.hash ~= 0
end

function Filters.hasAppearanceName (tweakDbid)
    return Utils.isValidCname(TweakDB:GetFlat(tweakDbid..".appearanceName"))
end

function Filters.isCraftingSpec (tweakDbid)
    local path = tweakDbid.value
    return TDBID.IsValid(TweakDB:GetFlat(tweakDbid..".CraftingData")) or
        -- Note: in patch 2.0 they removed stats from clothes, and removed .CraftingData field,
        -- as I guess there's no point in crafting clothes now.
        -- However, I have not found a way to automatically detect if the item was a crafting spec...
        -- ...so the filter tries to guess it from name patterns alone.
        string.match(path, "^Items%..*_Crafting$") or
        string.match(path, "^Items%.V?Hard_.*$") or
        string.match(path, "^Items%.Normal_.*$") or
        string.match(path, "^Items%.Story_.*$") or
        string.match(path, "^Items%.Weak_%d+_.*$") or
        string.match(path, "^Items%.Avg_%d+_.*$") or
        string.match(path, "^Items%.Str_%d+_.*$") or
        string.match(path, "^.*_Legendary$") or
        string.match(path, "^.*_Epic$") or
        string.match(path, "^.*_Crafted$")
end

function Filters.isClothingItem (itemId)
    return RPGManager.GetItemCategory(itemId) == gamedataItemCategory.Clothing
end

function Filters.doesItemExist (tweakDbid)
    return TweakDB:GetRecord(tweakDbid) ~= nil
end

function Filters.isLifepathDuplicate (tweakDbid)
    local path = tweakDbid.value
    return string.match(path, "^Items%.[qQ]301_Corpo_[MW]A_.*$") or
        string.match(path, "^Items%.[qQ]301_Nomad_[MW]A_.*$") or
        string.match(path, "^Items%.[qQ]301_Street_[MW]A_.*$")
end

function Filters.isOnInternalBlacklist (itemId)
    local wardrobeSystem = Game.GetWardrobeSystem()
    return wardrobeSystem and wardrobeSystem:IsItemBlacklisted(itemId)
end

-- condition is a function with parameters (itemId) returning a bool
-- failureMessage is a string which can be displayed if the filter returns false
function Filters.makeFilter (condition, configKey, failureMessage)
    return {
        condition = condition,
        configKey = configKey,
        failureMessage = failureMessage
    }
end

function Filters.changeInputFromTweakDbidToItemId (filter)
    return function (itemId)
        return filter(ItemID.GetTDBID(itemId))
    end
end

function Filters.negate (filter)
    return function (itemId)
        return not filter(itemId)
    end
end

return Filters
