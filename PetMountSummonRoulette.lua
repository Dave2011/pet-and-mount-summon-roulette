
MountRouletteDB = MountRouletteDB or {}

local MountController = PetMountSummonRoulette.MountController
local Mount = PetMountSummonRoulette.Mount

local PetController = PetMountSummonRoulette.PetController
local Pet = PetMountSummonRoulette.Pet

MountRouletteDB.lastMountRarityGroup = MountRouletteDB.lastMountRarityGroup or nil
MountRouletteDB.lastPetRarityGroup = MountRouletteDB.lastPetRarityGroup or nil

local mountDB = MountController:new()
if MountRouletteDB.mounts then
    for id, mountData in pairs(MountRouletteDB.mounts) do
        mountDB:addMount(Mount:new(
            id,
            mountData.name,
            mountData.isFlying,
            mountData.isGround,
            mountData.isAquatic,
            mountData.summoned,
            mountData.rarity
        ))
    end
end

local petDB = PetController:new()
if MountRouletteDB.pets then
    for id, petData in pairs(MountRouletteDB.pets) do
        petDB:addPet(Pet:new(
            id,
            petData.name,
            petData.summoned,
            petData.rarity
        ))
    end
end

local function getMountRidingCriteria()
    if IsIndoors() or UnitOnTaxi("player") then
        return nil -- Mounting is completely disabled
    end

    if IsSubmerged("player") then
        return "aquatic"
    end

    if IsFlyableArea() then
        return "flying"
    end

    if not IsFlyableArea() and not IsSubmerged("player") then
        return "ground"
    end

    return nil -- Fallback case: No valid mount criteria
end

local function summonRandomMount()
    local mountRidingCriteria = getMountRidingCriteria()

    if not mountRidingCriteria then
        print(ERR_MOUNT_NO_MOUNTS_ALLOWED) -- Default WoW warning message
        return
    end

    local rarityGroups = mountDB:getAllRarityGroups()
    table.sort(rarityGroups) -- Ensure groups are in ascending order

    local currentRarityGroup = MountRouletteDB.lastMountRarityGroup or rarityGroups[1]
    local nextRarityGroup = mountDB:getNextRarityGroup(currentRarityGroup)
    local mount = mountDB:getRandomUnsummonedMountByRarity(nextRarityGroup, mountRidingCriteria)

    if mount then
        print("Summoning " .. mount.name .. " from group " .. mount.rarity)
        C_MountJournal.SummonByID(mount.id)
        mountDB:markSummoned(mount.id)
        mountDB:saveToPersistentStorage()

        MountRouletteDB.lastMountRarityGroup = nextRarityGroup
    end
end

local function summonRandomPet()

    local rarityGroups = petDB:getAllRarityGroups()
    table.sort(rarityGroups) -- Ensure groups are in ascending order

    local currentRarityGroup = MountRouletteDB.lastPetRarityGroup or rarityGroups[1]
    local nextGroupIndex = nil

    -- Find the index of the next rarity group
    for i, group in ipairs(rarityGroups) do
        if group == currentRarityGroup then
            nextGroupIndex = i + 1
            break
        end
    end

    -- If no next group, loop back to the first group
    if not nextGroupIndex or not rarityGroups[nextGroupIndex] then
        nextGroupIndex = 1
    end

    local nextRarityGroup = rarityGroups[nextGroupIndex]
    local pet = petDB:getRandomUnsummonedPetByRarity(nextRarityGroup)

    if pet then
        print("Summoning " .. pet.name .. " from group " .. pet.rarity)
        C_PetJournal.SummonPetByGUID(pet.id)
        petDB:markSummoned(pet.id)
        petDB:saveToPersistentStorage()

        MountRouletteDB.lastPetRarityGroup = nextRarityGroup
    end
end


local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("COMPANION_UPDATE")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        mountDB:buildFromJournal(MountRouletteDB.mounts or {})
        mountDB:saveToPersistentStorage()
    end
end)

local frame = CreateFrame("Frame")
frame:RegisterEvent("PET_JOURNAL_LIST_UPDATE")

frame:SetScript("OnEvent", function(self, event)
    if event == "PET_JOURNAL_LIST_UPDATE" then
        petDB:buildFromJournal(MountRouletteDB.pets or {})
        petDB:saveToPersistentStorage()
    end
end)


SLASH_PMSRMOUNT1 = "/pmsrmount"
SlashCmdList["PMSRMOUNT"] = function()
    summonRandomMount()
end

SLASH_PMSRPET1 = "/pmsrpet"
SlashCmdList["PMSRPET"] = function()
    summonRandomPet()
end

SLASH_PMSRPETDISMISS1 = "/pmsrpetdismiss"
SlashCmdList["PMSRPETDISMISS"] = function()
    C_PetBattles.ForceEnd()
end