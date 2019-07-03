CommandButtonOverLayText = {}
UnitCastAbleSpells = {}
CurrentSelectedUnit = {}
--setmetatable(UnitCastAbleSpells, {__mode = "k"})--autoforget units when no strong reference is left

function UpdateTextOverLay()
    local playerIndex = GetLocalPlayer()
    if UnitCastAbleSpells[CurrentSelectedUnit[playerIndex]] then
        for k,v in pairs(UnitCastAbleSpells[CurrentSelectedUnit[playerIndex]]) do
            --print (k)
            local spellId = v.SpellId
            if spellId then
            
            
            --v is the table, k the key
                local fh = v.TextFrame
                --local fh = CommandButtonOverLayText[BlzGetOriginFrame(ORIGIN_FRAME_COMMAND_BUTTON, v.TextFrameIndex)]
                --print(BlzFrameIsVisible(BlzGetOriginFrame(ORIGIN_FRAME_COMMAND_BUTTON, v.TextFrameIndex)))
                if fh and BlzFrameIsVisible(BlzGetOriginFrame(ORIGIN_FRAME_COMMAND_BUTTON, v.TextFrameIndex)) then
                 
                    local cd = BlzGetUnitAbilityCooldownRemaining(CurrentSelectedUnit[playerIndex], spellId)

                    if cd > 0.0 then

                        if cd < 10 then
                            BlzFrameSetText(fh, R2SW(cd,1,1))
                        else
                            BlzFrameSetText(fh, I2S(R2I(cd)))
                        end
                        BlzFrameSetVisible(fh, true)
                    else
                        BlzFrameSetVisible(fh, false)
                    end
                else
                    BlzFrameSetVisible(fh, false)
                end
            end
        end
    end

    --Item cooldowns
    local index = 0
    repeat
        local itemAtIndex = UnitItemInSlot (CurrentSelectedUnit[playerIndex], index)
        if itemAtIndex then
            local spell = BlzGetItemAbilityByIndex(itemAtIndex, 0)
            if UnitCastAbleSpells[CurrentSelectedUnit[playerIndex]][spell] then
                local spellId = UnitCastAbleSpells[CurrentSelectedUnit[playerIndex]][spell].SpellId
                local cd = BlzGetUnitAbilityCooldownRemaining(CurrentSelectedUnit[playerIndex], spellId)
                local fh = CommandButtonOverLayText[BlzGetOriginFrame(ORIGIN_FRAME_ITEM_BUTTON, index)]
                if cd > 0.0 then
                    if cd < 10 then
                        BlzFrameSetText(fh, R2SW(cd,1,1))
                    else
                        BlzFrameSetText(fh, I2S(R2I(cd)))
                    end
                    BlzFrameSetVisible(fh, true)
                else
                    BlzFrameSetVisible(fh, false)
                end
            end
        else
            BlzFrameSetVisible(CommandButtonOverLayText[BlzGetOriginFrame(ORIGIN_FRAME_ITEM_BUTTON, index)], false)
        end
        index = index + 1
    until index == bj_MAX_INVENTORY

end

function UpdateSelection()
    print("UpdateSelection")
    CurrentSelectedUnit[GetTriggerPlayer()] = GetTriggerUnit()
    --hide all overlays

    for k,v in pairs(CommandButtonOverLayText) do
        if GetLocalPlayer() == GetTriggerPlayer() then
            BlzFrameSetVisible(v, false)
        end
    end

end
function UpdateUnitSpellPos(caster)
    --incomplete misses case in which units have skill point selection or attack ground buttons

    print("UpdateUnitSpellPos")
    local spellCount = -1
    local spell
    local table = {}
    local unallowed = {}

    local index = 0
    UnitCastAbleSpells[caster] = nil
    UnitCastAbleSpells[caster] = {}

    repeat
        local itemAtIndex = UnitItemInSlot (caster, index)
        if itemAtIndex then
            local itemSpellIndex = 0
            repeat
                spell = BlzGetItemAbilityByIndex(itemAtIndex, itemSpellIndex)
                if spell then
                    unallowed[spell] = true
                end
                itemSpellIndex = itemSpellIndex + 1
            until spell == nil
        end
        index = index + 1
    until index == bj_MAX_INVENTORY
   
    repeat --find max index
        spellCount = spellCount + 1
        spell = BlzGetUnitAbilityByIndex(caster, spellCount)
    until spell == nil
    print(spellCount)
    repeat
        spellCount = spellCount - 1
        spell = BlzGetUnitAbilityByIndex(caster, spellCount)
        
        local indexWanted = BlzGetAbilityIntegerField(spell, ABILITY_IF_BUTTON_POSITION_NORMAL_X)+ BlzGetAbilityIntegerField(spell, ABILITY_IF_BUTTON_POSITION_NORMAL_Y)*4
        if indexWanted ~= -44 and indexWanted ~= 0 and not unallowed[spell] then -- Y=-11 X=0
            local indexTry = indexWanted
            
            while table[indexTry]
            do
                indexTry = indexTry + 1
                if indexTry > 11 then break end
            end
            if indexTry > 11 or table[indexTry] then
                indexTry = indexWanted
                while table[indexTry] and indexTry > -1
                do
                    indexTry = indexTry - 1
                end
            end
            if indexTry >= 0 then --success
                print(BlzGetAbilityStringLevelField(spell, ABILITY_SLF_TOOLTIP_NORMAL,0))
                BJDebugMsg(" -> "..I2S(indexTry))
                table[indexTry] = true
                UnitCastAbleSpells[caster][spell] = {}
                UnitCastAbleSpells[caster][spell].TextFrame = CommandButtonOverLayText[BlzGetOriginFrame(ORIGIN_FRAME_COMMAND_BUTTON, indexTry)]
                UnitCastAbleSpells[caster][spell].TextFrameIndex = indexTry
            end
        end
    until spellCount == 0
    print("DOne")
end
function RememberCasting()
    print("RememberCasting")
    local spell = GetSpellAbility()
    local spellId = GetSpellAbilityId()
    local caster = GetTriggerUnit()
    
    if not UnitCastAbleSpells[caster] then UnitCastAbleSpells[caster] = {} end
    if not UnitCastAbleSpells[caster][spell] then UnitCastAbleSpells[caster][spell] = {} end
    UnitCastAbleSpells[caster][spell].SpellId = spellId
    
    print(GetUnitName(caster))
    print(GetObjectName(spellId))
    print(spell)
    print(UnitCastAbleSpells[caster][spell].TextFrame)
end

function CreateTextOverLay()
    local trig = CreateTrigger()
    TriggerRegisterAnyUnitEventBJ(trig, EVENT_PLAYER_UNIT_SPELL_EFFECT)
    TriggerAddAction(trig, RememberCasting)

    trig = CreateTrigger()
    TriggerRegisterPlayerSelectionEventBJ(trig, Player(0), true)
    TriggerRegisterPlayerSelectionEventBJ(trig, Player(1), true)
    TriggerAddAction(trig, UpdateSelection)

    BlzLoadTOCFile("war3mapImported\\CDText.toc")

    local index = 0
    
    repeat
        local fh = BlzCreateFrame("CDText", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0)
        CommandButtonOverLayText[BlzGetOriginFrame(ORIGIN_FRAME_COMMAND_BUTTON, index)] = fh
        BlzFrameSetAllPoints(fh, BlzGetOriginFrame(ORIGIN_FRAME_COMMAND_BUTTON, index))
        BlzFrameSetText(fh, I2S(index))  
        index = index + 1
    until index == 12

    index = 0
    repeat
        local fh = BlzCreateFrame("CDText", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0)
        CommandButtonOverLayText[BlzGetOriginFrame(ORIGIN_FRAME_ITEM_BUTTON, index)] = fh
        BlzFrameSetAllPoints(fh, BlzGetOriginFrame(ORIGIN_FRAME_ITEM_BUTTON, index))
        BlzFrameSetText(fh, I2S(index))
        index = index + 1
    until index == bj_MAX_INVENTORY
    TimerStart(CreateTimer(), 0.1, true, UpdateTextOverLay)
    
end

function isInTargetingMode()
    local index = 0
    repeat
        if (BlzFrameIsVisible(BlzGetOriginFrame(ORIGIN_FRAME_COMMAND_BUTTON, index))) then break end
        index = index + 1
    until index == 12

    return index == 11
end
