--[[

[Riven] Rivelina made by Lillgoalie & Mr Articuno

]]

if myHero.charName ~= "Riven" then return end


local version = 0.5
local AUTOUPDATE = true

-------------------------------------------------------------------------------------------------------------------------------
local SCRIPT_NAME = "Rivelina"
local SOURCELIB_URL = "https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua"
local SOURCELIB_PATH = LIB_PATH.."SourceLib.lua"
if FileExist(SOURCELIB_PATH) then
	require("SourceLib")
else
	DOWNLOADING_SOURCELIB = true
	DownloadFile(SOURCELIB_URL, SOURCELIB_PATH, function() print("Required libraries downloaded successfully, please reload") end)
end

if DOWNLOADING_SOURCELIB then print("Downloading required libraries, please wait...") return end

if AUTOUPDATE then
	SourceUpdater(SCRIPT_NAME, version, "raw.github.com", "/Lillgoalie/BoL/master/"..SCRIPT_NAME..".lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/Lillgoalie/VersionFiles/master/"..SCRIPT_NAME..".version"):CheckUpdate()
end

local RequireI = Require("SourceLib")
RequireI:Add("vPrediction", "https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua")
RequireI:Add("SOW", "https://raw.github.com/Hellsing/BoL/master/common/SOW.lua")
RequireI:Check()

if RequireI.downloadNeeded == true then return end
-------------------------------------------------------------------------------------------------------------------------------

require 'VPrediction'
require 'SOW'

--- Constants ---
local QREADY, WREADY, EREADY, RREADY = false, false, false, false
local ignite, igniteReady = nil, nil
local ts
local VP = nil
local qOff, wOff, eOff, rOff = 0,0,0,0
local abilitySequence = {1, 2, 3, 1, 1, 4, 1, 3, 1, 3, 4, 3, 3, 2, 2, 4, 2, 2}
local Ranges = { Q = 260 + 100, W = 250, E = 325, R = 880 , AA = 250}
local AnimationCancel =
{
	[1]=function() myHero:MoveTo(mousePos.x,mousePos.z) end, --"Move"
	[2]=function() SendChat('/l') end, --"Laugh"
	[3]=function() SendChat('/d') end, --"Dance"
	[4]=function() SendChat('/t') end, --"Taunt"
	[5]=function() SendChat('/j') end, --"joke"
	[6]=function() end,
}

local QREADY, WREADY, EREADY, RREADY  = false, false, false, false
local BRKSlot, DFGSlot, HXGSlot, BWCSlot, TMTSlot, RAHSlot, RNDSlot, YGBSlot = nil, nil, nil, nil, nil, nil, nil, nil
local BRKREADY, DFGREADY, HXGREADY, BWCREADY, TMTREADY, RAHREADY, RNDREADY, YGBREADY = false, false, false, false, false, false, false, false

function OnLoad()
	initComponents()
end

function initComponents()
	-- VPrediction Start
	VP = VPrediction()
	-- SOW Declare
	Orbwalker = SOW(VP)
	-- Target Selector
	ts = TargetSelector(TARGET_NEAR_MOUSE, 900)
	
	Menu = scriptConfig("Rivelina by Lillgoalie & Mr Articuno", "RivenBLMA")
	
	Menu:addSubMenu("["..myHero.charName.." - Orbwalker]", "SOWorb")
	Orbwalker:LoadToMenu(Menu.SOWorb)
	
	Menu:addSubMenu("["..myHero.charName.." - Combo]", "RivenCombo")
	Menu.RivenCombo:addParam("combo", "Combo mode", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	-- Menu.RivenCombo:addParam("useF", "Use Flash in Combo ", SCRIPT_PARAM_ONOFF, false)
	Menu.RivenCombo:addSubMenu("Q Settings", "qSet")
	Menu.RivenCombo.qSet:addParam("useQ", "Use Q in combo", SCRIPT_PARAM_ONOFF, true)
	Menu.RivenCombo:addSubMenu("W Settings", "wSet")
	Menu.RivenCombo.wSet:addParam("useW", "Use W in combo", SCRIPT_PARAM_ONOFF, true)
	Menu.RivenCombo:addSubMenu("E Settings", "eSet")
	Menu.RivenCombo.eSet:addParam("useE", "Use E in combo", SCRIPT_PARAM_ONOFF, true)
	Menu.RivenCombo:addSubMenu("R Settings", "rSet")
	Menu.RivenCombo.rSet:addParam("useWeaving", "Use R on Q>AA", SCRIPT_PARAM_ONOFF, true)
	Menu.RivenCombo.rSet:addParam("useR", "Use R in Combo", SCRIPT_PARAM_LIST, 1, { "ALWAYS", "KILLABLE", "NEVER"})
	Menu.RivenCombo.rSet:addParam("rRange", "Maximum range to cast R", SCRIPT_PARAM_SLICE, 850, 400, 900, 0)
	
	Menu:addSubMenu("["..myHero.charName.." - Harass]", "Harass")
	Menu.Harass:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("G"))
	Menu.Harass:addParam("useQ", "Use Q in Harass", SCRIPT_PARAM_ONOFF, true)
	Menu.Harass:addParam("useW", "Use W in Harass", SCRIPT_PARAM_ONOFF, true)
	Menu.Harass:addParam("useE", "Use E in Harass", SCRIPT_PARAM_ONOFF, true)
	
	Menu:addSubMenu("["..myHero.charName.." - Laneclear]", "Laneclear")
	Menu.Laneclear:addParam("lclr", "Laneclear Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
	Menu.Laneclear:addParam("useClearQ", "Use Q in Laneclear", SCRIPT_PARAM_ONOFF, true)
	Menu.Laneclear:addParam("useClearW", "Use W in Laneclear", SCRIPT_PARAM_ONOFF, true)
	Menu.Laneclear:addParam("useClearE", "Use E in Laneclear", SCRIPT_PARAM_ONOFF, true)
	
	Menu:addSubMenu("["..myHero.charName.." - Jungleclear]", "Jungleclear")
	Menu.Jungleclear:addParam("jclr", "Jungleclear Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
	Menu.Jungleclear:addParam("useClearQ", "Use Q in Jungleclear", SCRIPT_PARAM_ONOFF, true)
	Menu.Jungleclear:addParam("useClearW", "Use W in Jungleclear", SCRIPT_PARAM_ONOFF, true)
	Menu.Jungleclear:addParam("useClearE", "Use E in Jungleclear", SCRIPT_PARAM_ONOFF, true)
	
	Menu:addSubMenu("["..myHero.charName.." - Additionals]", "Ads")
	Menu.Ads:addParam("cancel", "Animation Cancel", SCRIPT_PARAM_LIST, 1, { "Move","Laugh","Dance","Taunt","joke","Nothing" })
	AddProcessSpellCallback(function(unit, spell)
		animationCancel(unit, spell)
	end)
	Menu.Ads:addParam("autoLevel", "Auto-Level Spells", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads:addSubMenu("Escape", "escapeMenu")
	Menu.Ads.escapeMenu:addParam("escapeKey", "Escape Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
	Menu.Ads:addParam("weaving", "Q>AA", SCRIPT_PARAM_ONOFF, true)
	Menu.Ads:addParam("hitOnly", "Only Q if hits", SCRIPT_PARAM_ONOFF, true)
	Menu.Ads:addSubMenu("Killsteal", "KS")
	Menu.Ads.KS:addParam("useR", "Use Ultimate", SCRIPT_PARAM_ONOFF, true)
	Menu.Ads.KS:addParam("ignite", "Use Ignite", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.KS:addParam("igniteRange", "Minimum range to cast Ignite", SCRIPT_PARAM_SLICE, 470, 0, 600, 0)
	Menu.Ads:addSubMenu("VIP", "VIP")
	Menu.Ads.VIP:addParam("skin", "Use custom skin (Requires Reload)", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.VIP:addParam("skin1", "Skin changer", SCRIPT_PARAM_SLICE, 1, 1, 7)
	Menu.Ads.VIP:addParam("pCast", "Use packets (VIP Only)", SCRIPT_PARAM_ONOFF, false)
	
	Menu:addSubMenu("["..myHero.charName.." - Target Selector]", "targetSelector")
	Menu.targetSelector:addTS(ts)
	ts.name = "Focus"
	
	Menu:addSubMenu("["..myHero.charName.." - Drawings]", "drawings")
	local DManager = DrawManager()
	DManager:CreateCircle(myHero, Ranges.AA, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"AA range", true, true, true)
	DManager:CreateCircle(myHero, Ranges.Q, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"Q range", true, true, true)
	DManager:CreateCircle(myHero, Ranges.W, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"W range", true, true, true)
	DManager:CreateCircle(myHero, Ranges.E, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"E range", true, true, true)
	DManager:CreateCircle(myHero, Ranges.R, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"R range", true, true, true)
	
	enemyMinions = minionManager(MINION_ENEMY, 360, myHero, MINION_SORT_MAXHEALTH_DEC)
	allyMinions = minionManager(MINION_ALLY, 360, myHero, MINION_SORT_MAXHEALTH_DEC)
	jungleMinions = minionManager(MINION_JUNGLE, 360, myHero, MINION_SORT_MAXHEALTH_DEC)
	
	if Menu.Ads.VIP.skin and VIP_USER then
		GenModelPacket("Riven", Menu.Ads.VIP.skin1)
	end
	
	PrintChat("<font color = \"#33CCCC\">Rivelina by</font> <font color = \"#fff8e7\">Lillgoalie</font> <font color = \"#33CCCC\">&</font> <font color = \"#fff8e7\">Mr Articuno</font>")
end

function OnTick()
	ts:update()
	enemyMinions:update()
	allyMinions:update()
	jungleMinions:update()
	CDHandler()
	KillSteal()
  
  	DFGSlot, HXGSlot, BWCSlot, SheenSlot, TrinitySlot, LichBaneSlot, BRKSlot, TMTSlot, RAHSlot, RNDSlot, STDSlot = GetInventorySlotItem(3128), GetInventorySlotItem(3146), GetInventorySlotItem(3144), GetInventorySlotItem(3057), GetInventorySlotItem(3078), GetInventorySlotItem(3100), GetInventorySlotItem(3153), GetInventorySlotItem(3077), GetInventorySlotItem(3074), GetInventorySlotItem(3143), GetInventorySlotItem(3131)
    QREADY = (myHero:CanUseSpell(_Q) == READY)
    WREADY = (myHero:CanUseSpell(_W) == READY)
    EREADY = (myHero:CanUseSpell(_E) == READY)
    RREADY = (myHero:CanUseSpell(_R) == READY)
    DFGREADY = (DFGSlot ~= nil and myHero:CanUseSpell(DFGSlot) == READY)
    HXGREADY = (HXGSlot ~= nil and myHero:CanUseSpell(HXGSlot) == READY)
    BWCREADY = (BWCSlot ~= nil and myHero:CanUseSpell(BWCSlot) == READY)
    BRKREADY = (BRKSlot ~= nil and myHero:CanUseSpell(BRKSlot) == READY)
    TMTREADY = (TMTSlot ~= nil and myHero:CanUseSpell(TMTSlot) == READY)
    RAHREADY = (RAHSlot ~= nil and myHero:CanUseSpell(RAHSlot) == READY)
    RNDREADY = (RNDSlot ~= nil and myHero:CanUseSpell(RNDSlot) == READY)
    STDREADY = (STDSlot ~= nil and myHero:CanUseSpell(STDSlot) == READY)
    IREADY = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
	
	
	if Menu.Ads.autoLevel then
		AutoLevel()
	end
	
	if Menu.Ads.escapeMenu.escapeKey then
		EscapeMode()
	end
	
	if Menu.RivenCombo.combo then
		Combo()
	end
	
	if Menu.Harass.harass then
		Harass()
	end
	
	if Menu.Laneclear.lclr then
		LaneClear()
	end
	
	if Menu.Jungleclear.jclr then
		JungleClear()
	end
  
end

function CDHandler()
	-- Spells
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
	-- Items
	tiamatSlot = GetInventorySlotItem(3077)
	hydraSlot = GetInventorySlotItem(3074)
	youmuuSlot = GetInventorySlotItem(3142) 
	bilgeSlot = GetInventorySlotItem(3144)
	bladeSlot = GetInventorySlotItem(3153)
	
	tiamatReady = (tiamatSlot ~= nil and myHero:CanUseSpell(tiamatSlot) == READY)
	hydraReady = (hydraSlot ~= nil and myHero:CanUseSpell(hydraSlot) == READY)
	youmuuReady = (youmuuSlot ~= nil and myHero:CanUseSpell(youmuuSlot) == READY)
	bilgeReady = (bilgeSlot ~= nil and myHero:CanUseSpell(bilgeSlot) == READY)
	bladeReady = (bladeSlot ~= nil and myHero:CanUseSpell(bladeSlot) == READY)
	-- Summoners
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
		ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		ignite = SUMMONER_2
	end
	igniteReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
end

-- Harass --

function Harass()
	local enemy = ts.target
	
	if enemy ~= nil and ValidTarget(enemy) then
		if Menu.Harass.useE and EREADY then
			SpellCast(_E, enemy.x, enemy.z)
		end
		if Menu.Harass.useW and ValidTarget(enemy, Ranges.W) and WREADY then
			SpellCast(_W)
      		ItemUsage()
		end
		if Menu.Harass.useQ and ValidTarget(enemy, Ranges.Q) and QREADY then
			if Menu.Ads.weaving then
				qWeaving(enemy)
			end
			if not Menu.Ads.weaving then
				SpellCast(_Q, enemy.x, enemy.z)
			end
		end
	end
	
end

-- End Harass --


-- Combo Selector --

function Combo()
	local typeCombo = 0
	if ts.target ~= nil then
		AllInCombo(ts.target, 0)
	end
	
	--SmartCombo(ts.target)
end

-- Combo Selector --

-- All In Combo -- E1RWQRQ

function AllInCombo(target, typeCombo)
	if target ~= nil and typeCombo == 0 then
		-- Secured stun
		if ValidTarget(target, Ranges.W - 20) and WREADY then
			CastSpell(_W)
		end
		
		-- E+W(+Q) Range Combo --
		-- Initiate part
		if ValidTarget(target, 900) and Menu.RivenCombo.eSet.useE and EREADY and WREADY then
			SpellCast(_E, target.x, target.z)
			DelayAction(function() end, 1500 - GetLatency())
			ItemUsage()
		end
		-- Ultimate passive cast part
		if RREADY and myHero:GetSpellData(_R).name == 'RivenFengShuiEngine' and ValidTarget(target, 360) then
			if Menu.RivenCombo.rSet.useR == 1 then
				SpellCast(_R)
				DelayAction(function() end, 800 - GetLatency())
			end
			if Menu.RivenCombo.rSet.useR == 2 then
				SpellCast(_R)
				DelayAction(function() end, 800 - GetLatency())
			end
		end
		-- W casting part with range checks
		if ValidTarget(target, Ranges.W) and WREADY and Menu.RivenCombo.wSet.useW then
			SpellCast(_W)
		elseif ValidTarget(target, Ranges.Q + Ranges.W) and WREADY and QREADY and Menu.RivenCombo.qSet.useQ then
			SpellCast(_Q, target.x, target.z)
		elseif ValidTarget(target, Ranges.E + Ranges.W) and EREADY and Menu.RivenCombo.eSet.useE then
			SpellCast(_E, target.x, target.z)
			SpellCast(_W)
		end
		-- Ultimate active cast part
		if ValidTarget(target, Menu.RivenCombo.rSet.rRange) and RREADY and myHero:GetSpellData(_R).name == 'rivenizunablade' then
			if Menu.RivenCombo.rSet.useR == 1 and target ~= nil and ValidTarget(target, Menu.RivenCombo.rSet.rRange) then
				SpellCast(_R, target.x, target.z)
			end
			if Menu.RivenCombo.rSet.useR == 2 then
				for i, enemy in ipairs(GetEnemyHeroes()) do
					rDmg = getDmg("R", enemy, myHero)
					if enemy ~= nil and ValidTarget(enemy, Menu.RivenCombo.rSet.rRange) and enemy.health < rDmg then
						SpellCast(_R, enemy.x, enemy.z)
					end
				end
			end
			DelayAction(function() end, 1000 - GetLatency())
		end
		if ValidTarget(target, Ranges.Q) and QREADY and Menu.RivenCombo.qSet.useQ then
			SpellCast(_Q, target.x, target.z)
		end
		
		-- E+W+Q Range Combo --
		
		-- E+Q+Q+W Range Combo --
		if ValidTarget(target, 700) and GetDistance(target) > 500 then
			if Menu.RivenCombo.qSet.useQ and QREADY then
				SpellCast(_Q, target.x, target.z)
			end
		end
		
		-- E+Q+Q+W Range Combo --
		
		
		-- E+Q+Q+Q+W Range Combo --
		if ValidTarget(target, 900) and GetDistance(target) > 700 then
			if Menu.RivenCombo.qSet.useQ and QREADY then
				SpellCast(_Q, target.x, target.z)
			end
		end
		
		-- E+Q+Q+Q+W Range Combo --
	end
end

-- All In Combo --

-- Combo Smart --

function SmartCombo(target)
	if target ~= nil and ValidTarget(target) then
		if RREADY and Menu.RivenCombo.rSet.useR and ValidTarget(target, Ranges.R) then
			rDmg = getDmg("R", target, myHero)
			
			if RREADY and target ~= nil and ValidTarget(target, Menu.RivenCombo.rSet.rRange) and target.health <= rDmg then
				if myHero:GetSpellData(_R).name == 'RivenFengShuiEngine' then
					CastSpell(_R)
				end
				if myHero:GetSpellData(_R).name == 'rivenizunablade' then
					SpellCast(_R, target.x, target.z)
				end
			end
		end
		
		if Menu.Ads.weaving and QREADY and Menu.RivenCombo.qSet.useQ then
			qWeaving(target)
		else
			SpellCast(_Q, target.x, target.z)
		end
		if Menu.RivenCombo.wSet.useW and ValidTarget(target, Ranges.W) and WREADY then
			CastSpell(_W)
		end
		if EREADY and Menu.RivenCombo.eSet.useE and ValidTarget(target, Ranges.E) then
			SpellCast(_E, target.x, target.z)
		end
	end
end

-- End Combo Smart --

function LaneClear()
	for i, enemyMinion in pairs(enemyMinions.objects) do
		for _, allyMinion in pairs(allyMinions.objects) do
			if allyMinion ~= nil and enemyMinion ~= nil then
				-- Ally minions there, no need for shield
				if enemyMinion ~= nil and ValidTarget(enemyMinion) and Menu.Laneclear.useClearQ and QREADY then
					if Menu.Ads.weaving then
						qWeaving(enemyMinion)
					else
						if Menu.Ads.hitOnly then
							if ValidTarget(enemyMinion, Ranges.Q) then
								SpellCast(_Q, enemyMinion.x, enemyMinion.z)
							end
						else
							if ValidTarget(enemyMinion, Ranges.Q) then
								SpellCast(_Q, enemyMinion.x, enemyMinion.z)
							end
						end
					end
				end
				if Menu.Laneclear.useClearW and WREADY and ValidTarget(enemyMinion, Ranges.W) then
					CastSpell(_W)
				end
			end
			if allyminion == nil and enemyMinion ~= nil then
				-- Only enemy minions, need shield
				
				if Menu.Laneclear.useClearQ and QREADY then
					if Menu.Ads.weaving then
						qWeaving(enemyMinion)
					else
						if Menu.Ads.hitOnly then
							if ValidTarget(enemyMinion, Ranges.Q) then
								SpellCast(_Q, enemyMinion.x, enemyMinion.z)
							end
						else
							SpellCast(_Q, enemyMinion.x, enemyMinion.z)
						end
					end
				end
				if Menu.Laneclear.useClearW and WREADY and ValidTarget(enemyMinion, Ranges.W) then
					CastSpell(_W)
				end
			end
		end
	end
end

function JungleClear()
	for i, jungleMinion in pairs(jungleMinions.objects) do
		if jungleMinion ~= nil then
			if Menu.Jungleclear.useClearE and EREADY then
				SpellCast(_E, jungleMinion.x, jungleMinion.z)
			end
			if Menu.Jungleclear.useClearQ and QREADY then
				if Menu.Ads.weaving then
					qWeaving(jungleMinion)
				else
					if Menu.Ads.hitOnly then
						if ValidTarget(jungleMinion, Ranges.Q) then
							SpellCast(_Q, jungleMinion.x, jungleMinion.z)
						end
					else
						SpellCast(_Q, jungleMinion.x, jungleMinion.z)
					end
				end
			end
			if Menu.Jungleclear.useClearW and WREADY and ValidTarget(jungleMinion, Ranges.W) then
				CastSpell(_W)
			end
		end
	end
end

function AutoLevel()
	local qL, wL, eL, rL = player:GetSpellData(_Q).level + qOff, player:GetSpellData(_W).level + wOff, player:GetSpellData(_E).level + eOff, player:GetSpellData(_R).level + rOff
	if qL + wL + eL + rL < player.level then
		local spellSlot = { SPELL_1, SPELL_2, SPELL_3, SPELL_4, }
		local level = { 0, 0, 0, 0 }
		for i = 1, player.level, 1 do
			level[abilitySequence[i]] = level[abilitySequence[i]] + 1
		end
		for i, v in ipairs({ qL, wL, eL, rL }) do
			if v < level[i] then LevelSpell(spellSlot[i]) end
		end
	end
end

function KillSteal()
	if Menu.Ads.KS.useR then
		KSR()
	end
	if Menu.Ads.KS.ignite then
		IgniteKS()
	end
end

-- Use Ultimate to KS --

function KSR()
	for i, enemy in ipairs(GetEnemyHeroes()) do
		rDmg = getDmg("R", enemy, myHero)
		
		if RREADY and enemy ~= nil and ValidTarget(enemy, Menu.RivenCombo.rSet.rRange) and enemy.health < rDmg then
			if myHero:GetSpellData(_R).name == 'RivenFengShuiEngine' then
				SpellCast(_R)
			end
			if myHero:GetSpellData(_R).name == 'rivenizunablade' then
				SpellCast(_R, enemy.x, enemy.z)
			end
		end
	end
end

-- Use Ultimate to KS --

-- Auto Ignite get the maximum range to avoid over kill --

function IgniteKS()
	if igniteReady then
		local Enemies = GetEnemyHeroes()
		for i, val in ipairs(Enemies) do
			if ValidTarget(val, 600) then
				if getDmg("IGNITE", val, myHero) > val.health and RReady ~= true and GetDistance(val) >= Menu.Ads.KS.igniteRange then
					CastSpell(ignite, val)
				end
			end
		end
	end
end

-- Auto Ignite --

function EscapeMode()
	myHero:MoveTo(mousePos.x, mousePos.z)
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if enemy ~= nil and ValidTarget(enemy, Ranges.W) and WREADY then
			CastSpell(_W)
		end
	end
	
	if EREADY then
		SpellCast(_E, mousePos.x, mousePos.z)
	end
	
	if QREADY and not EREADY then
		if QREADY and not EREADY then
			DelayAction(function() end, 1500 - GetLatency())
			SpellCast(_Q, mousePos.x, mousePos.z)
		end
	end
end

function HealthCheck(unit, HealthValue)
	if unit.health > (unit.maxHealth * (HealthValue/100)) then 
		return true
	else
		return false
	end
end

function qWeaving(Target)
	Orbwalker:RegisterAfterAttackCallback(function(target,mode)
		if target.type ~= 'obj_AI_Hero' and Menu.Jungleclear.jclr then
			if QREADY then
				if Menu.Ads.hitOnly then
					if ValidTarget(target, Ranges.Q) then
						SpellCast(_Q, target.x, target.z)
					end
				else
					SpellCast(_Q, target.x, target.z)
				end
			end
		end
		if target.type ~= 'obj_AI_Hero' and Menu.Laneclear.lclr then
			if QREADY then
				if Menu.Ads.hitOnly then
					if ValidTarget(target, Ranges.Q) then
						SpellCast(_Q, target.x, target.z)
					end
				else
					SpellCast(_Q, target.x, target.z)
				end
			end
		end
		if target.type == 'obj_AI_Hero' and Menu.Harass.harass then
			if QREADY then
				if Menu.Ads.hitOnly then
					if ValidTarget(target, Ranges.Q) then
						SpellCast(_Q, target.x, target.z)
					end
				else
					SpellCast(_Q, target.x, target.z)
				end
			end
		end
		if target.type == 'obj_AI_Hero' and Menu.RivenCombo.combo then
			if QREADY then
				if RREADY and Menu.RivenCombo.rSet.useWeaving and myHero:GetSpellData(_R).name == 'RivenFengShuiEngine' then
					CastSpell(_R)
				end
				if Menu.Ads.hitOnly then
					if ValidTarget(target, Ranges.Q) then
						SpellCast(_Q, target.x, target.z)
					end
				else
					SpellCast(_Q, target.x, target.z)
				end
			end
		end
	end)
end

function animationCancel(unit, spell)
	if not unit.isMe then return end
	
	if spell.name == 'RivenTriCleave' then -- _Q
		DelayAction(function() SOW:resetAA() end, nil)
		AnimationCancel[Menu.Ads.cancel]()
	else
		if spell.name == 'RivenMartyr' then -- _W
			
			AnimationCancel[Menu.Ads.cancel]()
		else
			if spell.name == 'RivenFeint' then -- _E
				
				AnimationCancel[Menu.Ads.cancel]()
			else
				if spell.name == 'RivenFengShuiEngine' then -- _R first cast
					--AnimationCancel[Config.Extras.cancel]()
				else
					if spell.name == 'rivenizunablade' then -- _R Second cast
						--AnimationCancel[Config.Extras.cancel]()
					end
				end
			end
		end
	end
end

function SpellCast(spell, posx, posz)
	if Menu.Ads.VIP.pCast and VIP_USER then
		Packet('S_CAST', { spellId = spell, fromX = posx, fromY = posz}):send()
	else
		if posx == nil or posz == nil then
			CastSpell(spell)
		else
			CastSpell(spell, posx, posz)
		end
	end
end

function ItemUsage(target)

    if DFGREADY then CastSpell(DFGSlot, ts.target) end
    if HXGREADY then CastSpell(HXGSlot, ts.target) end
    if BWCREADY then CastSpell(BWCSlot, ts.target) end
    if BRKREADY then CastSpell(BRKSlot, ts.target) end
    if TMTREADY and GetDistance(ts.target) < 275 then CastSpell(TMTSlot) end
    if RAHREADY and GetDistance(ts.target) < 275 then CastSpell(RAHSlot) end
    if RNDREADY and GetDistance(ts.target) < 275 then CastSpell(RNDSlot) end
  
end

-- Change skin function, made by Shalzuth
function GenModelPacket(champ, skinId)
	p = CLoLPacket(0x96)
	p:EncodeF(myHero.networkID)
	p.pos = 1
	t1 = p:Decode1()
	t2 = p:Decode1()
	t3 = p:Decode1()
	t4 = p:Decode1()
	p:Encode1(t1)
	p:Encode1(t2)
	p:Encode1(t3)
	p:Encode1(bit32.band(t4,0xB))
	p:Encode1(1)--hardcode 1 bitfield
	p:Encode4(skinId)
	for i = 1, #champ do
		p:Encode1(string.byte(champ:sub(i,i)))
	end
	for i = #champ + 1, 64 do
		p:Encode1(0)
	end
	p:Hide()
	RecvPacket(p)
end

function OnDraw()
	
end