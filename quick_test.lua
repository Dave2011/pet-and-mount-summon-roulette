-- Quick test to verify the addon is working properly
print("=== Quick Addon Test ===")

-- Test 1: Check if basic functions exist
local basicFunctions = {
    "CreateOptionsPanel",
    "InitializeConfig", 
    "LoadPreset",
    "ValidateRarityGroups"
}

print("Checking basic functions...")
for _, funcName in ipairs(basicFunctions) do
    if _G[funcName] then
        print("✓ " .. funcName .. " exists")
    else
        print("✗ " .. funcName .. " missing")
    end
end

-- Test 2: Check if slash commands are registered
print("\nChecking slash commands...")
if SlashCmdList then
    local commands = {"PMSROPTIONS", "PMSRMOUNT", "PMSRPET", "PMSRVALIDATE"}
    for _, cmd in ipairs(commands) do
        if SlashCmdList[cmd] then
            print("✓ /" .. cmd:lower() .. " registered")
        else
            print("✗ /" .. cmd:lower() .. " not found")
        end
    end
else
    print("✗ SlashCmdList not available")
end

-- Test 3: Check configuration
print("\nChecking configuration...")
if MountRouletteDB and MountRouletteDB.config then
    print("✓ Configuration exists")
    print("  - Rarity groups: " .. #MountRouletteDB.config.rarityGroups)
    print("  - Mounts enabled: " .. tostring(MountRouletteDB.config.enableMounts))
    print("  - Pets enabled: " .. tostring(MountRouletteDB.config.enablePets))
else
    print("✗ Configuration not initialized")
end

print("\n=== Test Complete ===")
print("Try '/pmsroptions' to open the options panel!")
print("Try '/pmsrmount' to summon a mount!")
print("Try '/pmsrpet' to summon a pet!")