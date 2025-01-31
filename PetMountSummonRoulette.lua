
MountRouletteDB = MountRouletteDB or {}

MountRouletteDB.lastMountRarityGroup = MountRouletteDB.lastMountRarityGroup or nil
MountRouletteDB.lastPetRarityGroup = MountRouletteDB.lastPetRarityGroup or nil


local function getMountCriteria(mountTypeID) 
            --[[ mountID fly ground aqua desciption
                230 0 1 0 for most ground mounts
                231 0 1 0 for  [Riding Turtle] and  [Sea Turtle]
                232 0 0 1 for  [Vashj'ir Seahorse] (was named Abyssal Seahorse prior to Warlords of Draenor)
                241 0 0 0 for Blue, Green, Red, and Yellow Qiraji Battle Tank (restricted to use inside Temple of Ahn'Qiraj)
                242 0 0 0 for Swift Spectral Gryphon (hidden in the mount journal, used while dead in certain zones)
                247 1 0 0 for  [Disc of the Red Flying Cloud]
                248 1 0 0 for most flying mounts, including those that change capability based on riding skill
                254 0 0 1 for  [Reins of Poseidus],  [Brinedeep Bottom-Feeder] and  [Fathom Dweller]
                269 0 1 0 for  [Reins of the Azure Water Strider] and  [Reins of the Crimson Water Strider]
                284 0 1 0 for  [Chauffeured Chopper] and Chauffeured Mechano-Hog
                398 1 0 0 for  [Kua'fon's Harness]
                402 1 0 0 for Dragonriding
                407 1 1 1 for  [Deepstar Polyp] and  [Otterworldly Ottuk Carrier]
                408 0 1 0 for  [Unsuccessful Prototype Fleetpod]
                412 0 1 1 for Otto and Ottuk
                424 1 0 0 for Dragonriding mounts, including mounts that have dragonriding animations but are not yet enabled for dragonriding.
                436 1 0 1 for Wondrous Wavewhisker ]]
            --
            local isGround, isFlying, isAquatic = false, false, false

            if (mountTypeID == 230 or mountTypeID == 231 or mountTypeID == 269 or mountTypeID == 284 or mountTypeID == 408) then
                isGround = true

            elseif (mountTypeID == 232 or mountTypeID == 254) then 
                isAquatic = true

            elseif (mountTypeID == 247 or mountTypeID == 248 or mountTypeID == 398 or mountTypeID == 402 or mountTypeID == 424 ) then
                isFlying = true

            elseif mountTypeID == 412 then
                isGround  = true
                isAquatic = true

            elseif mountTypeID == 436 then
                isFlying  = true
                isAquatic = true

            elseif mountTypeID == 407 then
                isGround  = true
                isFlying  = true
                isAquatic = true
            end
            return isGround, isFlying, isAquatic
end

local function getMountRarityGroup(mountID)
    local rarity = 0 -- code for mounts that are not in the rarity DB yet
    for rarityLevel, mountList in pairs(PetMountSummonRouletteData.mounts) do
        for _, id in ipairs(mountList) do
            if id == mountID then
                rarity = rarityLevel
                break
            end
        end
        if rarity > 0 then break end
    end
    return rarity
end

local function getPetRarityGroup(petID)
    local rarity = 0 -- code for mounts that are not in the rarity DB yet
    for rarityLevel, petList in pairs(PetMountSummonRouletteData.pets) do
        for _, id in ipairs(petList) do
            if id == petID then
                rarity = rarityLevel
                break
            end
        end
        if rarity > 0 then break end
    end
    return rarity
end

local function getNextMountRarityGroup(currentRarityGroup, mountType)
    -- Ensure mountType is valid
    if not MountRouletteDB.mounts.unsummoned[mountType] then
        error("Invalid mount type: " .. tostring(mountType))
    end

    -- Extract all rarity groups for the given mount type
    local rarityGroups = {}
    for rarityGroup in pairs(MountRouletteDB.mounts.unsummoned[mountType]) do
        table.insert(rarityGroups, rarityGroup)
    end

    -- If no rarity groups are available, return nil
    if #rarityGroups == 0 then
        return nil
    end

    -- Sort the rarity groups in ascending order
    table.sort(rarityGroups)

    -- Find the index of the current rarity group
    local currentIndex = nil
    for i, rarityGroup in ipairs(rarityGroups) do
        if rarityGroup == currentRarityGroup then
            currentIndex = i
            break
        end
    end

    -- If the current rarity group is not found, start from the first one
    if not currentIndex then
        currentIndex = 1
    end

    -- Get the next rarity group (wrap around if necessary)
    local nextIndex = currentIndex + 1
    if nextIndex > #rarityGroups then
        nextIndex = 1
    end
    return rarityGroups[nextIndex]
end

local function getNextPetRarityGroup(currentRarityGroup)
    
    -- Extract all rarity groups for the given mount type
    local rarityGroups = {}
    for rarityGroup in pairs(MountRouletteDB.pets.unsummoned) do
        table.insert(rarityGroups, rarityGroup)
    end

    -- If no rarity groups are available, return nil
    if #rarityGroups == 0 then
        return nil
    end

    -- Sort the rarity groups in ascending order
    table.sort(rarityGroups)

    -- Find the index of the current rarity group
    local currentIndex = nil
    for i, rarityGroup in ipairs(rarityGroups) do
        if rarityGroup == currentRarityGroup then
            currentIndex = i
            break
        end
    end

    -- If the current rarity group is not found, start from the first one
    if not currentIndex then
        currentIndex = 1
    end

    -- Get the next rarity group (wrap around if necessary)
    local nextIndex = currentIndex + 1
    if nextIndex > #rarityGroups then
        nextIndex = 1
    end
    return rarityGroups[nextIndex]
end

local function getAndMoveRandomMount(currentRarityGroup, mountType)
    -- Ensure mountType is valid
    if not MountRouletteDB.mounts.unsummoned[mountType] then
        error("Invalid mount type: " .. tostring(mountType))
    end

    -- Get the next rarity group
    local nextRarityGroup = getNextMountRarityGroup(currentRarityGroup, mountType)
    if not nextRarityGroup then
        return nil  -- No unsummoned mounts available
    end

    -- Get all mounts in the next rarity group
    local mounts = MountRouletteDB.mounts.unsummoned[mountType][nextRarityGroup]

    -- Check if the mounts table is empty
    local isEmpty = true
    for _ in pairs(mounts) do
        isEmpty = false
        break
    end

    if isEmpty then
        -- No mounts left in this rarity group, reset the unsummoned list
        MountRouletteDB.mounts.unsummoned[mountType][nextRarityGroup] = MountRouletteDB.mounts.summoned[mountType][nextRarityGroup] or {}
        MountRouletteDB.mounts.summoned[mountType][nextRarityGroup] = {}
        mounts = MountRouletteDB.mounts.unsummoned[mountType][nextRarityGroup]
    end

    -- Convert the mounts table to an array for easier random selection
    local mountArray = {}
    for mountID, mountData in pairs(mounts) do
        table.insert(mountArray, mountData)
    end

    -- Select a random mount
    if #mountArray > 0 then
        local randomIndex = math.random(1, #mountArray)
        local selectedMount = mountArray[randomIndex]

        -- Move the selected mount from unsummoned to summoned
        MountRouletteDB.mounts.unsummoned[mountType][nextRarityGroup][selectedMount.mountID] = nil
        MountRouletteDB.mounts.summoned[mountType][nextRarityGroup] = MountRouletteDB.mounts.summoned[mountType][nextRarityGroup] or {}
        MountRouletteDB.mounts.summoned[mountType][nextRarityGroup][selectedMount.mountID] = selectedMount

        return selectedMount
    else
        return nil  -- No mounts found (should not happen after reset)
    end
end

local function getAndMoveRandomPet(currentRarityGroup)

     -- Get the next rarity group
    local nextRarityGroup = getNextPetRarityGroup(currentRarityGroup)
    if not nextRarityGroup then
        return nil  -- No unsummoned pets available
    end

    -- Get all pets in the next rarity group
    local pets = MountRouletteDB.pets.unsummoned[nextRarityGroup]

    -- Check if the pets table is empty
    local isEmpty = true
    for _ in pairs(pets) do
        isEmpty = false
        break
    end

    if isEmpty then
        -- No pets left in this rarity group, reset the unsummoned list
        MountRouletteDB.pets.unsummoned[nextRarityGroup] = MountRouletteDB.pets.summoned[nextRarityGroup] or {}
        MountRouletteDB.pets.summoned[nextRarityGroup] = {}
        pets = MountRouletteDB.pets.unsummoned[nextRarityGroup]
    end

    -- Convert the pets table to an array for easier random selection
    local petArray = {}
    for mountID, mountData in pairs(pets) do
        table.insert(petArray, mountData)
    end

    -- Select a random mount
    if #petArray > 0 then
        local randomIndex = math.random(1, #petArray)
        local selectedPet = petArray[randomIndex]

        -- Move the selected petfrom unsummoned to summoned
        MountRouletteDB.pets.unsummoned[nextRarityGroup][selectedPet.petID] = nil
        MountRouletteDB.pets.summoned[nextRarityGroup] = MountRouletteDB.pets.summoned[nextRarityGroup] or {}
        MountRouletteDB.pets.summoned[nextRarityGroup][selectedPet.petID] = selectedPet

        return selectedPet
    else
        return nil  -- No mounts found (should not happen after reset)
    end
end

local function saveMountsToVariable()
  
    if MountRouletteDB.mounts and MountRouletteDB.mounts.unsummoned and #MountRouletteDB.mounts.unsummoned > 0 then
        MountRouletteDB.mounts = MountRouletteDB.mounts or {
            summoned = { ground = {}, flying = {}, aquatic = {} },
            unsummoned = { ground = {}, flying = {}, aquatic = {} }
        }
    else MountRouletteDB.mounts = {
        summoned = { ground = {}, flying = {}, aquatic = {} },
        unsummoned = { ground = {}, flying = {}, aquatic = {} }
    } end

    C_MountJournal.SetDefaultFilters()
    for i = 1, C_MountJournal.GetNumDisplayedMounts() do
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = C_MountJournal.GetDisplayedMountInfo(i)

        if mountID and isCollected then
            local creatureDisplayInfoID, description, source, isSelfMount, mountTypeID, uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = C_MountJournal.GetMountInfoExtraByID(mountID)

            local isGround, isFlying, isAquatic = getMountCriteria(mountTypeID)

            local rarityGroup = getMountRarityGroup(mountID)

            -- Save mount information in the appropriate category
            local mountData = {
                name = name,
                mountID = mountID
            }

            if isGround then
                MountRouletteDB.mounts.unsummoned.ground[rarityGroup] = MountRouletteDB.mounts.unsummoned.ground[rarityGroup] or {}
                MountRouletteDB.mounts.unsummoned.ground[rarityGroup][mountID] = mountData
            end
            if isFlying then
                MountRouletteDB.mounts.unsummoned.flying[rarityGroup] = MountRouletteDB.mounts.unsummoned.flying[rarityGroup] or {}
                MountRouletteDB.mounts.unsummoned.flying[rarityGroup][mountID] = mountData
            end
            if isAquatic then
                MountRouletteDB.mounts.unsummoned.aquatic[rarityGroup] = MountRouletteDB.mounts.unsummoned.aquatic[rarityGroup] or {}
                MountRouletteDB.mounts.unsummoned.aquatic[rarityGroup][mountID] = mountData
            end
        end
    end
end

local function savePetsToVariable()
  
    if MountRouletteDB.pets and MountRouletteDB.pets.unsummoned and #MountRouletteDB.pets.unsummoned > 0 then
        MountRouletteDB.pets = MountRouletteDB.pets or {
            summoned = { },
            unsummoned = { }
        }
    else MountRouletteDB.pets = {
        summoned = { },
        unsummoned = { }
    } end

    C_MountJournal.SetDefaultFilters()
    for i = 1, C_PetJournal.GetNumPets() do
        local petID, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(i)

        if speciesID and owned then
           local rarityGroup = getPetRarityGroup(speciesID)

            -- Save mount information in the appropriate category
            local petData = {
                name = speciesName,
                petID = petID
            }
            MountRouletteDB.pets.unsummoned[rarityGroup] = MountRouletteDB.pets.unsummoned[rarityGroup] or {}
            MountRouletteDB.pets.unsummoned[rarityGroup][petID] = petData
        end
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

    local rarityGroup = getNextMountRarityGroup(MountRouletteDB.lastMountRarityGroup[mountRidingCriteria] or 0, mountRidingCriteria)
    local selectedMount = getAndMoveRandomMount(rarityGroup, mountRidingCriteria)

    if selectedMount then
        print("Summoning mount from group " .. tostring(rarityGroup))  -- Fixed: Access mountID directly
        C_MountJournal.SummonByID(selectedMount.mountID)
        if MountRouletteDB.lastMountRarityGroup and MountRouletteDB.lastMountRarityGroup[mountRidingCriteria] then
            MountRouletteDB.lastMountRarityGroup[mountRidingCriteria] = rarityGroup
        else
            MountRouletteDB.lastMountRarityGroup = MountRouletteDB.lastMountRarityGroup or {}
            MountRouletteDB.lastMountRarityGroup[mountRidingCriteria] = rarityGroup
        end
    else
        print("No mounts available for summoning.")
    end
end

local function summonRandomPet()

    local rarityGroup = getNextPetRarityGroup(MountRouletteDB.lastPetRarityGroup or 0)
    local selectedPet = getAndMoveRandomPet(rarityGroup)

    if selectedPet then
        print("Summoning pet from group " .. tostring(rarityGroup))  -- Fixed: Access mountID directly
        C_PetJournal.SummonPetByGUID(selectedPet.petID)
        MountRouletteDB.lastPetRarityGroup = rarityGroup
    else
        print("No pets available for summoning.")
    end
end


local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("COMPANION_UPDATE")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        saveMountsToVariable()
    end
end)

local frame = CreateFrame("Frame")
frame:RegisterEvent("PET_JOURNAL_LIST_UPDATE")

frame:SetScript("OnEvent", function(self, event)
    if event == "PET_JOURNAL_LIST_UPDATE" then
        savePetsToVariable()
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