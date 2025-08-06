-- Test script to verify the options panel functionality
-- Run this in WoW console to test the options system

print("=== Testing Options Panel Functionality ===")

-- Test 1: Check if the panel creation works
print("Testing panel creation...")
if CreateOptionsPanel then
    print("✓ CreateOptionsPanel function exists")
    local testPanel = CreateOptionsPanel()
    if testPanel then
        print("✓ Panel created successfully")
        print("  - Panel name: " .. (testPanel.name or "unnamed"))
        print("  - Panel type: " .. testPanel:GetObjectType())
    else
        print("✗ Panel creation failed")
    end
else
    print("✗ CreateOptionsPanel function not found")
end

-- Test 2: Check configuration initialization
print("\nTesting configuration...")
if InitializeConfig then
    print("✓ InitializeConfig function exists")
    InitializeConfig()
    if MountRouletteDB and MountRouletteDB.config then
        print("✓ Configuration initialized")
        print("  - Enable mounts: " .. tostring(MountRouletteDB.config.enableMounts))
        print("  - Enable pets: " .. tostring(MountRouletteDB.config.enablePets))
        print("  - Cycle order: " .. (MountRouletteDB.config.cycleOrder or "not set"))
        print("  - Rarity groups: " .. #MountRouletteDB.config.rarityGroups)
    else
        print("✗ Configuration not properly initialized")
    end
else
    print("✗ InitializeConfig function not found")
end

-- Test 3: Check preset loading
print("\nTesting preset system...")
if LoadPreset then
    print("✓ LoadPreset function exists")
    if presetConfigs then
        print("✓ Preset configurations available:")
        for key, preset in pairs(presetConfigs) do
            print("  - " .. key .. ": " .. preset.name)
        end
        
        -- Test loading a preset
        print("Testing conservative preset load...")
        LoadPreset("conservative")
        if MountRouletteDB.config.rarityGroups[1].name == "Legendary" then
            print("✓ Conservative preset loaded successfully")
        else
            print("✗ Preset loading failed")
        end
    else
        print("✗ Preset configurations not found")
    end
else
    print("✗ LoadPreset function not found")
end

-- Test 4: Check validation system
print("\nTesting validation system...")
if ValidateRarityGroups then
    print("✓ ValidateRarityGroups function exists")
    local issues = ValidateRarityGroups()
    print("  - Validation issues found: " .. #issues)
    if #issues > 0 then
        for _, issue in ipairs(issues) do
            print("    • " .. issue)
        end
    else
        print("  ✓ Configuration is valid")
    end
else
    print("✗ ValidateRarityGroups function not found")
end

-- Test 5: Check statistics calculation
print("\nTesting statistics system...")
if CalculateCollectionStats then
    print("✓ CalculateCollectionStats function exists")
    local stats = CalculateCollectionStats()
    print("  - Total mounts: " .. stats.totalMounts)
    print("  - Total pets: " .. stats.totalPets)
    print("  - Rarity distribution entries: " .. (stats.rarityDistribution and #stats.rarityDistribution or 0))
else
    print("✗ CalculateCollectionStats function not found")
end

-- Test 6: Test slash command registration
print("\nTesting slash commands...")
if SlashCmdList then
    local commands = {"PMSROPTIONS", "PMSRVALIDATE"}
    for _, cmd in ipairs(commands) do
        if SlashCmdList[cmd] then
            print("✓ /" .. cmd:lower() .. " command registered")
        else
            print("✗ /" .. cmd:lower() .. " command not found")
        end
    end
else
    print("✗ SlashCmdList not available")
end

print("\n=== Options Panel Test Complete ===")
print("Try running '/pmsroptions' to open the options panel")
print("Try running '/pmsrvalidate' to validate your configuration")