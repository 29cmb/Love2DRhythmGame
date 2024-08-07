local utils = {}

function utils:CheckCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2+w2 and
        x2 < x1+w1 and
        y1 < y2+h2 and
        y2 < y1+h1
end

function utils.clamp(val, lower, upper)
    if not lower then lower = 0 end
    if not upper then upper = math.huge end

    assert(val, "Value not provided")

    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end

function utils.find(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

function utils.round(num, decimalPlaces)
    local mult = 10^decimalPlaces
    return math.floor(num * mult + 0.5) / mult
end

return utils