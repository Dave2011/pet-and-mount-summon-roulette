
---- ToDo:
-- Fix PetdbUpdate message, shows too often
-- Better naming for summon info. Show name of pet/mount, and percentage
-- Group mounts so more of them are in one group. Ideally dynamic, like the 20 rarest in group one, next 40, and so on.
-- clear filters before summoning, otherwise it will bug out and only summon what has been filtered.
---
MountRouletteDB = MountRouletteDB or {}

MountRouletteDB.lastMountRarityGroup = MountRouletteDB.lastMountRarityGroup or nil
MountRouletteDB.lastPetRarityGroup = MountRouletteDB.lastPetRarityGroup or nil

-- Helper functions for new options system
local function getConfiguredRarityGroup(itemID, isMount)
    -- First check if we have a configured group for this item
    if MountRouletteDB.config and MountRouletteDB.config.rarityGroups then
        local originalRarity = isMount and getMountRarityGroup(itemID) or getPetRarityGroup(itemID)
        
        -- Find which configured group this item belongs to
        for i, group in ipairs(MountRouletteDB.config.rarityGroups) do
            if group.enabled and originalRarity >= group.minPercent and originalRarity < group.maxPercent then
                return i -- Return the group index as the new rarity group
            end
        end
    end
    
    -- Fallback to original system
    return isMount and getMountRarityGroup(itemID) or getPetRarityGroup(itemID)
end

local function getEnabledRarityGroups()
    if MountRouletteDB.config and MountRouletteDB.config.rarityGroups then
        local enabledGroups = {}
        for i, group in ipairs(MountRouletteDB.config.rarityGroups) do
            if group.enabled then
                table.insert(enabledGroups, i)
            end
        end
        return enabledGroups
    end
    
    -- Fallback to original groups
    return {3, 5, 7, 10, 15, 20, 30, 40}
end

local function isFeatureEnabled(featureType)
    if MountRouletteDB.config then
        if featureType == "mounts" then
            return MountRouletteDB.config.enableMounts ~= false
        elseif featureType == "pets" then
            return MountRouletteDB.config.enablePets ~= false
        end
    end
    return true -- Default to enabled
end

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

function getMountRarityGroup(mountID)
    local rarity = 0 -- code for mounts that are not in the rarity DB yet
    for rarityLevel, mountList in pairs(PetMountSummonRouletteData.mounts) do
        for _, id in ipairs(mountList) do
            if id == mountID then
                return tonumber(rarityLevel)
            end
        end
    end
    return rarity
end

function getPetRarityGroup(petID)
    local rarity = 0 -- code for mounts that are not in the rarity DB yet
    for rarityLevel, petList in pairs(PetMountSummonRouletteData.pets) do
        for _, id in ipairs(petList) do
            if id == petID then
                return tonumber(rarityLevel)
            end
        end
    end
    return rarity
end

function getNextMountRarityGroup(currentRarityGroup, mountType)
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

function getNextPetRarityGroup(currentRarityGroup)
    
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

function getAndMoveRandomMount(currentRarityGroup, mountType)
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

function getAndMoveRandomPet(currentRarityGroup)

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

function countTotalItemsInTable(t)
    local totalCount = 0
    for _, subTable in pairs(t) do
        if type(subTable) == "table" then
            for _ in pairs(subTable) do
                totalCount = totalCount + 1
            end
        end
    end
    return totalCount
end

function saveMountsToVariable()
    local totalUnsummonedMounts = 0
    if MountRouletteDB.mounts and MountRouletteDB.mounts.unsummoned then
        totalUnsummonedMounts = countTotalItemsInTable(MountRouletteDB.mounts.unsummoned) or 0
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[PetAndMountSummonRoulette]|r " .. totalUnsummonedMounts .. " number of unsummoned mounts")
    end
    
    if MountRouletteDB.mounts and MountRouletteDB.mounts.unsummoned and totalUnsummonedMounts > 0 then
        MountRouletteDB.mounts = MountRouletteDB.mounts or {
            summoned = { ground = {}, flying = {}, aquatic = {} },
            unsummoned = { ground = {}, flying = {}, aquatic = {} }
        }
        
    else MountRouletteDB.mounts = {
        summoned = { ground = {}, flying = {}, aquatic = {} },
        unsummoned = { ground = {}, flying = {}, aquatic = {} }
    }
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[PetAndMountSummonRoulette]|r " .. "var does not exists")
    end

    C_MountJournal.SetDefaultFilters()
    for i = 1, C_MountJournal.GetNumDisplayedMounts() do
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = C_MountJournal.GetDisplayedMountInfo(i)

        if mountID and isCollected then
            local creatureDisplayInfoID, description, source, isSelfMount, mountTypeID, uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = C_MountJournal.GetMountInfoExtraByID(mountID)

            local isGround, isFlying, isAquatic = getMountCriteria(mountTypeID)

            local rarityGroup = getConfiguredRarityGroup(mountID, true)
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

function savePetsToVariable()
    local totalUnsummonedPets = 0
    if MountRouletteDB.pets and MountRouletteDB.pets.unsummoned then
        totalUnsummonedPets = countTotalItemsInTable(MountRouletteDB.pets.unsummoned) or 0
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[PetAndMountSummonRoulette]|r " .. totalUnsummonedPets .. " number of unsummoned pets")
    end
    
    if MountRouletteDB.pets and MountRouletteDB.pets.unsummoned and totalUnsummonedPets > 0 then
        MountRouletteDB.pets = MountRouletteDB.pets or {
            summoned = { },
            unsummoned = { }
        }
    else 
        MountRouletteDB.pets = {
            summoned = { },
            unsummoned = { }
        }
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[PetAndMountSummonRoulette]|r " .. "Pet database reset")
    end

    -- Clear pet journal filters to ensure we see all pets
    C_PetJournal.SetAllPetTypesChecked(true)
    C_PetJournal.ClearSearchFilter()
    
    local totalPetsFound = 0
    for i = 1, C_PetJournal.GetNumPets() do
        local petID, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(i)

        if speciesID and owned then
            local rarityGroup = getConfiguredRarityGroup(speciesID, false)
            totalPetsFound = totalPetsFound + 1

            -- Save pet information in the appropriate category
            local petData = {
                name = speciesName,
                petID = petID,
                speciesID = speciesID
            }
            MountRouletteDB.pets.unsummoned[rarityGroup] = MountRouletteDB.pets.unsummoned[rarityGroup] or {}
            MountRouletteDB.pets.unsummoned[rarityGroup][petID] = petData
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[PetAndMountSummonRoulette]|r " .. totalPetsFound .. " pets loaded into database")
end

function getMountRidingCriteria()
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

function summonRandomMount()
    -- Check if mount summoning is enabled
    if not isFeatureEnabled("mounts") then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[PetAndMountSummonRoulette]|r " .. "Mount summoning is disabled in options.")
        return
    end

    local mountRidingCriteria = getMountRidingCriteria()

    if not mountRidingCriteria then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[PetAndMountSummonRoulette]|r " .. "No mounts allowed.")
        return
    end

    local lastMountRarityGroup = 0
    
    if MountRouletteDB.lastMountRarityGroup and MountRouletteDB.lastMountRarityGroup[mountRidingCriteria] then
        lastMountRarityGroup = MountRouletteDB.lastMountRarityGroup[mountRidingCriteria]
    else
        MountRouletteDB.lastMountRarityGroup = {
            ground = {},
            flying = {},
            aquatic = {}
        }
    end
    local rarityGroup = getNextMountRarityGroup(lastMountRarityGroup, mountRidingCriteria)
    local selectedMount = getAndMoveRandomMount(rarityGroup, mountRidingCriteria)

    if selectedMount then
        -- Get group name for better messaging
        local groupName = "Unknown"
        if MountRouletteDB.config and MountRouletteDB.config.rarityGroups and MountRouletteDB.config.rarityGroups[rarityGroup] then
            groupName = MountRouletteDB.config.rarityGroups[rarityGroup].name
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[PetAndMountSummonRoulette]|r " .. "Summoning " .. selectedMount.name .. " from " .. groupName .. " group.")
        C_MountJournal.SummonByID(selectedMount.mountID)
        if MountRouletteDB.lastMountRarityGroup and MountRouletteDB.lastMountRarityGroup[mountRidingCriteria] then
            MountRouletteDB.lastMountRarityGroup[mountRidingCriteria] = rarityGroup
        else
            MountRouletteDB.lastMountRarityGroup = MountRouletteDB.lastMountRarityGroup or {}
            MountRouletteDB.lastMountRarityGroup[mountRidingCriteria] = rarityGroup
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[PetAndMountSummonRoulette]|r " .. "No mounts available for summoning.")
    end
end

function summonRandomPet()
    -- Check if pet summoning is enabled
    if not isFeatureEnabled("pets") then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[PetAndMountSummonRoulette]|r " .. "Pet summoning is disabled in options.")
        return
    end

    local rarityGroup = getNextPetRarityGroup(MountRouletteDB.lastPetRarityGroup or 0)
    local selectedPet = getAndMoveRandomPet(rarityGroup)

    if selectedPet then
        -- Get group name for better messaging
        local groupName = "Unknown"
        if MountRouletteDB.config and MountRouletteDB.config.rarityGroups and MountRouletteDB.config.rarityGroups[rarityGroup] then
            groupName = MountRouletteDB.config.rarityGroups[rarityGroup].name
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[PetMountSummonRoulette]|r " .. "Summoning " .. selectedPet.name .. " from " .. groupName .. " group.")
        C_PetJournal.SummonPetByGUID(selectedPet.petID)
        MountRouletteDB.lastPetRarityGroup = rarityGroup
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[PetMountSummonRoulette]|r " .. "No pets available for summoning.")
    end
end


frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("COMPANION_UPDATE")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        saveMountsToVariable()
        savePetsToVariable()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[PetAndMountSummonRoulette]|r " .. "Mount & Pet Database refreshed")
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

-- Global reference to our options panel
local optionsPanel = nil

SLASH_PMSROPTIONS1 = "/pmsroptions"
SLASH_PMSROPTIONS2 = "/pmsrconfig"
SlashCmdList["PMSROPTIONS"] = function()
    -- Direct panel access - most reliable method
    if optionsPanel then
        if optionsPanel:IsShown() then
            optionsPanel:Hide()
        else
            optionsPanel:Show()
            optionsPanel:Raise() -- Bring to front
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[PetAndMountSummonRoulette]|r Options panel not loaded yet. Try again in a moment or /reload")
    end
end

-- Function to set the global panel reference (called from options file)
function SetOptionsPanel(panel)
    optionsPanel = panel
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[PetAndMountSummonRoulette]|r Options panel ready! Use /pmsroptions to open")
end
-- Debug command to check pet database status
SLASH_PMSRDEBUG1 = "/pmsrdebug"
SlashCmdList["PMSRDEBUG"] = function()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[PetAndMountSummonRoulette]|r === DEBUG INFO ===")
    
    -- Check if pet database exists
    if MountRouletteDB.pets and MountRouletteDB.pets.unsummoned then
        local totalPets = countTotalItemsInTable(MountRouletteDB.pets.unsummoned)
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[PetAndMountSummonRoulette]|r Total pets in database: " .. totalPets)
        
        -- Show pets by group
        for groupId, pets in pairs(MountRouletteDB.pets.unsummoned) do
            local count = 0
            for _ in pairs(pets) do
                count = count + 1
            end
            local groupName = "Group " .. groupId
            if MountRouletteDB.config and MountRouletteDB.config.rarityGroups and MountRouletteDB.config.rarityGroups[groupId] then
                groupName = MountRouletteDB.config.rarityGroups[groupId].name
            end
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[PetAndMountSummonRoulette]|r " .. groupName .. ": " .. count .. " pets")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[PetAndMountSummonRoulette]|r Pet database not initialized!")
    end
    
    -- Check configuration
    if MountRouletteDB.config and MountRouletteDB.config.rarityGroups then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[PetAndMountSummonRoulette]|r Configuration groups: " .. #MountRouletteDB.config.rarityGroups)
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[PetAndMountSummonRoulette]|r Pets enabled: " .. tostring(MountRouletteDB.config.enablePets))
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[PetAndMountSummonRoulette]|r Configuration not loaded!")
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[PetAndMountSummonRoulette]|r === END DEBUG ===")
end

-- Force refresh command
SLASH_PMSRREFRESH1 = "/pmsrrefresh"
SlashCmdList["PMSRREFRESH"] = function()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[PetAndMountSummonRoulette]|r Refreshing pet and mount databases...")
    saveMountsToVariable()
    savePetsToVariable()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[PetAndMountSummonRoulette]|r Database refresh complete!")
end