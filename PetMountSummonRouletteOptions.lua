-- PetMountSummonRouletteOptions.lua
-- Options panel for Pet & Mount Summon Roulette addon

local addonName = "PetMountSummonRoulette"
local L = {} -- Localization table (can be expanded later)

-- Preset configurations
local presetConfigs = {
    default = {
        name = "Default",
        rarityGroups = {
            {
                name = "Ultra Rare",
                minPercent = 0,
                maxPercent = 3,
                enabled = true,
                color = { 1, 0, 0 }
            },
            {
                name = "Very Rare",
                minPercent = 3,
                maxPercent = 7,
                enabled = true,
                color = { 1, 0.5, 0 }
            },
            {
                name = "Rare",
                minPercent = 7,
                maxPercent = 15,
                enabled = true,
                color = { 1, 1, 0 }
            },
            {
                name = "Uncommon",
                minPercent = 15,
                maxPercent = 30,
                enabled = true,
                color = { 0, 1, 0 }
            },
            {
                name = "Common",
                minPercent = 30,
                maxPercent = 100,
                enabled = true,
                color = { 0.5, 0.5, 0.5 }
            }
        }
    },
    conservative = {
        name = "Conservative",
        rarityGroups = {
            {
                name = "Legendary",
                minPercent = 0,
                maxPercent = 1,
                enabled = true,
                color = { 1, 0, 1 }
            },
            {
                name = "Ultra Rare",
                minPercent = 1,
                maxPercent = 5,
                enabled = true,
                color = { 1, 0, 0 }
            },
            {
                name = "Rare",
                minPercent = 5,
                maxPercent = 20,
                enabled = true,
                color = { 1, 0.5, 0 }
            },
            {
                name = "Everything Else",
                minPercent = 20,
                maxPercent = 100,
                enabled = true,
                color = { 0.5, 0.5, 0.5 }
            }
        }
    },
    balanced = {
        name = "Balanced",
        rarityGroups = {
            {
                name = "Ultra Rare",
                minPercent = 0,
                maxPercent = 5,
                enabled = true,
                color = { 1, 0, 0 }
            },
            {
                name = "Rare",
                minPercent = 5,
                maxPercent = 15,
                enabled = true,
                color = { 1, 1, 0 }
            },
            {
                name = "Uncommon",
                minPercent = 15,
                maxPercent = 40,
                enabled = true,
                color = { 0, 1, 0 }
            },
            {
                name = "Common",
                minPercent = 40,
                maxPercent = 100,
                enabled = true,
                color = { 0.5, 0.5, 0.5 }
            }
        }
    },
    aggressive = {
        name = "Aggressive",
        rarityGroups = {
            {
                name = "Top 10%",
                minPercent = 0,
                maxPercent = 10,
                enabled = true,
                color = { 1, 0, 0 }
            },
            {
                name = "Next 20%",
                minPercent = 10,
                maxPercent = 30,
                enabled = true,
                color = { 1, 1, 0 }
            },
            {
                name = "Rest",
                minPercent = 30,
                maxPercent = 100,
                enabled = true,
                color = { 0, 1, 0 }
            }
        }
    }
}

-- Default configuration
local defaultConfig = {
    rarityGroups = presetConfigs.default.rarityGroups,
    cycleOrder = "sequential", -- "sequential" or "random"
    enableMounts = true,
    enablePets = true
}

-- Initialize saved variables
local function InitializeConfig()
    if not MountRouletteDB.config then
        MountRouletteDB.config = {}
    end

    -- Merge with defaults for any missing values
    for key, value in pairs(defaultConfig) do
        if MountRouletteDB.config[key] == nil then
            if type(value) == "table" then
                MountRouletteDB.config[key] = {}
                for k, v in pairs(value) do
                    MountRouletteDB.config[key][k] = v
                end
            else
                MountRouletteDB.config[key] = value
            end
        end
    end
end

-- Create the main options panel
local function CreateOptionsPanel()
    local panel = CreateFrame("Frame", addonName .. "OptionsPanel", UIParent, "BasicFrameTemplateWithInset")
    panel.name = "Pet & Mount Roulette"
    panel:SetSize(600, 500)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:Hide() -- Start hidden

    -- Title
    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    panel.title:SetPoint("LEFT", panel.TitleBg, "LEFT", 5, 0)
    panel.title:SetText("Pet & Mount Summon Roulette Options")

    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Pet & Mount Summon Roulette Options")

    -- Subtitle
    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Configure custom rarity groups for your pets and mounts")

    -- Enable/Disable sections
    local enableMountsCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    enableMountsCheck:SetSize(24, 24)
    enableMountsCheck:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -20)
    enableMountsCheck.Text:SetText("Enable Mount Summoning")
    enableMountsCheck:SetChecked(MountRouletteDB.config.enableMounts)
    enableMountsCheck:SetScript("OnClick", function(self)
        MountRouletteDB.config.enableMounts = self:GetChecked()
    end)

    local enablePetsCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    enablePetsCheck:SetSize(24, 24)
    enablePetsCheck:SetPoint("TOPLEFT", enableMountsCheck, "BOTTOMLEFT", 0, -8)
    enablePetsCheck.Text:SetText("Enable Pet Summoning")
    enablePetsCheck:SetChecked(MountRouletteDB.config.enablePets)
    enablePetsCheck:SetScript("OnClick", function(self)
        MountRouletteDB.config.enablePets = self:GetChecked()
    end)

    -- Cycle order dropdown
    local cycleLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    cycleLabel:SetPoint("TOPLEFT", enablePetsCheck, "BOTTOMLEFT", 0, -20)
    cycleLabel:SetText("Group Cycling Order:")

    local cycleDropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
    cycleDropdown:SetPoint("TOPLEFT", cycleLabel, "BOTTOMLEFT", -15, -5)
    UIDropDownMenu_SetWidth(cycleDropdown, 150)
    UIDropDownMenu_SetText(cycleDropdown, MountRouletteDB.config.cycleOrder == "sequential" and "Sequential" or "Random")

    local function CycleDropdown_Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()

        info.text = "Sequential"
        info.value = "sequential"
        info.func = function()
            MountRouletteDB.config.cycleOrder = "sequential"
            UIDropDownMenu_SetText(cycleDropdown, "Sequential")
        end
        info.checked = (MountRouletteDB.config.cycleOrder == "sequential")
        UIDropDownMenu_AddButton(info)

        info.text = "Random"
        info.value = "random"
        info.func = function()
            MountRouletteDB.config.cycleOrder = "random"
            UIDropDownMenu_SetText(cycleDropdown, "Random")
        end
        info.checked = (MountRouletteDB.config.cycleOrder == "random")
        UIDropDownMenu_AddButton(info)
    end

    UIDropDownMenu_Initialize(cycleDropdown, CycleDropdown_Initialize)

    -- Rarity Groups section
    local groupsLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    groupsLabel:SetPoint("TOPLEFT", cycleDropdown, "BOTTOMLEFT", 15, -30)
    groupsLabel:SetText("Rarity Groups")

    local groupsSubtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    groupsSubtitle:SetPoint("TOPLEFT", groupsLabel, "BOTTOMLEFT", 0, -5)
    groupsSubtitle:SetText("Define custom rarity ranges for grouping your collection")

    -- Scroll frame for groups
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", groupsSubtitle, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetSize(500, 200)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(480, 1)
    scrollFrame:SetScrollChild(scrollChild)

    -- Store references for updates
    panel.scrollChild = scrollChild
    panel.enableMountsCheck = enableMountsCheck
    panel.enablePetsCheck = enablePetsCheck
    panel.cycleDropdown = cycleDropdown

    -- Add/Remove buttons
    local addButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    addButton:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -10)
    addButton:SetSize(100, 22)
    addButton:SetText("Add Group")
    addButton:SetScript("OnClick", function()
        AddNewGroup()
        RefreshGroupsList(panel)
    end)

    local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetButton:SetPoint("LEFT", addButton, "RIGHT", 10, 0)
    resetButton:SetSize(100, 22)
    resetButton:SetText("Reset to Default")
    resetButton:SetScript("OnClick", function()
        ResetToDefaults()
        RefreshOptionsPanel(panel)
    end)

    -- Preset templates dropdown
    local presetLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    presetLabel:SetPoint("LEFT", resetButton, "RIGHT", 20, 0)
    presetLabel:SetText("Load Preset:")

    local presetDropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
    presetDropdown:SetPoint("LEFT", presetLabel, "RIGHT", -15, 0)
    UIDropDownMenu_SetWidth(presetDropdown, 120)
    UIDropDownMenu_SetText(presetDropdown, "Choose...")

    local function PresetDropdown_Initialize(self, level)
        for presetKey, presetData in pairs(presetConfigs) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = presetData.name
            info.value = presetKey
            info.func = function()
                LoadPreset(presetKey)
                RefreshOptionsPanel(panel)
                UIDropDownMenu_SetText(presetDropdown, "Choose...")
            end
            UIDropDownMenu_AddButton(info)
        end
    end

    UIDropDownMenu_Initialize(presetDropdown, PresetDropdown_Initialize)

    -- Import/Export buttons
    local importButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    importButton:SetPoint("TOPLEFT", addButton, "BOTTOMLEFT", 0, -10)
    importButton:SetSize(100, 22)
    importButton:SetText("Import Config")
    importButton:SetScript("OnClick", function()
        ShowImportDialog(panel)
    end)

    local exportButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    exportButton:SetPoint("LEFT", importButton, "RIGHT", 10, 0)
    exportButton:SetSize(100, 22)
    exportButton:SetText("Export Config")
    exportButton:SetScript("OnClick", function()
        ShowExportDialog()
    end)

    -- Statistics display
    local statsButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    statsButton:SetPoint("LEFT", exportButton, "RIGHT", 10, 0)
    statsButton:SetSize(100, 22)
    statsButton:SetText("Show Stats")
    statsButton:SetScript("OnClick", function()
        ShowStatisticsDialog()
    end)

    return panel
end

-- Add a new rarity group
function AddNewGroup()
    local newGroup = {
        name = "New Group",
        minPercent = 0,
        maxPercent = 10,
        enabled = true,
        color = { 0.5, 0.5, 1 }
    }
    table.insert(MountRouletteDB.config.rarityGroups, newGroup)
end

-- Reset to default configuration
function ResetToDefaults()
    MountRouletteDB.config = {}
    InitializeConfig()
end

-- Refresh the groups list display
function RefreshGroupsList(panel)
    -- Clear existing group frames
    if panel.groupFrames then
        for _, frame in pairs(panel.groupFrames) do
            frame:Hide()
            frame:SetParent(nil)
        end
    end
    panel.groupFrames = {}

    local yOffset = 0
    for i, group in ipairs(MountRouletteDB.config.rarityGroups) do
        local groupFrame = CreateGroupFrame(panel.scrollChild, group, i)
        groupFrame:SetPoint("TOPLEFT", panel.scrollChild, "TOPLEFT", 0, -yOffset)
        table.insert(panel.groupFrames, groupFrame)
        yOffset = yOffset + 35
    end

    -- Update scroll child height
    panel.scrollChild:SetHeight(math.max(yOffset, 200))
end

-- Create individual group configuration frame
function CreateGroupFrame(parent, group, index)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(460, 30)

    -- Background
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)

    -- Enable checkbox
    local enableCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    enableCheck:SetSize(20, 20)
    enableCheck:SetPoint("LEFT", frame, "LEFT", 5, 0)
    enableCheck:SetChecked(group.enabled)
    enableCheck:SetScript("OnClick", function(self)
        group.enabled = self:GetChecked()
    end)

    -- Group name
    local nameEdit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    nameEdit:SetPoint("LEFT", enableCheck, "RIGHT", 5, 0)
    nameEdit:SetSize(120, 20)
    nameEdit:SetText(group.name)
    nameEdit:SetScript("OnTextChanged", function(self)
        group.name = self:GetText()
    end)

    -- Min percent
    local minEdit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    minEdit:SetPoint("LEFT", nameEdit, "RIGHT", 10, 0)
    minEdit:SetSize(40, 20)
    minEdit:SetText(tostring(group.minPercent))
    minEdit:SetScript("OnTextChanged", function(self)
        local value = tonumber(self:GetText())
        if value then
            group.minPercent = value
        end
    end)

    -- Dash
    local dash = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    dash:SetPoint("LEFT", minEdit, "RIGHT", 5, 0)
    dash:SetText("-")

    -- Max percent
    local maxEdit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    maxEdit:SetPoint("LEFT", dash, "RIGHT", 5, 0)
    maxEdit:SetSize(40, 20)
    maxEdit:SetText(tostring(group.maxPercent))
    maxEdit:SetScript("OnTextChanged", function(self)
        local value = tonumber(self:GetText())
        if value then
            group.maxPercent = value
        end
    end)

    -- Percent label
    local percentLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    percentLabel:SetPoint("LEFT", maxEdit, "RIGHT", 5, 0)
    percentLabel:SetText("%")

    -- Delete button
    local deleteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    deleteButton:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
    deleteButton:SetSize(60, 20)
    deleteButton:SetText("Delete")
    deleteButton:SetScript("OnClick", function()
        table.remove(MountRouletteDB.config.rarityGroups, index)
        RefreshGroupsList(frame:GetParent():GetParent():GetParent()) -- Navigate back to main panel
    end)

    return frame
end

-- Refresh the entire options panel
function RefreshOptionsPanel(panel)
    panel.enableMountsCheck:SetChecked(MountRouletteDB.config.enableMounts)
    panel.enablePetsCheck:SetChecked(MountRouletteDB.config.enablePets)
    UIDropDownMenu_SetText(panel.cycleDropdown,
        MountRouletteDB.config.cycleOrder == "sequential" and "Sequential" or "Random")
    RefreshGroupsList(panel)
end

-- Event handler for addon initialization
local function OnAddonLoaded(self, event, loadedAddonName)
    if loadedAddonName == addonName then
        InitializeConfig()

        -- Create the standalone options panel
        local panel = CreateOptionsPanel()

        -- Set the global panel reference for direct access
        if SetOptionsPanel then
            SetOptionsPanel(panel)
        end

        -- Initial refresh
        RefreshGroupsList(panel)

        DEFAULT_CHAT_FRAME:AddMessage(
            "|cFF00FF00[PetAndMountSummonRoulette]|r Options panel ready! Use /pmsroptions to open")
    end
end

-- Register events
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnAddonLoaded)
-- Load a preset configuration
function LoadPreset(presetKey)
    if presetConfigs[presetKey] then
        MountRouletteDB.config.rarityGroups = {}
        for i, group in ipairs(presetConfigs[presetKey].rarityGroups) do
            MountRouletteDB.config.rarityGroups[i] = {
                name = group.name,
                minPercent = group.minPercent,
                maxPercent = group.maxPercent,
                enabled = group.enabled,
                color = { group.color[1], group.color[2], group.color[3] }
            }
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[PetAndMountSummonRoulette]|r Loaded " ..
            presetConfigs[presetKey].name .. " preset")
    end
end

-- Show import dialog
function ShowImportDialog(panel)
    local importFrame = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
    importFrame:SetSize(400, 300)
    importFrame:SetPoint("CENTER")
    importFrame:SetFrameStrata("DIALOG")
    importFrame.title = importFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    importFrame.title:SetPoint("LEFT", importFrame.TitleBg, "LEFT", 5, 0)
    importFrame.title:SetText("Import Configuration")

    local instructions = importFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    instructions:SetPoint("TOPLEFT", importFrame.InsetBg, "TOPLEFT", 10, -10)
    instructions:SetText("Paste your exported configuration below:")

    local scrollFrame = CreateFrame("ScrollFrame", nil, importFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetSize(360, 180)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetSize(360, 180)
    editBox:SetScript("OnEscapePressed", function() importFrame:Hide() end)
    scrollFrame:SetScrollChild(editBox)

    local importButton = CreateFrame("Button", nil, importFrame, "UIPanelButtonTemplate")
    importButton:SetPoint("BOTTOMLEFT", importFrame.InsetBg, "BOTTOMLEFT", 10, 10)
    importButton:SetSize(80, 22)
    importButton:SetText("Import")
    importButton:SetScript("OnClick", function()
        local configText = editBox:GetText()
        if configText and configText ~= "" then
            local success, importedConfig = pcall(loadstring("return " .. configText))
            if success and importedConfig and importedConfig.rarityGroups then
                MountRouletteDB.config.rarityGroups = importedConfig.rarityGroups
                if importedConfig.cycleOrder then
                    MountRouletteDB.config.cycleOrder = importedConfig.cycleOrder
                end
                if importedConfig.enableMounts ~= nil then
                    MountRouletteDB.config.enableMounts = importedConfig.enableMounts
                end
                if importedConfig.enablePets ~= nil then
                    MountRouletteDB.config.enablePets = importedConfig.enablePets
                end
                RefreshOptionsPanel(panel)
                DEFAULT_CHAT_FRAME:AddMessage(
                    "|cFF00FF00[PetAndMountSummonRoulette]|r Configuration imported successfully!")
                importFrame:Hide()
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[PetAndMountSummonRoulette]|r Invalid configuration format!")
            end
        end
    end)

    local cancelButton = CreateFrame("Button", nil, importFrame, "UIPanelButtonTemplate")
    cancelButton:SetPoint("LEFT", importButton, "RIGHT", 10, 0)
    cancelButton:SetSize(80, 22)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function() importFrame:Hide() end)

    importFrame:Show()
    editBox:SetFocus()
end

-- Show export dialog
function ShowExportDialog()
    local exportFrame = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
    exportFrame:SetSize(400, 300)
    exportFrame:SetPoint("CENTER")
    exportFrame:SetFrameStrata("DIALOG")
    exportFrame.title = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    exportFrame.title:SetPoint("LEFT", exportFrame.TitleBg, "LEFT", 5, 0)
    exportFrame.title:SetText("Export Configuration")

    local instructions = exportFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    instructions:SetPoint("TOPLEFT", exportFrame.InsetBg, "TOPLEFT", 10, -10)
    instructions:SetText("Copy the configuration below to share with others:")

    local scrollFrame = CreateFrame("ScrollFrame", nil, exportFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetSize(360, 180)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetSize(360, 180)
    editBox:SetScript("OnEscapePressed", function() exportFrame:Hide() end)
    scrollFrame:SetScrollChild(editBox)

    -- Generate export string
    local exportConfig = {
        rarityGroups = MountRouletteDB.config.rarityGroups,
        cycleOrder = MountRouletteDB.config.cycleOrder,
        enableMounts = MountRouletteDB.config.enableMounts,
        enablePets = MountRouletteDB.config.enablePets
    }

    local function serializeTable(t, indent)
        indent = indent or 0
        local spacing = string.rep("  ", indent)
        local result = "{\n"

        for k, v in pairs(t) do
            local key = type(k) == "string" and k or "[" .. k .. "]"
            result = result .. spacing .. "  " .. key .. " = "

            if type(v) == "table" then
                result = result .. serializeTable(v, indent + 1)
            elseif type(v) == "string" then
                result = result .. '"' .. v .. '"'
            else
                result = result .. tostring(v)
            end
            result = result .. ",\n"
        end

        result = result .. spacing .. "}"
        return result
    end

    editBox:SetText(serializeTable(exportConfig))
    editBox:HighlightText()

    local closeButton = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    closeButton:SetPoint("BOTTOM", exportFrame.InsetBg, "BOTTOM", 0, 10)
    closeButton:SetSize(80, 22)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function() exportFrame:Hide() end)

    exportFrame:Show()
    editBox:SetFocus()
end

-- Show statistics dialog
function ShowStatisticsDialog()
    local statsFrame = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
    statsFrame:SetSize(450, 400)
    statsFrame:SetPoint("CENTER")
    statsFrame:SetFrameStrata("DIALOG")
    statsFrame.title = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    statsFrame.title:SetPoint("LEFT", statsFrame.TitleBg, "LEFT", 5, 0)
    statsFrame.title:SetText("Collection Statistics")

    local scrollFrame = CreateFrame("ScrollFrame", nil, statsFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", statsFrame.InsetBg, "TOPLEFT", 10, -10)
    scrollFrame:SetSize(410, 320)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(390, 1)
    scrollFrame:SetScrollChild(scrollChild)

    -- Calculate statistics
    local stats = CalculateCollectionStats()

    local yOffset = 0
    local function AddStatLine(text, color)
        local line = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        line:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
        line:SetText(text)
        if color then
            line:SetTextColor(color[1], color[2], color[3])
        end
        yOffset = yOffset + 20
        return line
    end

    AddStatLine("=== MOUNT STATISTICS ===", { 1, 1, 0 })
    AddStatLine("Total Mounts: " .. stats.totalMounts)
    AddStatLine("")

    for i, group in ipairs(MountRouletteDB.config.rarityGroups) do
        if group.enabled then
            local count = stats.mountsByGroup[i] or 0
            local percentage = stats.totalMounts > 0 and (count / stats.totalMounts * 100) or 0
            AddStatLine(string.format("%s: %d mounts (%.1f%%)", group.name, count, percentage), group.color)
        end
    end

    AddStatLine("")
    AddStatLine("=== PET STATISTICS ===", { 1, 1, 0 })
    AddStatLine("Total Pets: " .. stats.totalPets)
    AddStatLine("")

    for i, group in ipairs(MountRouletteDB.config.rarityGroups) do
        if group.enabled then
            local count = stats.petsByGroup[i] or 0
            local percentage = stats.totalPets > 0 and (count / stats.totalPets * 100) or 0
            AddStatLine(string.format("%s: %d pets (%.1f%%)", group.name, count, percentage), group.color)
        end
    end

    AddStatLine("")
    AddStatLine("=== RARITY DISTRIBUTION ===", { 1, 1, 0 })
    for percent, count in pairs(stats.rarityDistribution) do
        AddStatLine(string.format("%d%% rarity: %d items", percent, count))
    end

    scrollChild:SetHeight(math.max(yOffset, 320))

    local closeButton = CreateFrame("Button", nil, statsFrame, "UIPanelButtonTemplate")
    closeButton:SetPoint("BOTTOM", statsFrame.InsetBg, "BOTTOM", 0, 10)
    closeButton:SetSize(80, 22)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function() statsFrame:Hide() end)

    statsFrame:Show()
end

-- Calculate collection statistics
function CalculateCollectionStats()
    local stats = {
        totalMounts = 0,
        totalPets = 0,
        mountsByGroup = {},
        petsByGroup = {},
        rarityDistribution = {}
    }

    -- Count mounts by group
    if MountRouletteDB.mounts and MountRouletteDB.mounts.unsummoned then
        for mountType, groups in pairs(MountRouletteDB.mounts.unsummoned) do
            for groupId, mounts in pairs(groups) do
                for mountId, mountData in pairs(mounts) do
                    stats.totalMounts = stats.totalMounts + 1
                    stats.mountsByGroup[groupId] = (stats.mountsByGroup[groupId] or 0) + 1
                end
            end
        end
    end

    -- Count pets by group
    if MountRouletteDB.pets and MountRouletteDB.pets.unsummoned then
        for groupId, pets in pairs(MountRouletteDB.pets.unsummoned) do
            for petId, petData in pairs(pets) do
                stats.totalPets = stats.totalPets + 1
                stats.petsByGroup[groupId] = (stats.petsByGroup[groupId] or 0) + 1
            end
        end
    end

    -- Calculate rarity distribution from original data
    if PetMountSummonRouletteData then
        if PetMountSummonRouletteData.mounts then
            for rarity, mountList in pairs(PetMountSummonRouletteData.mounts) do
                local rarityNum = tonumber(rarity)
                if rarityNum then
                    stats.rarityDistribution[rarityNum] = (stats.rarityDistribution[rarityNum] or 0) + #mountList
                end
            end
        end

        if PetMountSummonRouletteData.pets then
            for rarity, petList in pairs(PetMountSummonRouletteData.pets) do
                local rarityNum = tonumber(rarity)
                if rarityNum then
                    stats.rarityDistribution[rarityNum] = (stats.rarityDistribution[rarityNum] or 0) + #petList
                end
            end
        end
    end

    return stats
end

-- Validate rarity group configuration
function ValidateRarityGroups()
    local issues = {}
    local groups = MountRouletteDB.config.rarityGroups

    for i, group in ipairs(groups) do
        -- Check for valid ranges
        if group.minPercent >= group.maxPercent then
            table.insert(issues, string.format("Group '%s': Min percent (%d) must be less than max percent (%d)",
                group.name, group.minPercent, group.maxPercent))
        end

        -- Check for negative values
        if group.minPercent < 0 or group.maxPercent < 0 then
            table.insert(issues, string.format("Group '%s': Percentages cannot be negative", group.name))
        end

        -- Check for values over 100
        if group.minPercent > 100 or group.maxPercent > 100 then
            table.insert(issues, string.format("Group '%s': Percentages cannot exceed 100", group.name))
        end

        -- Check for overlaps with other groups
        for j, otherGroup in ipairs(groups) do
            if i ~= j and group.enabled and otherGroup.enabled then
                if (group.minPercent < otherGroup.maxPercent and group.maxPercent > otherGroup.minPercent) then
                    table.insert(issues, string.format("Groups '%s' and '%s' have overlapping ranges",
                        group.name, otherGroup.name))
                end
            end
        end

        -- Check for empty names
        if not group.name or group.name:trim() == "" then
            table.insert(issues, string.format("Group %d: Name cannot be empty", i))
        end
    end

    return issues
end

-- Show validation results
function ShowValidationDialog()
    local issues = ValidateRarityGroups()

    if #issues == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[PetAndMountSummonRoulette]|r Configuration is valid!")
        return
    end

    local validationFrame = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
    validationFrame:SetSize(450, 300)
    validationFrame:SetPoint("CENTER")
    validationFrame:SetFrameStrata("DIALOG")
    validationFrame.title = validationFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    validationFrame.title:SetPoint("LEFT", validationFrame.TitleBg, "LEFT", 5, 0)
    validationFrame.title:SetText("Configuration Issues")

    local scrollFrame = CreateFrame("ScrollFrame", nil, validationFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", validationFrame.InsetBg, "TOPLEFT", 10, -10)
    scrollFrame:SetSize(410, 220)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(390, 1)
    scrollFrame:SetScrollChild(scrollChild)

    local yOffset = 0
    for _, issue in ipairs(issues) do
        local line = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        line:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
        line:SetText("• " .. issue)
        line:SetTextColor(1, 0.5, 0.5) -- Light red
        line:SetWidth(390)
        line:SetJustifyH("LEFT")
        line:SetWordWrap(true)
        yOffset = yOffset + line:GetStringHeight() + 5
    end

    scrollChild:SetHeight(math.max(yOffset, 220))

    local closeButton = CreateFrame("Button", nil, validationFrame, "UIPanelButtonTemplate")
    closeButton:SetPoint("BOTTOM", validationFrame.InsetBg, "BOTTOM", 0, 10)
    closeButton:SetSize(80, 22)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function() validationFrame:Hide() end)

    validationFrame:Show()
end

-- Add validation button to the main panel (modify the existing CreateOptionsPanel function)
-- This would be added near the other buttons, but since we can't easily modify the existing function,
-- we'll add a slash command for validation instead

-- Add slash command for validation
SLASH_PMSRVALIDATE1 = "/pmsrvalidate"
SlashCmdList["PMSRVALIDATE"] = function()
    ShowValidationDialog()
end
