local Mount = PetMountSummonRoulette.Mount

local MountController = {}
MountController.__index = MountController

function MountController:new()
    local obj = {
        mounts = {},
    }
    setmetatable(obj, MountController)
    return obj
end

function MountController:addMount(mount)
    self.mounts[mount.id] = mount
end

function MountController:removeMountByID(id)
    self.mounts[id] = nil
end

function MountController:getMountByID(id)
    return self.mounts[id]
end

function MountController:getAllMounts()
    return self.mounts
end

function MountController:markSummoned(id)
    local mount = self:getMountByID(id)
    if mount then
        mount.summoned = true
    end
end

function MountController:buildFromJournal(existingMounts)
    C_MountJournal.SetDefaultFilters()
    for i = 1, C_MountJournal.GetNumDisplayedMounts() do
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = C_MountJournal.GetDisplayedMountInfo(i)

        local isFlying, isGround, isAquatic = false, false, false

        if mountID and isCollected then
            local summoned = existingMounts[mountID] and existingMounts[mountID].summoned or false
            local rarity = 0
            for rarityLevel, mountList in pairs(PetMountSummonRouletteData.mounts) do
                for _, id in ipairs(mountList) do
                    if id == mountID then
                        rarity = rarityLevel
                        break
                    end
                end
                if rarity > 0 then break end
            end
            local creatureDisplayInfoID, description, source, isSelfMount, mountTypeID, uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = C_MountJournal.GetMountInfoExtraByID(mountID)

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

            self:addMount(Mount:new(mountID, name, isFlying, isGround, isAquatic, summoned, rarity))
        end
    end

    for id in pairs(existingMounts) do
        if not self:getMountByID(id) then
            existingMounts[id] = nil
        end
    end
end

function MountController:saveToPersistentStorage()
    MountRouletteDB.mounts = {}
    for id, mount in pairs(self:getAllMounts()) do
        MountRouletteDB.mounts[id] = {
            name = mount.name,
            isFlying = mount.isFlying,
            isGround = mount.isGround,
            isAquatic = mount.isAquatic,
            summoned = mount.summoned,
            rarity = mount.rarity
        }
    end
end

function MountController:resetRarityGroup(rarityGroup)
    local resetCount = 0
    for _, mount in pairs(self.mounts) do
        if mount.rarity == rarityGroup then
            mount.summoned = false
            resetCount = resetCount + 1
        end
    end
    if resetCount > 0 then
        self:saveToPersistentStorage()
    end
end

function MountController:getRandomUnsummonedMountByRarity(rarityGroup, mountRidingCriteria)
    local candidates = {}
    for _, mount in pairs(self.mounts) do
        if mount.rarity == rarityGroup and not mount.summoned then
            if (mountRidingCriteria == "aquatic" and mount.isAquatic) or
               (mountRidingCriteria == "ground" and mount.isGround) or
               (mountRidingCriteria == "flying" and mount.isFlying) then
                table.insert(candidates, mount)
            end
        end
    end

    if #candidates > 0 then
        return candidates[math.random(1, #candidates)]
    end

    -- No unsummoned mounts found; reset and retry
    self:resetRarityGroup(rarityGroup)
    return self:getRandomUnsummonedMountByRarity(rarityGroup, mountRidingCriteria)
end

function MountController:getAllRarityGroups()
    local rarityGroups = {}
    for _, mount in pairs(self.mounts) do
        rarityGroups[mount.rarity] = true
    end
    local result = {}
    for rarity in pairs(rarityGroups) do
        table.insert(result, rarity)
    end
    table.sort(result)
    return result
end

PetMountSummonRoulette.MountController =  MountController