-- изменения от Mori(GitHub/YouTube/Discord/Telegram: @mrcatsoul):
-- 31.5.25
-- + кд в виде секунд;
-- + команды:
-- ~ /rt counter - вкл/выкл число вражеских игроков, которые должны реснуться;
-- ~ /rt icon - вкл/выкл отображение иконы и текстуры кд;
-- ~ /rt size - размер текста числа кд;

local addonName = ...

RezTimer_Data = {}

local band = bit.band
local GetTime = GetTime
local strf = string.format
local mathmax = math.max
local mathmodf = math.modf

local SPELL_2584_NAME

local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE

local ICON_TEXTURE = "Interface\\Icons\\spell_holy_resurrection"

local nextResTime, secToRes = GetTime()+30, 30
local _29 = 29

local rezTimer = CreateFrame("Frame", addonName.."Frame", UIParent)
rezTimer:SetPoint("CENTER")
rezTimer:SetSize(35, 35)
rezTimer:SetMovable(true)
rezTimer:EnableMouse(true)
rezTimer:SetClampedToScreen(true)

rezTimer.countText = rezTimer:CreateFontString(nil, "ARTWORK")
rezTimer.countText:SetPoint("BOTTOM", 0, -14)
rezTimer.countText:SetFont("Fonts\\ARIALN.ttf", 14, "OUTLINE")

rezTimer.counter = 0

rezTimer.test = false

rezTimer.t = rezTimer:CreateTexture(nil, "background")
rezTimer.t:SetAllPoints()
rezTimer.t:SetTexture(ICON_TEXTURE)

rezTimer.cd = CreateFrame("Cooldown", addonName.."CooldownFrame", rezTimer)
rezTimer.cd:SetAllPoints()
rezTimer.cd:SetScript("OnHide", function(self)
	if rezTimer:IsVisible() then
		if not rezTimer.test then
			self:SetCooldown(GetTime(), _29)
      if not RezTimerSV.icon then
        self:SetAlpha(0)
      end
      nextResTime = GetTime() + _29
			return
		end
		rezTimer:Hide()
		rezTimer.test = false
	end
end)

rezTimer.cdTextFrame = CreateFrame("frame", nil, rezTimer)
rezTimer.cdTextFrame:SetAllPoints()
rezTimer.cdText = rezTimer.cdTextFrame:CreateFontString(nil, "ARTWORK")
rezTimer.cdText:SetPoint("CENTER", 0, 0)
rezTimer.cdText:SetFont("Fonts\\ARIALN.ttf", 18, "OUTLINE")

rezTimer:RegisterForDrag("LeftButton")
rezTimer:RegisterEvent("ADDON_LOADED")
rezTimer:RegisterEvent("PLAYER_ENTERING_WORLD")
rezTimer:SetScript("OnDragStart", rezTimer.StartMoving)
rezTimer:SetScript("OnDragStop", rezTimer.StopMovingOrSizing)

rezTimer:SetScript("OnEvent", function(self, event, ...)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local _, eventType, _, _, _, _, _, dstFlags, spellId = ...

		if eventType == "UNIT_DIED" then
			local isHostile = band(dstFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0
			local isPlayer = band(dstFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0
			
			if isHostile and isPlayer then
				self.counter = self.counter + 1
				self.setText(self.counter)
        RezTimer_Data.counter = self.counter
			end
		elseif (eventType == "SPELL_AURA_APPLIED" and spellId == 44535) or -- 44535 Исцеление духа - Снижение затрат на заклинания на 100%.
			   (eventType == "SPELL_AURA_REMOVED" and spellId == 44521) then -- 44521 Подготовка - Снижение затрат на заклинания и навыки на 100%.
			self:Show()
			self.cd:SetCooldown(GetTime(), 30)
      if not RezTimerSV.icon then
        self.cd:SetAlpha(0)
      end
      nextResTime = GetTime() + 30
			self.setText(0)
			self.counter = 0
      RezTimer_Data.counter = 0
			self.test = false
      if not UIFrameIsFlashing(self.cdText) then
        --print("UIFrameFlash 1")
        self.cdText:SetAlpha(0)
        UIFrameFlash(self.cdText, 0.2, 0.8, 1.6, true, 0.6, 0)
      end
      --print("рес прошел(настоящий)")
      if not RezTimerSV.counter then
        --self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED") -- test
      end
    elseif eventType == "SPELL_AURA_REMOVED" and spellId == 44535 and band(dstFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then -- test
      self:Show()
			self.cd:SetCooldown(GetTime(), 24)
      if not RezTimerSV.icon then
        self.cd:SetAlpha(0)
      end
      nextResTime = GetTime() + 24
			self.test = false
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		if select(2, IsInInstance()) == "pvp" then
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		else
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end
		
		if RezTimerSV.init then
			RezTimerSV.init = false
			self.cd:SetCooldown(GetTime(), 30)
      if not RezTimerSV.icon then
        self.cd:SetAlpha(0)
      end
      nextResTime = GetTime() + 30
			self.test = true
		else
			self:Hide()
		end
    
    SPELL_2584_NAME = GetSpellInfo(2584) -- Ожидание воскрешения (Оставайтесь в поле зрения хранителя душ и дожидайтесь воскрешения.)
    self:update()
	elseif event == "ADDON_LOADED" and ... == addonName then
		self:UnregisterEvent("ADDON_LOADED")
		
		RezTimerSV = RezTimerSV or {init = true, lock = false, scale = 1, fontSize = 18, icon = true, counter = true}
		
		if RezTimerSV.lock then
			self:EnableMouse(false)
		end
		self:SetScale(RezTimerSV.scale)
	end
end)

function rezTimer:update()
  if RezTimerSV.icon then
    self.cd:SetAlpha(1)
    self.t:SetTexture(ICON_TEXTURE)
  else
    self.cd:SetAlpha(0)
    self.t:SetTexture(nil)
  end
  self.cdText:SetFont("Fonts\\ARIALN.ttf", RezTimerSV.fontSize or 18, "OUTLINE")
  self.setText(self.counter)
end

rezTimer.setText = function(n)
  if not RezTimerSV.counter then 
    rezTimer.countText:SetText(nil)
    return 
  end
	if n == 0 then
		rezTimer.countText:SetTextColor(0, 1, 0)
	elseif n == 1 then
		rezTimer.countText:SetTextColor(1, 1, 0)
	elseif n == 2 then
		rezTimer.countText:SetTextColor(1, 0.5, 0)
	else
		rezTimer.countText:SetTextColor(1, 0, 0)
	end
	rezTimer.countText:SetText(n)
end

local UnitIsGhost = UnitIsGhost
local UnitAura = UnitAura
local GetAreaSpiritHealerTime = GetAreaSpiritHealerTime

rezTimer:SetScript("OnUpdate", function(self, elapsed)
  self._t = self._t and self._t + elapsed or 0
  if self._t < 0.1 then return end
  self._t = 0
  
  -- test
  -- if not self.playerDead and SPELL_2584_NAME and GetAreaSpiritHealerTime() and UnitIsGhost("player") and UnitAura("player", SPELL_2584_NAME) then
    -- self.playerDead = true
    -- secToRes = GetAreaSpiritHealerTime()
    -- nextResTime = GetTime() + secToRes+1
    -- self.cd:SetCooldown(GetTime(), secToRes)
  -- elseif self.playerDead and not UnitIsGhost("player") then
    -- self.playerDead = nil
  -- end
  
  secToRes = mathmax(0, (nextResTime - GetTime()))
  
  --local text = secToRes >= 1 and strf("%.0f", secToRes) or secToRes > 0 and strf("%.1f", secToRes) or "" 
  --local text = secToRes >= 1 and secToRes < 27 and mathmodf(secToRes) or secToRes > 0.1 and strf("%.1f", secToRes) or RezTimerSV.icon and 0 or "|T"..ICON_TEXTURE..":0|t"
  --local text = secToRes > 0 and strf("%.1f", secToRes) or "" 
  
  local text = ""
  
  if RezTimerSV.icon then
    if secToRes > 0.9 then
      text = mathmodf(secToRes)
    elseif secToRes >= 0.1 then
      text = strf("%.1f", secToRes)
    else
      text = _29
    end
    RezTimer_Data.cd = text
  else
    if secToRes < _29-0.2 then
      if secToRes > 0.9 then
        text = mathmodf(secToRes)
        RezTimer_Data.cd = text
      elseif secToRes >= 0.1 then
        text = strf("%.1f", secToRes)
        RezTimer_Data.cd = text
      else
        RezTimer_Data.cd = strf("%.1f", secToRes)
        text = "|T"..ICON_TEXTURE..":0|t"
      end
    else
      RezTimer_Data.cd = mathmodf(secToRes)
      text = "|T"..ICON_TEXTURE..":0|t"
    end
  end
  
  --RezTimer_Data.cd = text

  if self.cdText:GetText() ~= tostring(text) then
    if UIFrameIsFlashing(self.cdText) then
      UIFrameFlashStop(self.cdText)
    end
    self.cdText:SetText(text)
    if secToRes < 0.1 or text == "|T"..ICON_TEXTURE..":0|t" then
      if not UIFrameIsFlashing(self.cdText) --[[and self.cdText:GetText() == "|T"..ICON_TEXTURE..":0|t"]] then
        self.cdText:SetAlpha(0)
        --print("UIFrameFlash 2")
        --UIFrameFlash(self.cdText, 0.2, 0.6, 1.6, true, 0.6, 0)
        UIFrameFlash(self.cdText, 0.2, 0.8, 1.6, true, 0.6, 0)
        --/run rezTimer.cdText:SetText("|TInterface\\Icons\\spell_holy_resurrection:0|t") UIFrameFlash(rezTimer, 0.4, 0.4, 1, true, 0.2, 0)
      end
      --print("рес прошел(по таймеру)",GetAreaSpiritHealerTime(),secToRes)
    end
  end
  
  if not UIFrameIsFlashing(self.cdText) then
    self.cdText:SetAlpha(1)
  end
end)

SLASH_REZTIMER1, SLASH_REZTIMER2 = "/reztimer", "/rt"

function SlashCmdList.REZTIMER(option)
	if option ~= "" then
		local option, value = string.split(" ", string.lower(option))
		if option == "test" then
			rezTimer.test = true
			rezTimer:Show()
			rezTimer.cd:SetCooldown(GetTime(), 30)
      if not RezTimerSV.icon then
        rezTimer.cd:SetAlpha(0)
      end
      nextResTime = GetTime() + 30
		elseif option == "lock" then
			if RezTimerSV.lock then
				rezTimer:EnableMouse(true)
				RezTimerSV.lock = false
				print("|cFFFFFF00RezTimer unlocked")
			else
				rezTimer:EnableMouse(false)
				RezTimerSV.lock = true
				print("|cFFFFFF00RezTimer locked")
			end
		elseif option == "scale" then
			value = tonumber(value)
			
			if value and value > 0 then
				rezTimer:SetScale(value)
				RezTimerSV.scale = value
			else
				print("|cFFFFFF00Incorrect value")
			end
		elseif option == "size" then
			value = tonumber(value)
			
			if value and value > 5 then
        RezTimerSV.fontSize = value
        rezTimer:update()
			else
				print("|cFFFFFF00Incorrect value")
			end
		elseif option == "icon" then
      if RezTimerSV.icon == true then
        RezTimerSV.icon = false
      else
        RezTimerSV.icon = true
      end
      rezTimer:update()
		elseif option == "counter" then
      if RezTimerSV.counter == true then
        RezTimerSV.counter = false
      else
        RezTimerSV.counter = true
      end
      rezTimer:update()
		else
			print("|cFFFFFF00Incorrect syntax")
		end
	else
		print("|cFFFFFF00Usage: " .. SLASH_REZTIMER1 .. " or " .. SLASH_REZTIMER2 .. " <option>")
		print("|cFFFFFF00Options: test, lock, scale <number>")
	end
end
