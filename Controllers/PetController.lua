local Pet = PetMountSummonRoulette.Pet

local PetController = {}
PetController.__index = PetController

function PetController:new()
    local obj = {
        pets = {},
    }
    setmetatable(obj, PetController)
    return obj
end

function PetController:addPet(pet)
    self.pets[pet.id] = pet
end

function PetController:removePetByID(id)
    self.pets[id] = nil
end

function PetController:getPetByID(id)
    return self.pets[id]
end

function PetController:getAllPets()
    return self.pets
end

function PetController:markSummoned(id)
    local pet = self:getPetByID(id)
    if pet then
        pet.summoned = true
    end
end

function PetController:buildFromJournal(existingPets)
    for i = 1, C_PetJournal.GetNumPets() do
        local petID, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(i)
        
        if speciesID and owned then
            local summoned = existingPets[petID] and existingPets[petID].summoned or false
            local rarity = 0
            for rarityLevel, petList in pairs(PetMountSummonRouletteData.pets) do
                for _, id in ipairs(petList) do
                    
                    if id == speciesID then
                        rarity = rarityLevel
                        break
                    end
                end
                if rarity > 0 then break end
            end
            self:addPet(Pet:new(petID, speciesName, summoned, rarity))
        end
    end

    for id in pairs(existingPets) do
        if not self:getPetByID(id) then
            existingPets[id] = nil
        end
    end
end

function PetController:saveToPersistentStorage()
    MountRouletteDB.pets = {}
    for id, pet in pairs(self:getAllPets()) do
        MountRouletteDB.pets[id] = {
            name = pet.name,
            summoned = pet.summoned,
            rarity = pet.rarity
        }
    end
end


function PetController:resetRarityGroup(rarityGroup)
    local resetCount = 0
    for _, pet in pairs(self.pets) do
        if pet.rarity == rarityGroup then
            pet.summoned = false
            resetCount = resetCount + 1
        end
    end
    if resetCount > 0 then
        self:saveToPersistentStorage()
    end
end

function PetController:getRandomUnsummonedPetByRarity(rarityGroup)
    local candidates = {}
    for _, pet in pairs(self.pets) do
        if pet.rarity == rarityGroup and not pet.summoned then
            table.insert(candidates, pet)
        end
    end

    if #candidates > 0 then
        return candidates[math.random(1, #candidates)]
    end

    -- No unsummoned pets found; reset and retry
    self:resetRarityGroup(rarityGroup)
    return self:getRandomPetByRarity(rarityGroup)
end

function PetController:getRandomPetByRarity(rarityGroup)
    local candidates = {}
    for _, pet in pairs(self.pets) do
        if pet.rarity == rarityGroup then
            table.insert(candidates, pet)
        end
    end

    if #candidates > 0 then
        return candidates[math.random(1, #candidates)]
    end
    return nil
end

function PetController:getAllRarityGroups()
    local rarityGroups = {}
    for _, pet in pairs(self.pets) do
        rarityGroups[pet.rarity] = true
    end
    local result = {}
    for rarity in pairs(rarityGroups) do
        table.insert(result, rarity)
    end
    table.sort(result)
    return result
end

PetMountSummonRoulette.PetController =  PetController