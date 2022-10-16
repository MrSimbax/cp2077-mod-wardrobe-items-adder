local Utils = {}

function Utils.split (str, delim)
    delim = delim or "%s"
    local pat = string.format("[^%s]*", delim)
    local t = {}
    for word in str:gmatch(pat) do
        t[#t + 1] = word
    end
    return t
end

function Utils.trim (str)
    return str:find("^%s*$") and '' or str:match("^%s*(.*%S)")
end

function Utils.serialize (file, object, indent)
    indent = indent or ""
    local t = type(object)
    if t == "string" then
        file:write(string.format("%q", object))
    elseif t == "number" or t == "boolean" or t == "nil" then
        local quoted = string.format("%q", object)
        file:write(quoted:sub(2, #quoted - 1))
    elseif t == "table" then
        local newindent = indent.."    "
        file:write("{\n")
        local n = nil
        for i, v in ipairs(object) do
            file:write(newindent)
            Utils.serialize(file, v, newindent)
            file:write(",\n")
            n = i
        end
        for k,v in pairs(object) do
            if n and type(k) == "number" and math.floor(k) == k and 1 <= k and k <= n then
                goto continue
            end
            file:write(newindent)
            if type(k) == "string" and string.find(k, "^[_%a][_%w]*$") then
                file:write(k)
            else
                file:write(string.format("[%q]", k))
            end
            file:write(" = ")
            Utils.serialize(file, v, newindent)
            file:write(",\n")
            ::continue::
        end
        file:write(indent.."}")
        if indent == "" then
            file:write("\n")
        end
    else
        error("cannot serialize a "..type(object))
    end
end

return Utils
