local Utils = require("utils")
local Logger = require("logger")

local Ui = {}

-- Parses the list of clothes from the user, converts the multiline string into a list of TweakDB paths
local function textToListOfClothes (clothes)
    clothes = Utils.split(clothes, "\r\n")
    local ret = {}
    for _, cloth in ipairs(clothes) do
        local tweakDBID = cloth:match("Items%.([_%w]+)") or cloth:match("[_%w]+")
        if tweakDBID then
            table.insert(ret, "Items."..tweakDBID)
        end
    end
    return ret
end

function Ui:init (wardrobeItemsAdder)
    self.isVisible = false
    self.clothesText = ""

    self.wardrobeItemsAdder = wardrobeItemsAdder

    self.winWidth = 355
    self.winHeight = ImGui.GetTextLineHeight() * 29
    self.winContentWidth = self.winWidth - 16
    self.buffSize = 4 * 2^20
    return self
end

function Ui:onOverlayOpen ()
    self.isVisible = true
end

function Ui:onOverlayClose ()
    self.isVisible = false
end

function Ui:drawSeparatorWithSpacing()
    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()
end

function Ui:onDraw ()
    if not self.isVisible then
        return
    end

    ImGui.SetNextWindowSize(self.winWidth, self.winHeight)
    if ImGui.Begin("Wardrobe Items Adder", ImGuiWindowFlags.NoResize) then
        if ImGui.BeginTabBar("##tabBar") then
            if ImGui.BeginTabItem("Adder") then
                Ui:drawMainTab()
                ImGui.EndTabItem()
            end
            if ImGui.BeginTabItem("Settings") then
                Ui:drawSettings()
                ImGui.EndTabItem()
            end
            if self.wardrobeItemsAdder.config.showAdvancedSettings then
                if ImGui.BeginTabItem("Blacklist") then
                    Ui:drawBlacklist()
                    ImGui.EndTabItem()
                end
            end
            ImGui.EndTabBar();
        end
    end
    ImGui.End()
end

function Ui:drawMainTab ()
    ImGui.TextColored(1, 0, 0, 1, "Warning: items cannot be removed from wardrobe.")
    if ImGui.Button("Add All Clothes", self.winContentWidth, ImGui.GetTextLineHeight() * 3) then
        self.wardrobeItemsAdder:addAllClothesToWardrobe()
        Logger:info("Added all clothes to wardrobe.")
    end

    Ui:drawSeparatorWithSpacing()

    Ui:drawSectionDescription("Add Specific Clothes", [[
Each line should contain at most one item ID,
with or without the "Items." prefix.
For convenience, Game.AddToInventory(...)
commands can be copy-pasted as-is.]])

    self.clothesText =
        ImGui.InputTextMultiline(
            "##specificClothesInput",
            self.clothesText,
            self.buffSize,
            self.winContentWidth,
            ImGui.GetTextLineHeight() * 10)
    ImGui.Spacing()
    if ImGui.Button("Add Listed Items", self.winContentWidth, ImGui.GetTextLineHeight() * 2) then
        self.wardrobeItemsAdder:addClothesToWardrobe(textToListOfClothes(self.clothesText))
    end
end

function Ui:drawConfigCheckbox (label, config, configKey, tooltip)
    local changed = false
    config[configKey], changed = ImGui.Checkbox(label, config[configKey])
    if changed then
        self.wardrobeItemsAdder:saveConfig()
    end
    if tooltip and ImGui.IsItemHovered() then
        ImGui.SetTooltip(tooltip)
    end
end

function Ui:drawSectionDescription (title, description)
    ImGui.Text(title)
    ImGui.TextColored(0.5, 0.5, 0.5, 1.0, description)
    ImGui.Spacing()
end

function Ui:drawSettings ()
    local config = self.wardrobeItemsAdder.config

    ImGui.TextColored(1, 0, 0, 1, "Warning: items cannot be removed from wardrobe.")

    Ui:drawConfigCheckbox("Add All Clothes On Spawn", config, "addAllClothesOnPlayerSpawn",
        "Automatically add all clothes to the wardrobe after the player spawns.")

    Ui:drawConfigCheckbox("Show Advanced Settings", config, "showAdvancedSettings")
    if config.showAdvancedSettings then
        Ui:drawSeparatorWithSpacing()
        Ui:drawAdvancedSettings()
    end
end

function Ui:drawAdvancedSettings ()
    Ui:drawLogLevelCombo()
    Ui:drawSeparatorWithSpacing()
    Ui:drawFiltersCheckboxes()
    Ui:drawSeparatorWithSpacing()
    Ui:drawHideWindowButton()
end

function Ui:drawLogLevelCombo ()
    local items = {"All", "Default", "Only Errors And Warnings", "Only Errors", "Off"}
    local currentIndex = Logger.logLevel
    local preview = items[currentIndex]
    if ImGui.BeginCombo("Log Level", preview) then
        for index, _ in ipairs(items) do
            local isSelected = (currentIndex == index)
            if ImGui.Selectable(items[index], isSelected) then
                currentIndex = index
                Logger.logLevel = currentIndex
                self.wardrobeItemsAdder.config.logLevel = currentIndex
                self.wardrobeItemsAdder:saveConfig()
            end
            if isSelected then
                ImGui.SetItemDefaultFocus()
            end
        end
        ImGui.EndCombo()
    end
end

function Ui:drawFiltersCheckboxes ()
    Ui:drawSectionDescription("Item Filters", [[
The mod by default filters out items which
appear to be broken or not intended to be
in wardrobe. You can enable or disable
filters below. However, the game's wardrobe
system can still refuse to add an item.]])

    local filters = self.wardrobeItemsAdder.config.isFilterEnabled
    Ui:drawConfigCheckbox("Has \"Clothing\" Category", filters,
        "mustHaveClothingCategory", "The item must have \"Clothing\" category.")
    Ui:drawConfigCheckbox("Has Display Name", filters,
        "mustHaveDisplayName", "The item must have valid \"displayName\" field.")
    Ui:drawConfigCheckbox("Has Appearance Name", filters,
        "mustHaveAppearanceName", "The item must have valid \"appearanceName\" field.")
    Ui:drawConfigCheckbox("Is Not Crafting Spec", filters,
        "mustHaveAppearanceName", "The item must not have \"CraftingData\" field.")
    Ui:drawConfigCheckbox("Is Not Blacklisted", filters,
        "mustNotBeOnBlacklist", "The item must not be blacklisted in the mod's configuration.")
    Ui:drawConfigCheckbox("Is Not Blacklisted By Game", filters,
        "mustNotBeOnBlacklist", [[
The item must not be on the wardrobe blacklist.
The blacklist can be found in the TweakDB Editor under record
gamedataItemList_Record.Items.WardrobeBlacklist.items
]])
end

function Ui:drawHideWindowButton ()
    Ui:drawSectionDescription("Hide UI", [[
To show this window again, you can either
edit the config.lua file by hand inside
the mod's directory and reload mods/restart
the game, or use the following command
in the console.]])

    local showUiCommand = "GetMod(\"wardrobe_items_adder\"):showUi()"
    ImGui.PushItemWidth(self.winContentWidth - 55)
    ImGui.InputText("##showUiCommand", "GetMod(\"wardrobe_items_adder\"):showUi()",
        #showUiCommand + 1,
        ImGuiInputTextFlags.ReadOnly + ImGuiInputTextFlags.AutoSelectAll)
    ImGui.PopItemWidth()
    ImGui.SameLine()
    if ImGui.Button("Copy") then
        ImGui.SetClipboardText(showUiCommand)
    end

    local pressed = ImGui.Button("Hide This Window", self.winContentWidth, ImGui.GetTextLineHeightWithSpacing() + 2)
    if pressed then
        self.wardrobeItemsAdder.config.showUi = false
        self.wardrobeItemsAdder:saveConfig()
        return
    end
end

function Ui:drawBlacklist ()
    Ui:drawSectionDescription("Item Blacklist", [[
Theese items will not be added.]])
end

return Ui
