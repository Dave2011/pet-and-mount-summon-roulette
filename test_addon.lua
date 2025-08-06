-- Comprehensive test script for Pet & Mount Summon Roulette
-- This would be run in WoW's console or as a separate test

print("=== Pet & Mount Summon Roulette Enhanced Test Suite ===")

-- Test 1: Check if core functions exist
local core_functions = {
    "getMountRarityGroup",
    "getPetRarityGroup", 
    "getConfiguredRarityGroup",
    "isFeatureEnabled"
}

print("Testing core function availability...")
for _, func_name in ipairs(core_functions) do
    if _G[func_name] then
        print("✓ " .. func_name .. " exists")
    else
        print("✗ " .. func_name .. " missing")
    end
end

-- Test 2: Check Phase 2 functions exist
local phase2_functions = {
    "LoadPreset",
    "ShowImportDialog",
    "ShowExportDialog", 
    "ShowStatisticsDialog",
    "ValidateRarityGroups",
    "CalculateCollectionStats"
}

print("\nTesting Phase 2 function availability...")
for _, func_name in ipairs(phase2_functions) do
    if _G[func_name] then
        print("✓ " .. func_name .. " exists")
    else
        print("✗ " .. func_name .. " missing")
    end
end

-- Test 3: Check default config structure
print("\nTesting default configuration...")
if MountRouletteDB and MountRouletteDB.config then
    print("✓ Config exists")
    if MountRouletteDB.config.rarityGroups then
        print("✓ Rarity groups: " .. #MountRouletteDB.config.rarityGroups)
        for i, group in ipairs(MountRouletteDB.config.rarityGroups) do
            print("  - " .. group.name .. " (" .. group.minPercent .. "-" .. group.maxPercent .. "%)")
        end
    end
    
    print("✓ Cycle order: " .. (MountRouletteDB.config.cycleOrder or "not set"))
    print("✓ Mounts enabled: " .. tostring(MountRouletteDB.config.enableMounts))
    print("✓ Pets enabled: " .. tostring(MountRouletteDB.config.enablePets))
else
    print("✗ Config not initialized")
end

-- Test 4: Check preset configurations
print("\nTesting preset configurations...")
if presetConfigs then
    print("✓ Presets available:")
    for key, preset in pairs(presetConfigs) do
        print("  - " .. key .. ": " .. preset.name .. " (" .. #preset.rarityGroups .. " groups)")
    end
else
    print("✗ Presets not loaded")
end

-- Test 5: Test validation system
print("\nTesting validation system...")
if ValidateRarityGroups then
    local issues = ValidateRarityGroups()
    if #issues == 0 then
        print("✓ Configuration validation passed")
    else
        print("⚠ Configuration has " .. #issues .. " issues:")
        for _, issue in ipairs(issues) do
            print("  - " .. issue)
        end
    end
else
    print("✗ Validation system not available")
end

-- Test 6: Check slash commands
print("\nTesting slash command registration...")
local commands = {
    "PMSRMOUNT",
    "PMSRPET", 
    "PMSRPETDISMISS",
    "PMSROPTIONS",
    "PMSRVALIDATE"
}

for _, cmd in ipairs(commands) do
    if SlashCmdList and SlashCmdList[cmd] then
        print("✓ /" .. cmd:lower() .. " registered")
    else
        print("✗ /" .. cmd:lower() .. " missing")
    end
end

print("\n=== Test Suite Complete ===")
print("Run '/pmsroptions' to access the options panel")
print("Run '/pmsrvalidate' to validate your configuration")