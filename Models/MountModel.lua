PetMountSummonRoulette = PetMountSummonRoulette or {}
local Mount = {}
Mount.__index = Mount

function Mount:new(id, name, isFlying, isGround, isAquatic, summoned, rarity)
    local obj = {
        id = id,
        name = name,
        isFlying = isFlying,
        isGround = isGround,
        isAquatic = isAquatic,
        summoned = summoned or false,
        rarity = rarity or 0
    }
    setmetatable(obj, Mount)
    return obj
end

PetMountSummonRoulette.Mount = Mount