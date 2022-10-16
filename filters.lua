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
    return TDBID.IsValid(TweakDB:GetFlat(tweakDBID..".CraftingData"))
end

function Filters.isClothingItem (itemId)
    return RPGManager.GetItemCategory(itemId) == gamedataItemCategory.Clothing
end

function Filters.doesItemExist (tweakDBID)
    return TweakDB:GetRecord(tweakDBID) ~= nil
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
function Filters.tweakDbidToitemIdFilter (filter)
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
