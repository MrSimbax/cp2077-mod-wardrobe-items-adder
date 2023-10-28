local Utils = require("utils")

local Filters = {}

function Filters.hasDisplayName (tweakDBID)
    local locKey = TweakDB:GetFlat(tweakDBID..".displayName")
    return locKey ~= nil and locKey.hash ~= 0
end

function Filters.hasAppearanceName (tweakDBID)
    local cname = TweakDB:GetFlat(tweakDBID..".appearanceName")
    return cname ~= nil and (cname.hash_hi ~= 0 or cname.hash_lo ~= 0)
end

function Filters.isCraftingSpec (tweakDBID)
    local path = Utils.TdbidToString(tweakDBID)
    return TDBID.IsValid(TweakDB:GetFlat(tweakDBID..".CraftingData")) or
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

function Filters.doesItemExist (tweakDBID)
    return TweakDB:GetRecord(tweakDBID) ~= nil
end

function Filters.isLifepathDuplicate (tweakDBID)
    local path = Utils.TdbidToString(tweakDBID)
    return string.match(path, "^Items%.[qQ]301_Corpo_[MW]A_.*$") or
        string.match(path, "^Items%.[qQ]301_Nomad_[MW]A_.*$") or
        string.match(path, "^Items%.[qQ]301_Street_[MW]A_.*$")
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

-- Returns `function (itemId)` which returns the result from filter which is `function (tweakDBID)`
function Filters.tweakDbidToItemIdFilter (filter)
    return function (itemId)
        return filter(ItemID.GetTDBID(itemId))
    end
end

-- Returns `function (itemId)` which returns `not filter(itemId)`
function Filters.notFilter (filter)
    return function (itemId)
        return not filter(itemId)
    end
end

return Filters
