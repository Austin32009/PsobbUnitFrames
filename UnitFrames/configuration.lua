local lib_helpers = require("solylib.helpers")
local cfgMonsters = require("UnitFrames.monsters")

local function getMonstersBySegment()
    local mt = {}
    mt["General"] = {}
    table.insert(mt["General"], {id=-1, cate = "Default" } )
    for k,v in pairs(cfgMonsters.m) do
        if v.seg then
            v.id = k
            if mt[v.seg] == nil then
                mt[v.seg] = {}
            end
            table.insert(mt[v.seg],v)
        end
    end
    return mt
end
local monstersBySegment = getMonstersBySegment()
local monsterSegmentOrder = {
    "General",
    "Forest",
    "Cave",
    "Mine",
    "Ruins",
    "VR Temple",
    "VR Spaceship",
    "Central Control Area",
    "Seabed",
    "Crater",
    "Desert",
}


local function clampVal(clamp, min, max)
    return clamp < min and min or clamp > max and max or clamp
end
local function Norm(Val,Min,Max)
    return (Val - Min)/(Max - Min)
end
local function Lerp(Norm,Min,Max)
    return (Max - Min) * Norm + Min
end
local function shiftHexColor(color)
    return
    {
        bit.band(bit.rshift(color, 24), 0xFF),
        bit.band(bit.rshift(color, 16), 0xFF),
        bit.band(bit.rshift(color, 8), 0xFF),
        bit.band(color, 0xFF)
    }
end


local function ConfigurationWindow(configuration)
    local this =
    {
        title = "UnitFrames - Configuration",
        open = false,
        changed = false,
    }

    local _configuration = configuration


    local function PresentColorEditor(label, default, custom)
        custom = custom or 0xFFFFFFFF
    
        local changed = false
        local i_default =
        {
            bit.band(bit.rshift(default, 24), 0xFF),
            bit.band(bit.rshift(default, 16), 0xFF),
            bit.band(bit.rshift(default, 8), 0xFF),
            bit.band(default, 0xFF)
        }
        local i_custom =
        {
            bit.band(bit.rshift(custom, 24), 0xFF),
            bit.band(bit.rshift(custom, 16), 0xFF),
            bit.band(bit.rshift(custom, 8), 0xFF),
            bit.band(custom, 0xFF)
        }
    
        local ids = { "##X", "##Y", "##Z", "##W" }
        local fmt = { "A:%3.0f", "R:%3.0f", "G:%3.0f", "B:%3.0f" }
    
        imgui.BeginGroup()
        imgui.PushID(label)
    
        imgui.PushItemWidth(50)
        for n = 1, 4, 1 do
            local changedDragInt = false
            if n ~= 1 then
                imgui.SameLine(0, 5)
            end
    
            changedDragInt, i_custom[n] = imgui.DragInt(ids[n], i_custom[n], 1.0, 0, 255, fmt[n])
            if changedDragInt then
                this.changed = true
            end
        end
        imgui.PopItemWidth()
    
        imgui.SameLine(0, 5)
        imgui.ColorButton(i_custom[2] / 255, i_custom[3] / 255, i_custom[4] / 255, i_custom[1] / 255)
        if imgui.IsItemHovered() then
            imgui.SetTooltip(
                string.format(
                    "#%02X%02X%02X%02X",
                    i_custom[4],
                    i_custom[1],
                    i_custom[2],
                    i_custom[3]
                )
            )
        end
    
        imgui.SameLine(0, 5)
        imgui.Text(label)
    
        default =
        bit.lshift(i_default[1], 24) +
        bit.lshift(i_default[2], 16) +
        bit.lshift(i_default[3], 8) +
        bit.lshift(i_default[4], 0)
    
        custom =
        bit.lshift(i_custom[1], 24) +
        bit.lshift(i_custom[2], 16) +
        bit.lshift(i_custom[3], 8) +
        bit.lshift(i_custom[4], 0)
    
        if custom ~= default then
            imgui.SameLine(0, 5)
            if imgui.Button("Revert") then
                custom = default
                this.changed = true
            end
        end
    
        imgui.PopID()
        imgui.EndGroup()
    
        return custom
    end

    local configureMonster_persist = {}

    local _showWindowSettings = function()
        local success
        local serverList =
        {
            "Vanilla",
            "Ultima",
            "Ephinea",
            "Schthack",
        }

        local function configureMonster(monster, category, section, Additional)
            imgui.PushID(section..category.."cfg")
            local cateTabl        = _configuration[section][category]
            local defaultCateTabl = _configuration[section][-1]
            
            if configureMonster_persist[category] == nil then
                configureMonster_persist[category] = {}
            end
            local cm_persist = configureMonster_persist[category]


            if imgui.Checkbox("Enable", cateTabl.enabled) then
                cateTabl.enabled = not cateTabl.enabled
                this.changed = true
            end

            if category ~= -1 and imgui.Checkbox("Override General > Default", cateTabl.overridden) then
                cateTabl.overridden = not cateTabl.overridden
                this.overridden = true
            end

            local function showEnableRow(cateTabl, widgetName, buttonText, n)
                if imgui.Checkbox("##"..buttonText, cateTabl[widgetName].show) then
                    cateTabl[widgetName].show = not cateTabl[widgetName].show
                    this.changed = true
                end
                if imgui.IsItemActive() then
                    cm_persist.selected_widget = n
                end
                imgui.SameLine(0, 4)
                imgui.Selectable(buttonText)
            end
            local function showName_Option(cateTabl, n)
                showEnableRow(cateTabl, "name", "Show Name", n)
            end
            local function showStatusEffects_Option(cateTabl, n)
                showEnableRow(cateTabl, "se", "Show Status Effects", n)
            end
            local function showHealth_Option(cateTabl, n)
                showEnableRow(cateTabl, "hp", "Show Health", n)
            end
            local function showDamage_Option(cateTabl, n)
                showEnableRow(cateTabl, "damage", "Show Damage", n)
            end
            local function showHit_Option(cateTabl, n)
                showEnableRow(cateTabl, "hit", "Show Hit", n)
            end
            local function showRecommended_Option(cateTabl, n)
                showEnableRow(cateTabl, "recommended", "Show Recommended", n)
            end
            local function showRares_Option(cateTabl, n)
                showEnableRow(cateTabl, "rare", "Show Rare Drops", n)
            end
            local function showResistances_Option(cateTabl, n)
                showEnableRow(cateTabl, "resist", "Show Resistances", n)
            end
            local function showProbability_Option(cateTabl, n)
                showEnableRow(cateTabl, "probability", "Show Probability", n)
            end

            local function reorder_cateTabl_Options(items) -- user interaction reorders these options
                local active_item = nil
                local hovered_item = nil
                local active_item_val = nil
                for n=1, #items do
                    local item = items[n]
                    cateTabl_Shown_Reordering_Options[item](cateTabl,item)
                    if imgui.IsItemActive() then
                        active_item = n
                    end
                    if imgui.IsItemHoveredRect() then
                        hovered_item = n
                    end
                    if active_item_val == nil and active_item ~= nil and active_item == hovered_item then
                        cm_persist.selected_widget = item
                        active_item_val = item
                    end
                end
                
                for n=1, #items do
                    if active_item == n and hovered_item ~= nil and hovered_item ~= n then
                        if hovered_item > 0 and hovered_item <= #items then
                            while hovered_item ~= active_item do
                                local prev_item_val = items[active_item]
                                local prev_active_item = active_item
                                active_item = active_item + ((hovered_item - active_item) < 0.0 and -1 or 1)

                                items[prev_active_item] = items[active_item]
                                items[active_item] = prev_item_val
                            end
                            this.changed = true
                        end
                    end
                end
            end

            if not cateTabl_Shown_Reordering_Options then
                cateTabl_Shown_Reordering_Options = {
                    showName_Option,
                    showStatusEffects_Option,
                    showHealth_Option,
                    showDamage_Option,
                    showHit_Option,
                    showRecommended_Option,
                    showRares_Option,
                    showResistances_Option,
                    showProbability_Option,
                }
            end

            local function resetShowOptionOrder()
                cateTabl.shownOptionOrder = {}
                for i=1, #cateTabl_Shown_Reordering_Options do 
                    table.insert(cateTabl.shownOptionOrder, i)
                end
                this.changed = true
            end

            if not cateTabl.shownOptionOrder then
                resetShowOptionOrder()
            end

            if  (category == -1 and defaultCateTabl.enabled)
                or (category ~= -1 and cateTabl.overridden and cateTabl.enabled)
            then
                imgui.PushStyleColor("Border", 0.33, 0.33, 0.33, 1.0)
                
                local childWindowSizeX = imgui.CalcTextSize("Show Status Effects") + 42
                local childWindowSizeY = #cateTabl.shownOptionOrder * 24 +10
                imgui.BeginChild( "##" .. section..category.."reorder", childWindowSizeX, childWindowSizeY, true )
                reorder_cateTabl_Options(cateTabl.shownOptionOrder)
                imgui.EndChild()

                imgui.SameLine(0,1)
                imgui.BeginChild( "##" .. section..category.."options", 0, childWindowSizeY, true )
                if imgui.Button("Revert Order") then
                    resetShowOptionOrder()
                end

                if cm_persist.selected_widget == 1 then
                    local optionCate = "name"
                    local optionTabl = cateTabl[optionCate]

                    if imgui.TreeNodeEx("Name Options", "DefaultOpen") then
                        if imgui.RadioButton("Right",  optionTabl.justify, 0) then
                            optionTabl.justify = 0
                            this.changed = true
                        end
                        imgui.SameLine()
                        if imgui.RadioButton("Center",  optionTabl.justify, 1) then
                            optionTabl.justify = 1
                            this.changed = true
                        end
                        imgui.SameLine()
                        if imgui.RadioButton("Left",  optionTabl.justify, 2) then
                            optionTabl.justify = 2
                            this.changed = true
                        end

                        imgui.PushItemWidth(120)
                        success, optionTabl.fontScale = imgui.InputFloat("Font Scale", optionTabl.fontScale)
                        imgui.PopItemWidth()
                        if success then
                            this.changed = true
                        end
                        if optionTabl.fontScale ~= 1.0 then
                            imgui.SameLine(0,4)
                            if imgui.Button("Revert") then
                                optionTabl.fontScale = 1.0
                                this.changed = true
                            end
                        end

                        if imgui.Checkbox("New Line", optionTabl.newLine) then
                            optionTabl.newLine = not optionTabl.newLine
                            this.changed = true
                        end

                        if imgui.Checkbox("Color As Weakness", optionTabl.colorAsWeakness) then
                            optionTabl.colorAsWeakness = not optionTabl.colorAsWeakness
                            this.changed = true
                        end

                        imgui.TreePop()
                    end

                elseif cm_persist.selected_widget == 2 then
                    local optionCate = "se"
                    if imgui.TreeNodeEx("Status Effects Options", "DefaultOpen") then

                        imgui.TreePop()
                    end

                elseif cm_persist.selected_widget == 3 then
                    local optionCate = "hp"
                    -- add combo box for alt ways to show hp
                    if imgui.TreeNodeEx("Health Options", "DefaultOpen") then

                        imgui.TreePop()
                    end

                elseif cm_persist.selected_widget == 4 then
                    local optionCate = "damage"
                    if imgui.TreeNodeEx("Damage Options", "DefaultOpen") then

                        imgui.TreePop()
                    end

                elseif cm_persist.selected_widget == 5 then
                    local optionCate = "hit"
                    if imgui.TreeNodeEx("Hit Options", "DefaultOpen") then

                        imgui.TreePop()
                    end

                elseif cm_persist.selected_widget == 6 then
                    local optionCate = "recommended"
                    if imgui.TreeNodeEx("'Recommended' Options", "DefaultOpen") then
                        local SWidthP = 200

                        imgui.PushItemWidth(SWidthP)
                        success, cateTabl[optionCate].targHeavyThresh = imgui.SliderInt("Target Hard Damage Threshold", cateTabl[optionCate].targHeavyThresh, 1, 100)
                        imgui.PopItemWidth()
                        if success then
                            this.changed = true
                        end
            
                        imgui.PushItemWidth(SWidthP)
                        success, cateTabl[optionCate].targSpecThresh = imgui.SliderInt("Target Special Damage Threshold", cateTabl[optionCate].targSpecThresh, 1, 100)
                        imgui.PopItemWidth()
                        if success then
                            this.changed = true
                        end
                        imgui.TreePop()
                    end


                elseif cm_persist.selected_widget == 7 then
                    local optionCate = "rare"
                    if imgui.TreeNodeEx("Rare Options", "DefaultOpen") then

                        imgui.TreePop()
                    end

                elseif cm_persist.selected_widget == 8 then
                    local optionCate = "resist"
                    if imgui.TreeNodeEx("Resistance Options", "DefaultOpen") then

                        imgui.TreePop()
                    end

                elseif cm_persist.selected_widget == 9 then
                    local optionCate = "probability"
                    if imgui.TreeNodeEx("Probability Options", "DefaultOpen") then

                        imgui.TreePop()
                    end
                end

                imgui.EndChild()

                imgui.PopStyleColor()
            end

            if Additional ~= nil then
                -- if imgui.Checkbox("Show Slime Origin", cateTabl.showOrigin) then
                --     cateTabl.showOrigin = not cateTabl.showOrigin
                --     this.changed = true
                -- end
            end

            -- if imgui.Checkbox("Custom Color", cateTabl.useCustomColor) then
            --     cateTabl.useCustomColor = not cateTabl.useCustomColor
            --     this.changed = true
            -- end

            -- if cateTabl.useCustomColor then
            --     cateTabl.customBorderColor = PresentColorEditor("Border Color", 0xFFFF6900, cateTabl.customBorderColor)
            -- end


            imgui.PopID()
        end

        local numTrackersChanged = false
        local lastnumTrackers

        if imgui.TreeNodeEx("General", "DefaultOpen") then
            if imgui.Checkbox("Enable", _configuration.enable) then
                _configuration.enable = not _configuration.enable
                this.changed = true
            end

            imgui.PushItemWidth(100)
            lastnumTrackers =_configuration.numTrackers
            success, _configuration.numTrackers = imgui.InputInt("Max unit frames at once", _configuration.numTrackers)
            imgui.PopItemWidth()
            if success then
                this.changed = true
                numTrackersChanged = true
                _configuration.numTrackers = clampVal(_configuration.numTrackers, 1, _configuration.maxNumTrackers)
            end

            if imgui.Checkbox("Use Custom Screen Resolution", _configuration.customScreenResEnabled) then
                _configuration.customScreenResEnabled = not _configuration.customScreenResEnabled
                this.changed = true
            end

            if _configuration.customScreenResEnabled then
                local curX = imgui.GetCursorPosX()
                
                imgui.PushID("customScreenResEnabled")

                imgui.SetCursorPosX(curX + 20)
                imgui.PushItemWidth(100)
                success, _configuration.customScreenResX = imgui.InputInt("Screen Resolution Width", _configuration.customScreenResX)
                imgui.PopItemWidth()
                if success then
                    this.changed = true
                    _configuration.customScreenResX = clampVal(_configuration.customScreenResX, 1, _configuration.customScreenResX)
                end

                if _configuration.customScreenResX ~= lib_helpers.GetResolutionWidth() then
                    imgui.SameLine(0, 5)
                    if imgui.Button("Revert") then
                        _configuration.customScreenResX = lib_helpers.GetResolutionWidth()
                        this.changed = true
                    end
                end

                imgui.SetCursorPosX(curX + 20)
                imgui.PushItemWidth(100)
                success, _configuration.customScreenResY = imgui.InputInt("Screen Resolution Height", _configuration.customScreenResY)
                imgui.PopItemWidth()
                if success then
                    this.changed = true
                    _configuration.customScreenResY = clampVal(_configuration.customScreenResY, 1, _configuration.customScreenResY)
                end

                if _configuration.customScreenResY ~= lib_helpers.GetResolutionHeight() then
                    imgui.SameLine(0, 5)
                    if imgui.Button("Revert") then
                        _configuration.customScreenResY = lib_helpers.GetResolutionHeight()
                        this.changed = true
                    end
                end

                imgui.PopID()
                imgui.SetCursorPosX(curX)
            end

            if imgui.Checkbox("Use Custom FoV (Field of View)", _configuration.customFoVEnabled) then
                _configuration.customFoVEnabled = not _configuration.customFoVEnabled
                this.changed = true
            end

            if _configuration.customFoVEnabled then
                local curX = imgui.GetCursorPosX()
                imgui.PushID("customFoVEnabled")

                imgui.SetCursorPosX(curX + 20)
                imgui.PushItemWidth(200)
                --success, _configuration.customFoV0 = imgui.SliderFloat("Field of View @ Zoom 0 (Degrees)", _configuration.customFoV0, _configuration.customFoV4, 120)
                success, _configuration.customFoV0 = imgui.DragFloat("Field of View @ Zoom 0 (Degrees)", _configuration.customFoV0, 0.005, _configuration.customFoV4, 120)
                imgui.PopItemWidth()
                if success then
                    this.changed = true
                end
                imgui.SetCursorPosX(curX + 20)
                imgui.PushItemWidth(200)
                success, _configuration.customFoV1 = imgui.SliderFloat("Field of View @ Zoom 1 (Degrees)", _configuration.customFoV1, _configuration.customFoV4, _configuration.customFoV0)
                imgui.PopItemWidth()
                if success then
                    this.changed = true
                end
                imgui.SetCursorPosX(curX + 20)
                imgui.PushItemWidth(200)
                success, _configuration.customFoV2 = imgui.SliderFloat("Field of View @ Zoom 2 (Degrees)", _configuration.customFoV2, _configuration.customFoV4, _configuration.customFoV0)
                imgui.PopItemWidth()
                if success then
                    this.changed = true
                end
                imgui.SetCursorPosX(curX + 20)
                imgui.PushItemWidth(200)
                success, _configuration.customFoV3 = imgui.SliderFloat("Field of View @ Zoom 3 (Degrees)", _configuration.customFoV3, _configuration.customFoV4, _configuration.customFoV0)
                imgui.PopItemWidth()
                if success then
                    this.changed = true
                end
                imgui.SetCursorPosX(curX + 20)
                imgui.PushItemWidth(200)
                success, _configuration.customFoV4 = imgui.DragFloat("Field of View @ Zoom 4 (Degrees)", _configuration.customFoV4, 0.005, 0, _configuration.customFoV0)
                imgui.PopItemWidth()
                if success then
                    this.changed = true
                end

                imgui.PopID()
                imgui.SetCursorPosX(curX)
            end

            imgui.PushItemWidth(100)
            success, _configuration.updateThrottle = imgui.InputInt("Delay Update (miliSeconds)", _configuration.updateThrottle)
            imgui.PopItemWidth()
            if success then
                this.changed = true
            end

            imgui.PushItemWidth(200)
            success, _configuration.server = imgui.Combo("Server", _configuration.server, serverList, table.getn(serverList))
            imgui.PopItemWidth()
            if success then
                this.changed = true
            end

            imgui.TreePop()
        end

        -- UnitFrames display options
        if imgui.TreeNodeEx("Display Options") then
            if imgui.Checkbox("Show Monster HP Bars", _configuration.showMonsterBars ~= false) then
                _configuration.showMonsterBars = not (_configuration.showMonsterBars ~= false)
                this.changed = true
            end
            if imgui.Checkbox("Show Party HP Bars", _configuration.showPartyBars ~= false) then
                _configuration.showPartyBars = not (_configuration.showPartyBars ~= false)
                this.changed = true
            end
            if imgui.Checkbox("Show Own HP Bar", _configuration.showSelfBar == true) then
                _configuration.showSelfBar = not (_configuration.showSelfBar == true)
                this.changed = true
            end
            if imgui.Checkbox("Show Buffs (Shifta/Deband)", _configuration.showBuffs ~= false) then
                _configuration.showBuffs = not (_configuration.showBuffs ~= false)
                this.changed = true
            end
            if imgui.Checkbox("Show Debuffs (Jellen/Zalure)", _configuration.showDebuffs ~= false) then
                _configuration.showDebuffs = not (_configuration.showDebuffs ~= false)
                this.changed = true
            end
            if imgui.Checkbox("Show Section ID", _configuration.showSectionID ~= false) then
                _configuration.showSectionID = not (_configuration.showSectionID ~= false)
                this.changed = true
            end
            imgui.TreePop()
        end

        -- Bar Style
        if imgui.TreeNodeEx("Bar Style") then
            imgui.Text("Monster Bars")
            imgui.PushItemWidth(120)
            success, _configuration.monsterBarWidth = imgui.SliderInt("Monster Bar Width", _configuration.monsterBarWidth or 110, 40, 300)
            imgui.PopItemWidth()
            if success then this.changed = true end
            imgui.PushItemWidth(120)
            success, _configuration.monsterBarHeight = imgui.SliderInt("Monster Bar Height", _configuration.monsterBarHeight or 8, 4, 30)
            imgui.PopItemWidth()
            if success then this.changed = true end
            imgui.PushItemWidth(120)
            success, _configuration.monsterBorderThick = imgui.SliderFloat("Monster Border Thickness", _configuration.monsterBorderThick or 1.0, 0.5, 5.0)
            imgui.PopItemWidth()
            if success then this.changed = true end
            imgui.PushItemWidth(120)
            success, _configuration.monsterIconScale = imgui.SliderFloat("Monster Icon Scale", _configuration.monsterIconScale or 1.0, 0.5, 3.0)
            imgui.PopItemWidth()
            if success then this.changed = true end

            imgui.Text("Player Bars")
            imgui.PushItemWidth(120)
            success, _configuration.playerBarWidth = imgui.SliderInt("Player Bar Width", _configuration.playerBarWidth or 90, 40, 300)
            imgui.PopItemWidth()
            if success then this.changed = true end
            imgui.PushItemWidth(120)
            success, _configuration.playerBarHeight = imgui.SliderInt("Player Bar Height", _configuration.playerBarHeight or 7, 4, 30)
            imgui.PopItemWidth()
            if success then this.changed = true end
            imgui.PushItemWidth(120)
            success, _configuration.playerBorderThick = imgui.SliderFloat("Player Border Thickness", _configuration.playerBorderThick or 1.5, 0.5, 5.0)
            imgui.PopItemWidth()
            if success then this.changed = true end
            imgui.PushItemWidth(120)
            success, _configuration.playerIconScale = imgui.SliderFloat("Player Icon Scale", _configuration.playerIconScale or 1.0, 0.5, 3.0)
            imgui.PopItemWidth()
            if success then this.changed = true end
            imgui.TreePop()
        end

        -- Monster HP colors
        if imgui.TreeNodeEx("Monster HP Colors") then
            imgui.Text("High HP")
            _configuration.hpColorHigh = PresentColorEditor("High HP Color", 0xFF00FF00, _configuration.hpColorHigh or 0xFF00FF00)
            imgui.PushItemWidth(120)
            success, _configuration.hpThreshMid = imgui.SliderInt("Mid Threshold %", _configuration.hpThreshMid or 40, 1, 99)
            imgui.PopItemWidth()
            if success then this.changed = true end

            imgui.Text("Mid HP")
            _configuration.hpColorMid = PresentColorEditor("Mid HP Color", 0xFFFFFF00, _configuration.hpColorMid or 0xFFFFFF00)
            imgui.PushItemWidth(120)
            success, _configuration.hpThreshLow = imgui.SliderInt("Low Threshold %", _configuration.hpThreshLow or 20, 1, 99)
            imgui.PopItemWidth()
            if success then this.changed = true end

            imgui.Text("Low HP")
            _configuration.hpColorLow = PresentColorEditor("Low HP Color", 0xFFFF0000, _configuration.hpColorLow or 0xFFFF0000)

            imgui.Text("Border")
            _configuration.hpBorderColor = PresentColorEditor("Border Color", 0xFF00DDF4, _configuration.hpBorderColor or 0xFF00DDF4)
            imgui.TreePop()
        end

        -- Player HP colors
        if imgui.TreeNodeEx("Player HP Colors") then
            imgui.Text("High HP")
            _configuration.playerHpColorHigh = PresentColorEditor("High HP Color", 0xFF00FF00, _configuration.playerHpColorHigh or 0xFF00FF00)
            imgui.PushItemWidth(120)
            success, _configuration.playerHpThreshMid = imgui.SliderInt("Mid Threshold %", _configuration.playerHpThreshMid or 40, 1, 99)
            imgui.PopItemWidth()
            if success then this.changed = true end

            imgui.Text("Mid HP")
            _configuration.playerHpColorMid = PresentColorEditor("Mid HP Color", 0xFFFFFF00, _configuration.playerHpColorMid or 0xFFFFFF00)
            imgui.PushItemWidth(120)
            success, _configuration.playerHpThreshLow = imgui.SliderInt("Low Threshold %", _configuration.playerHpThreshLow or 20, 1, 99)
            imgui.PopItemWidth()
            if success then this.changed = true end

            imgui.Text("Low HP")
            _configuration.playerHpColorLow = PresentColorEditor("Low HP Color", 0xFFFF0000, _configuration.playerHpColorLow or 0xFFFF0000)

            imgui.Text("Border")
            _configuration.playerHpBorderColor = PresentColorEditor("Border Color", 0xFF00DDF4, _configuration.playerHpBorderColor or 0xFF00DDF4)
            imgui.TreePop()
        end

        local numTrackersToIterate
        if numTrackersChanged and _configuration.numTrackers > lastnumTrackers then
            numTrackersToIterate = lastnumTrackers
        else
            numTrackersToIterate = _configuration.numTrackers
        end

        local section = "tracker"
        local nodeName = "Tracker"
        if imgui.TreeNodeEx(nodeName) then

            local section = "tracker"

            if imgui.Checkbox("Enable", _configuration[section].EnableWindow) then
                _configuration[section].EnableWindow = not _configuration[section].EnableWindow
                _configuration[section].changed = true
                this.changed = true
            end

            if imgui.TreeNodeEx("Window") then

                if imgui.Checkbox("Hide when menus are open", _configuration[section].HideWhenMenu) then
                    _configuration[section].HideWhenMenu = not _configuration[section].HideWhenMenu
                    this.changed = true
                end

                if imgui.Checkbox("Hide when symbol chat/word select is open", _configuration[section].HideWhenSymbolChat) then
                    _configuration[section].HideWhenSymbolChat = not _configuration[section].HideWhenSymbolChat
                    this.changed = true
                end

                if imgui.Checkbox("Hide when the menu is unavailable", _configuration[section].HideWhenMenuUnavailable) then
                    _configuration[section].HideWhenMenuUnavailable = not _configuration[section].HideWhenMenuUnavailable
                    this.changed = true
                end

                imgui.TreePop()
            end
            
            if imgui.TreeNodeEx("Display") then
    
                if imgui.Checkbox("Clamp Monsters Into View", _configuration[section].clampMonsterView) then
                    _configuration[section].clampMonsterView = not _configuration[section].clampMonsterView
                    this.changed = true
                end

                imgui.PushItemWidth(120)
                success, _configuration[section].ignoreItemMaxDist = imgui.InputInt("Always Ignore Monsters Further Than (Distance)", _configuration[section].ignoreItemMaxDist)
                imgui.PopItemWidth()
                if success then
                    this.changed = true
                    _configuration[section].ignoreItemMaxDist = clampVal(_configuration[section].ignoreItemMaxDist, 0, 999999)
                end

                imgui.TreePop()
            end

            if imgui.TreeNodeEx("Monsters") then
                local SWidth = 110
                local SWidthP = SWidth + 16

                for i=1, #monsterSegmentOrder, 1 do
                    local segment = monsterSegmentOrder[i]
                    local monsters = monstersBySegment[monsterSegmentOrder[i]]
                    if imgui.TreeNodeEx(segment) then

                        for i,monster in pairs(monsters) do
                            if monster.cate then

                                if imgui.TreeNodeEx(monster.cate) then
                                    configureMonster(monster, monster.id, section)
                                    imgui.TreePop()
                                end
                            end
                        end

                        imgui.TreePop()
                    end
                end

                imgui.TreePop()
            end
            imgui.TreePop()
        end

    end

    this.Update = function()
        if this.open == false then
            return
        end

        local success

        imgui.SetNextWindowSize(500, 400, 'FirstUseEver')
        success, this.open = imgui.Begin(this.title, this.open)

        _showWindowSettings()

        imgui.End()
    end

    return this
end

return
{
    ConfigurationWindow = ConfigurationWindow,
}
