
-- Pet & Mount Summon Roulette
-- Author: Zalador (Updated by Antigravity)
-- Data provided by dataforazeroth.com

MountRouletteDB = MountRouletteDB or {}
local ADDON_NAME = "PetMountSummonRoulette"

-- Constants
local RARE_GROUP_SIZE = 20
local RARITY_THRESHOLD = 50.0

-- State
local sessionState = {
    mountGroups = {}, -- [groupIndex] = { {mountID=123, name="...", mountTypeID=...}, ... }
    petGroups = {},
    currentMountGroup = 1,
    currentPetGroup = 1,
    mountsInitialized = false,
    petsInitialized = false
}

-- Utility: Print to Chat
local function PrintMessage(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[" .. ADDON_NAME .. "]|r " .. msg)
end

local function PrintError(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[" .. ADDON_NAME .. "]|r " .. msg)
end

-- Sorting Comparator: Rarity Ascending (Rare -> Common), Name Ascending as tie breaker
local function RaritySort(a, b)
    if a.rarity ~= b.rarity then
        return (a.rarity or 100) < (b.rarity or 100)
    end
    return (a.name or "") < (b.name or "")
end

-- Helper: Get Rarity Color Code
local function GetRarityColor(rarity)
    local r = rarity or 100
    if r < 20.0 then
        return "|cffff8000" -- Legendary (Orange)
    elseif r < 40.0 then
        return "|cffa335ee" -- Epic (Purple)
    elseif r < 60.0 then
        return "|cff0070dd" -- Rare (Blue)
    else
        return "|cff1eff00" -- Common (Green)
    end
end

-- Helper: Check Mount Category
-- Using IDs from WoW Wiki/API
-- Flying: 248 (Classic Flying), 247 (Red Flying Cloud), 402 (Dragonriding/Regular Flying in new patches), 407, 412, etc.
-- Ground: 230, 269, 284, 242...
-- Aquatic: 231, 232, 254
local function IsFlyingMount(typeID)
    return typeID == 248 or typeID == 247 or typeID == 402 or typeID == 407 or typeID == 412 or typeID == 424
end

local function IsAquaticMount(typeID)
    return typeID == 231 or typeID == 232 or typeID == 254
end

-- Grouping Logic: Hybrid Strategy
local function CreateHybridGroups(items)
    local groups = {}
    
    local rares = {}
    local commons = {} 
    
    for _, item in ipairs(items) do
        if (item.rarity or 100) < RARITY_THRESHOLD then
            table.insert(rares, item)
        else
            table.insert(commons, item)
        end
    end
    
    -- 1. Process Rares
    table.sort(rares, RaritySort)
    local currentChunk = {}
    for _, item in ipairs(rares) do
        table.insert(currentChunk, item)
        if #currentChunk >= RARE_GROUP_SIZE then
            table.insert(groups, currentChunk)
            currentChunk = {}
        end
    end
    if #currentChunk > 0 then
        table.insert(groups, currentChunk)
    end
    
    -- 2. Process Commons
    local buckets = {}
    for i = 5, 10 do buckets[i] = {} end
    
    for _, item in ipairs(commons) do
        local r = item.rarity or 100
        local bucketIndex = math.floor(r / 10)
        if bucketIndex < 5 then bucketIndex = 5 end
        if bucketIndex > 10 then bucketIndex = 10 end
        
        table.insert(buckets[bucketIndex], item)
    end
    
    for i = 5, 10 do
        if #buckets[i] > 0 then
            table.sort(buckets[i], RaritySort)
            table.insert(groups, buckets[i])
        end
    end
    
    return groups
end


-- Initialize Dynamic Mount Groups
local function InitializeMounts()
    local allCollectedMounts = {}
    
    local numMounts = C_MountJournal.GetNumMounts()
    for i = 1, numMounts do
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = C_MountJournal.GetMountInfoByID(i)
        
        if mountID and isCollected and (not shouldHideOnChar) then
             local rarity = PetMountSummonRouletteData.mountRarity[mountID] or 100
             -- Capture Mount Type
             local _, _, _, _, mountTypeID = C_MountJournal.GetMountInfoExtraByID(mountID)
             
             table.insert(allCollectedMounts, {
                 mountID = mountID,
                 name = name,
                 rarity = rarity,
                 spellID = spellID,
                 mountTypeID = mountTypeID
             })
        end
    end
    
    sessionState.mountGroups = CreateHybridGroups(allCollectedMounts)
    sessionState.mountsInitialized = true
    
    if MountRouletteDB.lastMountGroupIndex and MountRouletteDB.lastMountGroupIndex <= #sessionState.mountGroups then
        sessionState.currentMountGroup = MountRouletteDB.lastMountGroupIndex
    else
        sessionState.currentMountGroup = 1
    end
end

-- Initialize Dynamic Pet Groups
local function InitializePets()
    local allCollectedPets = {}
    C_PetJournal.ClearSearchFilter()
    local numPets = C_PetJournal.GetNumPets()
    
    for i = 1, numPets do
        local petID, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(i)
        
        if owned and speciesID then
             local rarity = PetMountSummonRouletteData.petRarity[speciesID] or 100
             table.insert(allCollectedPets, {
                 petID = petID,
                 speciesID = speciesID,
                 name = customName or speciesName,
                 rarity = rarity
             })
        end
    end
    
    sessionState.petGroups = CreateHybridGroups(allCollectedPets)
    sessionState.petsInitialized = true
    
    if MountRouletteDB.lastPetGroupIndex and MountRouletteDB.lastPetGroupIndex <= #sessionState.petGroups then
        sessionState.currentPetGroup = MountRouletteDB.lastPetGroupIndex
    else
        sessionState.currentPetGroup = 1
    end
end


-- Core Logic: Summon Mount
local function SummonRandomMount()
    if not sessionState.mountsInitialized then InitializeMounts() end
    
    -- Determine Environment
    local isSubmerged = IsSubmerged()
    local isFlyable = IsFlyableArea()
    
    -- Safety Limit: prevent infinite loops if no suitable mount exists in ANY group (unlikely but possible)
    local parsedGroups = 0
    local totalGroups = #sessionState.mountGroups
    
    -- We will try to find a suitable mount by cycling through groups until we find one that has candidates.
    while parsedGroups < totalGroups do
        local groupIndex = sessionState.currentMountGroup
        local group = sessionState.mountGroups[groupIndex]
        
        parsedGroups = parsedGroups + 1
        
        if group and #group > 0 then
            -- Filter candidates in this group based on environment
            local candidates = {}
            for _, mount in ipairs(group) do
                local valid = false
                
                -- Is it usable at all?
                local _, _, _, _, isUsable = C_MountJournal.GetMountInfoByID(mount.mountID)
                
                if isUsable then
                    if isSubmerged then
                        -- Underwater: Prefer Aquatic, but standard swimming mounts work too
                        if IsAquaticMount(mount.mountTypeID) then valid = true end
                        -- Fallback for underwater? Usually people want aquatic speed.
                        -- If we only select aquatic, and user has none in this group, we skip. Correct.
                    elseif isFlyable then
                        -- Flying Area: Prefer Flying
                        if IsFlyingMount(mount.mountTypeID) then valid = true end
                    else
                        -- Ground Area: Prefer Ground (Non-Flying, Non-Aquatic usually, but Flying mounts work on ground too)
                        -- User request: "if flying is not allowed, it should only summon ground mounts"
                        -- Often Flying mounts look awkward on ground or user specifically wants ground mounts.
                        -- However, many "Flying" mounts are perfectly fine ground mounts.
                        -- STRICT interpretation: Filter OUT flying mounts?
                        -- "it should only summon ground mounts" -> likely implies excluding large drakes etc.
                        -- Let's exclude Explicit Flying Types for Ground logic relative to the request.
                        if not IsFlyingMount(mount.mountTypeID) and not IsAquaticMount(mount.mountTypeID) then
                             valid = true 
                        end
                        -- Note: IsFlyingMount(typeID) is checking the TYPE, not capability. 
                        -- Many users prefer this separation.
                    end
                end
                
                if valid then
                    table.insert(candidates, mount)
                end
            end
            
            -- If we found candidates in this group, summon one!
            if #candidates > 0 then
                local randomIndex = math.random(1, #candidates)
                local mount = candidates[randomIndex]
                
                C_MountJournal.SummonByID(mount.mountID)
                
                local color = GetRarityColor(mount.rarity)
                local groupInfo = "Group " .. groupIndex .. " (Rarity: " .. string.format("%.2f", mount.rarity) .. "%)"
                PrintMessage("Summoning " .. color .. mount.name .. "|r from " .. groupInfo)
                
                -- Always cycle group after a successful summon (or attempt)
                sessionState.currentMountGroup = (sessionState.currentMountGroup % totalGroups) + 1
                MountRouletteDB.lastMountGroupIndex = sessionState.currentMountGroup
                return 
            end
        end
        
        -- If no candidates found in this group, move to the next group and continue search
        sessionState.currentMountGroup = (sessionState.currentMountGroup % totalGroups) + 1
    end
    
    -- Fallback: If we cycled through ALL groups and found nothing matching the strict criteria 
    -- (e.g. underwater but owns no aquatic mounts), try again with ANY usable mount.
    
    parsedGroups = 0
    while parsedGroups < totalGroups do
        local groupIndex = sessionState.currentMountGroup
        local group = sessionState.mountGroups[groupIndex]
        parsedGroups = parsedGroups + 1
        
         if group and #group > 0 then
             local candidates = {}
             for _, mount in ipairs(group) do
                 local _, _, _, _, isUsable = C_MountJournal.GetMountInfoByID(mount.mountID)
                 if isUsable then table.insert(candidates, mount) end
             end
             
             if #candidates > 0 then
                local randomIndex = math.random(1, #candidates)
                local mount = candidates[randomIndex]
                C_MountJournal.SummonByID(mount.mountID)
                local color = GetRarityColor(mount.rarity)
                PrintMessage("Summoning (Fallback) " .. color .. mount.name .. "|r from Group " .. groupIndex)
                
                sessionState.currentMountGroup = (sessionState.currentMountGroup % totalGroups) + 1
                MountRouletteDB.lastMountGroupIndex = sessionState.currentMountGroup
                return
             end
         end
         sessionState.currentMountGroup = (sessionState.currentMountGroup % totalGroups) + 1
    end
    
    PrintError("No usable mounts found in collection.")
end

-- Core Logic: Summon Pet
local function SummonRandomPet()
    if not sessionState.petsInitialized then InitializePets() end
    
    local groupIndex = sessionState.currentPetGroup
    local group = sessionState.petGroups[groupIndex]
    
    if not group then return end
    
    local randomIndex = math.random(1, #group)
    local pet = group[randomIndex]
    
    C_PetJournal.SummonPetByGUID(pet.petID)
    
    local color = GetRarityColor(pet.rarity)
    local groupInfo = "Group " .. groupIndex .. " (Rarity: " .. string.format("%.2f", pet.rarity) .. "%)"
    PrintMessage("Summoning " .. color .. pet.name .. "|r from " .. groupInfo)
    
     sessionState.currentPetGroup = sessionState.currentPetGroup + 1
     if sessionState.currentPetGroup > #sessionState.petGroups then
         sessionState.currentPetGroup = 1
     end
     MountRouletteDB.lastPetGroupIndex = sessionState.currentPetGroup
end


-- Event Registration
local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(1, function()
             InitializeMounts()
             InitializePets()
             PrintMessage("Database Refreshed. Dynamic Groups Ready.")
        end)
    elseif event == "NEW_MOUNT_ADDED" then
        local mountID = ...
        InitializeMounts() -- Re-init to sort new mount
        -- Optional: Print message? 
        -- PrintMessage("New mount detect! Re-sorting groups.")
    elseif event == "NEW_PET_ADDED" then
        local petID = ...
        InitializePets()
    end
end)
frame:RegisterEvent("NEW_MOUNT_ADDED")
frame:RegisterEvent("NEW_PET_ADDED")
frame:RegisterEvent("PLAYER_LOGIN")

-- Slash Commands
SLASH_PMSRMOUNT1 = "/pmsrmount"
SlashCmdList["PMSRMOUNT"] = function()
    SummonRandomMount()
end

SLASH_PMSRPET1 = "/pmsrpet"
SlashCmdList["PMSRPET"] = function()
    SummonRandomPet()
end

SLASH_PMSRPETDISMISS1 = "/pmsrpetdismiss"
SlashCmdList["PMSRPETDISMISS"] = function()
    C_PetBattles.ForceEnd() 
end

SLASH_PMSRDEBUG1 = "/pmsrdebug"
SlashCmdList["PMSRDEBUG"] = function()
    PrintMessage("Debug Info (Hybrid Grouping):")
    PrintMessage("Mount Groups: " .. #sessionState.mountGroups)
    
    -- Show info about groups
    for i, group in ipairs(sessionState.mountGroups) do
        local first = group[1]
        local last = group[#group]
        local r1 = first and first.rarity or 0
        local r2 = last and last.rarity or 0
        -- Shorten output
        if i <= 3 or i >= #sessionState.mountGroups - 2 then
             PrintMessage(string.format(" G%d: %d items (%.1f%% - %.1f%%)", i, #group, r1, r2))
        end
    end
    
    PrintMessage("Current Mount Group Index: " .. sessionState.currentMountGroup)
    PrintMessage("Environment: Flight=" .. tostring(IsFlyableArea()) .. ", Submerged=" .. tostring(IsSubmerged()))
end

SLASH_PMSRREFRESH1 = "/pmsrrefresh"
SlashCmdList["PMSRREFRESH"] = function()
    InitializeMounts()
    InitializePets()
    PrintMessage("Refreshed.")
end