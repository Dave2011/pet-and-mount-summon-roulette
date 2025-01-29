PetMountSummonRoulette = PetMountSummonRoulette or {}
local Pet = {}
Pet.__index = Pet

function Pet:new(id, name, summoned, rarity)
    local obj = {
        id = id,
        name = name,
        summoned = summoned or false,
        rarity = rarity or 0
    }
    setmetatable(obj, Pet)
    return obj
end

PetMountSummonRoulette.Pet = Pet