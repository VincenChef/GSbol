

--[[ GS Syndra Index list:
	1. Draw
	2. Combo
	3. Ball Manager
	4. KS (Sniper E+Q,Ignite)
	5. Harass
	6. Jungle steal
]]--

require 'SOW'
require 'VPrediction'
if myHero.charName ~= "Syndra" then return end
local ts
local mTarget

local version = "0.3"

Qdmg, Wdmg, Edmg, Rdmg, Idmg, dfgDamage = 0,0,0,0,0,0
--[[ Spell data ]]--
local Qrange = 800
local Wrange = 925
local Erange = 750
local Rrange = 750
local QErange = 1300

local Qdelay = 500
local Wdelay = 200
local Edelay = 200

local Qradius = 75
local Wradius = 75
local Eradius = 125

--[[ Spell Status ]]--
local Qready
local Wready
local Eready
local Rready
local QEready


local InterruptList = 
	{
	  ["Katarina"] = "KatarinaR",
	  ["Malzahar"] = "AlZaharNetherGrasp",
	  ["Warwick"] = "InfiniteDuress",
	  ["Velkoz"] = "VelkozR",
          ["FiddleSticks"] = "Drain",
          ["Galio"] = "GalioIdolOfDurand",
          ["FiddleSticks"] = "Crowstorm",
          ["Urgot"] = "UrgotSwap2",
          ["Shen"] = "ShenStandUnited",
          ["Nunu"] = "AbsoluteZero",
          ["Pantheon"] = "Pantheon_GrandSkyfall_Jump",
          ["Varus"] = "VarusQ",
          ["Caitlyn"] = "CaitlynAceintheHole",
          ["MissFortune"] = "MissFortuneBulletTime",
          ["Karthus"] = "FallenOne"
	}
local LastChampionSpell = {}

function Init()
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY,1300,DAMAGE_MAGIC)
	ts.name = "Syndra"
	
	EnemysInTable = 0
	EnemyTable = {}
	
	VP = VPrediction()
	SOWi = SOW(VP)
	

	
	BallTable = 12
	Balls = {}
	for i=1, BallTable do
		Balls[i] = { pos = nil, time = nil, stunball = false, wball = false}
	end
	
	BallCount = 0
	
	SkipGrab = false
	SkipTil = nil
	
	PetChamp = false
	for i=1, heroManager.iCount do
		local champ = heroManager:GetHero(i)
		if champ.team ~= myHero.team then
		EnemysInTable = EnemysInTable + 1
		EnemyTable[EnemysInTable] = { hero = champ, Name = champ.charName, q = 0, w = 0, e = 0, r = 0, IndicatorText = "", IndicatorPos, NotReady = false, Pct = 0, PeelMe = false }
		if champ.charName == "Yorick" or champ.charName == "Malzahar" or champ.charName == "Heimerdinger" or champ.charName == "Annie" then PetChamp = true end
		end
	end
	
	Minions = minionManager(MINION_ALL, 925, myHero)
end

function Menu()
	Config = scriptConfig("GSSyndra","GSSyndra")
	-- Main combo setting
	Config:addSubMenu("GS:Syndra","Combo")
		Config.Combo:addParam("GeneralSetting","---- [ General Settings ]-----",SCRIPT_PARAM_INFO,"")
		Config.Combo:addParam("Knock","Knock dives away",SCRIPT_PARAM_ONOFF,true)
		Config.Combo:addParam("Interrupt","Auto Interrupt",SCRIPT_PARAM_ONOFF,true)
		
		Config.Combo:addParam("ComboSetting","---- [ Combo Settings ]-----",SCRIPT_PARAM_INFO,"")
		Config.Combo:addParam("PrioPet","Prioritize enemy Pets for grab",SCRIPT_PARAM_ONOFF,true)
		Config.Combo:addParam("AutoPet","Auto grab enemy Pets",SCRIPT_PARAM_ONOFF,false)
		
		Config.Combo:addParam("HarassSetting","---- [ Harass/Auto-Harass ]-----",SCRIPT_PARAM_INFO,"")
		Config.Combo:addParam("Wharass","Use W in Harass",SCRIPT_PARAM_ONOFF,true)
		Config.Combo:addParam("Eharass","Use E in Harass",SCRIPT_PARAM_ONOFF,true)
		Config.Combo:addParam("QEharass","Use stun combo in Harass",SCRIPT_PARAM_ONOFF,false)
		
		Config.Combo:addParam("KSSetting","---- [ KS Settings ]-----",SCRIPT_PARAM_INFO,"")
		Config.Combo:addParam("EQks","Snipe(E+Q)",SCRIPT_PARAM_ONOFF,true)
		Config.Combo:addParam("Ignite","Ignite killable",SCRIPT_PARAM_ONOFF,true)
		
		
	-- Orbwalking
	Config:addSubMenu("GS:Orbwalking", "Orbwalking")
	SOWi:LoadToMenu(Config.Orbwalking)
	
	-- Utility
	Config:addSubMenu("GS:Utility","Utility")
		Config.Utility:addParam("AutoPotion","Auto Potion",SCRIPT_PARAM_ONOFF,true)
		Config.Utility:addParam("AutoElixer","Auto Exlixer",SCRIPT_PARAM_SLICE,75,0,100,0)
                Config.Utility:addParam("antigapclosers"," Anti Gapclosers",SCRIPT_PARAM_ONOFF,true)
	
	-- Draw
	Config:addSubMenu("GS:Draw","Draw")
		Config.Draw:addParam("Damage","Draw Damage Indicator",SCRIPT_PARAM_ONOFF,true)
		Config.Draw:addParam("Q","Draw Q Range",SCRIPT_PARAM_ONOFF,true)
		Config.Draw:addParam("W","Draw W Range",SCRIPT_PARAM_ONOFF,true)
		Config.Draw:addParam("E","Draw E Range",SCRIPT_PARAM_ONOFF,false)
		Config.Draw:addParam("R","Draw R Range",SCRIPT_PARAM_ONOFF,true)
		Config.Draw:addParam("QE","Draw Max Stun Range",SCRIPT_PARAM_ONOFF,true)
		
	Config:addTS(ts)
	
	Config:addParam("HotKeySetting","----[ Hotkey Settings ]----",SCRIPT_PARAM_INFO,"")
	Config:addParam("ComboActive","Combo",SCRIPT_PARAM_ONKEYDOWN,false,32)
	Config:addParam("HarassActive","Harass",SCRIPT_PARAM_ONKEYDOWN,false,67)
	Config:addParam("HarassToggle","Auto Harass[toggle]",SCRIPT_PARAM_ONKEYTOGGLE,false,90)
	Config:addParam("JungleActive","Jungle Steal",SCRIPT_PARAM_ONKEYDOWN,false,88)
	Config:addParam("ManualStun","Manual stun target near mouse",SCRIPT_PARAM_ONKEYDOWN,false,86)
end

function OnLoad()
	Init()
	Menu()
	PrintChat("<font color=\"#6200FF\">GS Syndra -</font><font color=\"#66FF00\">c4sau</font>")
	PrintChat("<font color=\"#000000\">You are using version </font><font color = \"#FF0000\">" .. version .. "</font>")
end

function UpdateInfo()
	Qready = myHero:CanUseSpell(_Q) == READY
	Wready = myHero:CanUseSpell(_W) == READY
	Eready = myHero:CanUseSpell(_E) == READY
	Rready = myHero:CanUseSpell(_R) == READY
	QEready = Qready and Eready
	
	QCurrCd = myHero:GetSpellData(_Q).currentCd
	WCurrCd = myHero:GetSpellData(_E).currentCd
	ECurrCd = myHero:GetSpellData(_E).currentCd
	RCurrCd = myHero:GetSpellData(_R).currentCd
	
	Islot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
	Iready = (Islot ~= nil and myHero:CanUseSpell(Islot) == READY)
	
	SOWi:EnableAttacks()
	SOWi:ForceTarget()
	
	Qmana = myHero:GetSpellData(_Q).mana
	Wmana = myHero:GetSpellData(_W).mana
	Emana = myHero:GetSpellData(_E).mana
	Rmana = myHero:GetSpellData(_R).mana
	
	PotionHealthSlot = GetInventorySlotItem(2003)
	PotionHealthReady = (PotionHealthSlot ~= nil and GetInventoryItemIsCastable(2003,myHero))
	PotionManaSlot = GetInventorySlotItem(2004)
	PotionManaReady = (PotionManaSlot ~= nil and GetInventoryItemIsCastable(2004,myHero))
	
	ElixirHealthSlot = GetInventorySlotItem(2037)
	ElixirHealthReady = (ElixirHealthSlot ~= nil and GetInventoryItemIsCastable(2037,myHero))
	ElixirManaSlot = GetInventorySlotItem(2039)
	ElixirManaReady = (ElixirManaSlot ~= nil and GetInventoryItemIsCastable(2039,myHero))
	
	if myHero:GetSpellData(_R).level == 3 then
		Rrange = 750
	end
	
	dfgSlot = GetInventorySlotItem(3128)
	dfgReady = (dfgSlot ~= nil and GetInventoryItemIsCastable(3128,myHero))
	lichSlot = GetInventorySlotItem(3100)
	lichReady = (lichSlot ~= nil and myHero:CanUseSpell(lichSlot) == READY)
	sheenSlot = GetInventorySlotItem(3057)
	sheenReady = (sheenSlot ~= nil and myHero:CanUseSpell(sheenSlot) == READY)

	MyMana = myHero.mana
	ManaPct = math.round((myHero.mana / myHero.maxMana)*100)
	if Qmana + Emana + Rmana <= MyMana then
		GotMana = true
	else
		GotMana = false
	end
	if wTime ~= nil and os.clock()-wTime > 1.4 then 
		ChannelingW = false
		wTime = nil
	end
	if TimeToE and TimeToE + 0.3 < os.clock() then
        TimeToE = nil
        
    end
	
	if ValidTarget(mTarget) then
		THealth = mTarget.health
		Qdmg = getDmg("Q", mTarget, myHero)
		Wdmg = getDmg("W", mTarget, myHero)
		Edmg = getDmg("E", mTarget, myHero)
		Rdmg = getDmg("R", mTarget, myHero)*(3+BallCount)
		SpherEdmg = getDmg("R", mTarget, myHero) 
		
		Idmg = (Iready and getDmg("IGNITE", mTarget, myHero) or 0)
		sheendamage = (SHEENSlot and getDmg("SHEEN",enemy,myHero) or 0)
		lichdamage = (LICHSlot and getDmg("LICHBANE",enemy,myHero) or 0)
		TotalDamage = Qdmg+Edmg+Rdmg+sheendamage+lichdamage+Idmg
		ExtraDamage = sheendamage+lichdamage+Idmg
	end
end

function OnTick()
	Minions:update()
	ts:update()
	mTarget = ts.target
	UpdateInfo()
	
	SOWi:EnableAttacks()
	
	Calculations()
	
	if SkipGrab and SkipTil ~= nil then
		if SkipTil < os.clock() then
			SkipGrab = false
			SkipTil = nil
		end
	end	
	if StunTil ~= nil and StunTil < os.clock() then
		Stunned = nil
		StunTil = nil
	end
	
		
	Grabbed = false
	for i = 1, myHero.buffCount,1 do
		local buff = myHero:getBuff(i)
		if buff.name == "syndrawtooltip" and buff.valid then
			Grabbed = true
		end   
	end
	
	if Config.Combo.AutoPet and PetChamp and GetPet() ~= nil and Wready and not Grabbed then
		CastSpell(_W, GetPet().x, GetPet().z)
	end
	
	if Config.ManualStun then
		for _, enemy in pairs(GetEnemyHeroes()) do	
			if GetDistance(mousePos, enemy) < 250 then
				Stun(enemy, true)
			end		
		end	
	end
	
	if Config.ComboActive then Combo() end
	KS()
	if Config.HarassActive or Config.HarassToggle then Harass() end
	if Config.JungleActive then JungleSteal() end
	
	
	if Config.Combo.Interrupt then
		for i, unit in ipairs(GetEnemyHeroes()) do
			for champion, spell in pairs(InterruptList) do
				if GetDistance(unit) <= QErange and LastChampionSpell[unit.networkID] and spell == LastChampionSpell[unit.networkID].name and (os.clock() - LastChampionSpell[unit.networkID].time < 1) then
					Stun(unit)
				end
			end
		end
	end
	
	if Config.Utility.AutoPotion then
		if myHero.health/myHero.maxHealth < 0.7 then
			if PotionHealthReady then
				CastSpell(PotionHealthSlot)
			end
		end
		if myHero.mana/myHero.maxMana < 0.7 then
			if PotionManaReady then
				CastSpell(PotionManaSlot)
			end
		end
		
		if myHero.health/myHero.maxHealth < Config.Utility.AutoElixer/100 then
			if ElixirHealthReady then
				CastSpell(ElixirHealthSlot)
			end
		end
		if myHero.mana/myHero.maxMana < Config.Utility.AutoElixer/100 then
			if ElixirManaReady then
				CastSpell(ElixirManaSlot)
			end
		end
	end
end

function OnDraw()
	DrawRange()
	DrawDamage()
	
	if mTarget then
		DrawCircle2(mTarget.x,mTarget.y,mTarget.z,103,ARGB(255,0,255,0))
	end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------
--[[ 1. Draw ]]--
--[[Credits to barasia, vadash and viseversa for anti-lag circles]]
function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
	radius = radius or 300
	quality = math.max(8,math.floor(180/math.deg((math.asin((chordlength/(2*radius)))))))
	quality = 2 * math.pi / quality
	radius = radius*.92
	local points = {}
	for theta = 0, 2 * math.pi + quality, quality do
		local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
		points[#points + 1] = D3DXVECTOR2(c.x, c.y)
	end
	DrawLines2(points, width or 1, color or 4294967295)
end

function DrawCircle2(x, y, z, radius, color)
	local vPos1 = Vector(x, y, z)
	local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
	local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
	local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
	if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y })  then
		DrawCircleNextLvl(x, y, z, radius, 1, color, 75)	
	end
end

function DrawRange()
	if Config.Draw.Q then
		if Qready then
			DrawCircle2(myHero.x,myHero.y,myHero.z,Qrange,ARGB(255, 0, 255, 0))
		else
			DrawCircle2(myHero.x,myHero.y,myHero.z,Qrange,ARGB(255, 255, 0, 0))
		end
	end
	if Config.Draw.W then
		if Wready then
			DrawCircle2(myHero.x,myHero.y,myHero.z,Wrange,ARGB(255, 0, 255, 0))
		else
			DrawCircle2(myHero.x,myHero.y,myHero.z,Wrange,ARGB(255, 255, 0, 0))
		end
	end
	if Config.Draw.E then
		if Eready then
			DrawCircle2(myHero.x,myHero.y,myHero.z,Erange,ARGB(255, 0, 255, 0))
		else
			DrawCircle2(myHero.x,myHero.y,myHero.z,Erange,ARGB(255, 255, 0, 0))
		end
	end
	if Config.Draw.R then
		if Rready then
			DrawCircle2(myHero.x,myHero.y,myHero.z,Rrange,ARGB(255, 0, 255, 0))
		else
			DrawCircle2(myHero.x,myHero.y,myHero.z,Rrange,ARGB(255, 255, 0, 0))
		end
	end
	if Config.Draw.QE then
		if QEready then
			DrawCircle2(myHero.x,myHero.y,myHero.z,QErange,ARGB(255, 0, 255, 0))
		else
			DrawCircle2(myHero.x,myHero.y,myHero.z,QErange,ARGB(255, 255, 0, 0))
		end
	end
end

function DrawDamage()
if Config.Draw.Damage then
	for i=1, EnemysInTable do
		local enemy = EnemyTable[i].hero
		if ValidTarget(enemy) then
			
	--		enemy.barData = GetEnemyBarData()
			local barPos = WorldToScreen(D3DXVECTOR3(enemy.x, enemy.y, enemy.z))
            local PosX = barPos.x - 35
            local PosY = barPos.y - 50
	--		local barPosOffset = GetUnitHPBarOffset(enemy)
	--		local barOffset = { x = enemy.barData.PercentageOffset.x, y = enemy.barData.PercentageOffset.y }
	--		local barPosPercentageOffset = { x = enemy.barData.PercentageOffset.x, y = enemy.barData.PercentageOffset.y }
	--		local BarPosOffsetX = 171
	--		local BarPosOffsetY = 46
	--		local CorrectionY =  14.5
	--		local StartHpPos = 31

			local Text = EnemyTable[i].IndicatorText
	--		barPos.x = barPos.x + (barPosOffset.x - 0.5 + barPosPercentageOffset.x) * BarPosOffsetX + StartHpPos 
	--		barPos.y = barPos.y + (barPosOffset.y - 0.5 + barPosPercentageOffset.y) * BarPosOffsetY + CorrectionY 
	
				if EnemyTable[i].NotReady == true then
				
					DrawText(tostring(Text),18,PosX ,PosY ,ARGB(255,255,89,0))		
		--			DrawText("|",13,barPos.x+IndicatorPos ,barPos.y ,orange)
		--			DrawText("|",13,barPos.x+IndicatorPos ,barPos.y-9 ,orange)
		--			DrawText("|",13,barPos.x+IndicatorPos ,barPos.y-18 ,orange)
				else
					DrawText(tostring(Text),18,PosX ,PosY ,ARGB(255,0,255,0))	
		--			DrawText("|",13,barPos.x+IndicatorPos ,barPos.y ,ARGB(255,0,255,0))
		--			DrawText("|",13,barPos.x+IndicatorPos ,barPos.y-9 ,ARGB(255,0,255,0))
		--			DrawText("|",13,barPos.x+IndicatorPos ,barPos.y-18 ,ARGB(255,0,255,0))
				end
			
		end
	end
end
end
function Calculations()
	for i=1, EnemysInTable do
		
		local enemy = EnemyTable[i].hero
		if not enemy.dead and enemy.visible then
		cQdmg = getDmg("Q", enemy, myHero)
		cWdmg = getDmg("W", enemy, myHero)
		cEdmg = getDmg("E", enemy, myHero)
		crTotalDmg = getDmg("R", enemy, myHero) 
		crSpherEdmg = getDmg("R", enemy, myHero) 
		cIdmg = getDmg("IGNITE", enemy, myHero)
		csheendamage = (SHEENSlot and getDmg("SHEEN",enemy,myHero) or 0)
		clichdamage = (LICHSlot and getDmg("LICHBANE",enemy,myHero) or 0)
		cDfgDamage = 0
		cExtraDmg = 0
		cTotal = 0
		
	if Iready then
		cExtraDmg = cExtraDmg + Idmg
	end
	
	if sheenReady then
		cExtraDmg = cExtraDmg + csheenDamage
	end
	
	if lichReady then
		cExtraDmg = cExtraDmg + clichDamage
	end
	

	
	
	if Rready then
		crTotalDmg = crSpherEdmg*(3+BallCount)
		EnemyTable[i].r = crTotalDmg
	else
		EnemyTable[i].r = 0
	end
	
		EnemyTable[i].q = cQdmg

		EnemyTable[i].w = cQdmg

		EnemyTable[i].e = cEdmg
	
	
	
	if dfgReady then 
		cDfgDamage = (EnemyTable[i].q + EnemyTable[i].w + EnemyTable[i].e + EnemyTable[i].r) * 1.2
	end	
	
	-- Make combos
	if enemy.health < EnemyTable[i].q then
		EnemyTable[i].IndicatorText = "Q Kill"
		EnemyTable[i].IndicatorPos = 0
		if Qmana > MyMana or not Qready then
			EnemyTable[i].NotReady = true
		else
			EnemyTable[i].NotReady = false
		end
	
	elseif enemy.health <  EnemyTable[i].r  then
		EnemyTable[i].IndicatorText =  "Ult Kill"
		EnemyTable[i].IndicatorPos = 0
		if Rmana > MyMana or not Rready then
			EnemyTable[i].NotReady = true
		else
			EnemyTable[i].NotReady = false
		end
		
	elseif enemy.health <  EnemyTable[i].q + EnemyTable[i].w then
		EnemyTable[i].IndicatorText =  "Q+W Kill"
		EnemyTable[i].IndicatorPos = 0
		if Qmana + Wmana > MyMana or not Qready or not Wready then
			EnemyTable[i].NotReady = true
		else
			EnemyTable[i].NotReady = false
		end
		
	elseif enemy.health < EnemyTable[i].q + EnemyTable[i].w + EnemyTable[i].e then
		EnemyTable[i].IndicatorText =  "Q+W+E Kill"
		EnemyTable[i].IndicatorPos = 0
		if Wmana+Qmana+Emana > MyMana or not Wready or not Qready or not Eready then
			EnemyTable[i].NotReady = true
		else
			EnemyTable[i].NotReady = false
		end	
		
	elseif enemy.health < EnemyTable[i].q + EnemyTable[i].w + EnemyTable[i].e + cDfgDamage + cExtraDmg then
		EnemyTable[i].IndicatorText =  "Burst Kill"
		EnemyTable[i].IndicatorPos = 0
		if Wmana+Qmana+Emana > MyMana or not Wready or not Qready or not Eready then
			EnemyTable[i].NotReady = true
		else
			EnemyTable[i].NotReady = false
		end			
		
	elseif enemy.health < EnemyTable[i].q + EnemyTable[i].w + EnemyTable[i].e + EnemyTable[i].r + crSpherEdmg + cExtraDmg then
		EnemyTable[i].IndicatorText =  "All-In Kill"
		EnemyTable[i].IndicatorPos = 0
		if Qmana + Rmana > MyMana or not Qready or not Rready then
			EnemyTable[i].NotReady = true
		else
			EnemyTable[i].NotReady = false
		end

		
	else
		
			cTotal = cTotal + EnemyTable[i].q
		
			cTotal = cTotal + EnemyTable[i].w

			cTotal = cTotal + EnemyTable[i].e
		
			cTotal = cTotal + EnemyTable[i].r
		
		
		HealthLeft = math.round(enemy.health - cTotal)
		PctLeft = math.round(HealthLeft / enemy.maxHealth * 100)
		BarPct = PctLeft / 103 * 100
		EnemyTable[i].Pct = PctLeft
		EnemyTable[i].IndicatorPos = BarPct
 		EnemyTable[i].IndicatorText = PctLeft .. "% Harass"
		if not Qready or not Rready or not Eready then
			EnemyTable[i].NotReady =  true
		else
			EnemyTable[i].NotReady = false
		end
		if Qmana + Emana + Rmana > MyMana  then
			EnemyTable[i].NotReady =  true
		else
			EnemyTable[i].NotReady = false
		end

	end	
	end
	end	

end
----------------------------------------------------------------------------------------------------------------------------------------------------------
--[[ 2. Combo ]]--
function UseQ(target)
	if GetDistance(target) <= Qrange then
		local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(target, Qdelay/1000, Qradius, Qrange)
		
		if CastPosition == nil then return end
		if (HitChance < 2) then return end
		
		local predictedpos = Vector(CastPosition.x, 0, CastPosition.z)
		local mypos = Vector(myHero.x, 0, myHero.z)
		
		if GetDistance(myHero.visionPos, predictedpos) < Qrange + Qradius then	
			CastSpell(_Q, predictedpos.x, predictedpos.z)
		end
	end
end

function UseW(target)
	if GetDistance(target) <= Erange then
		local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(target, Wdelay/1000, Wradius, Wrange)
		
		if CastPosition == nil then return end
		if (HitChance <= 2) then return end
		
		local predictedpos = Vector(CastPosition.x, 0, CastPosition.z)
		local mypos = Vector(myHero.x, 0, myHero.z)
		
		if GetDistance(myHero.visionPos, predictedpos) < Wrange + Wradius then	
			CastSpell(_W, predictedpos.x, predictedpos.z)
		end
	end
end

function Dfg()
	if dfgReady then
	if Qdmg + Idmg > THealth then return 
		elseif  Wdmg+ Idmg > THealth then return 
		elseif Wdmg+ Idmg > THealth then return 
		elseif Qdmg+Edmg+ Idmg > THealth then return 
		elseif  Qdmg+Wdmg+ Idmg > THealth then return 
		elseif  Qdmg+Wdmg+ Idmg > THealth then return 
		elseif qReady and wReady and eReady and Qdmg+Wdmg+Edmg > THealth and GetDistance(mTarget) < 800 then 
			CastSpell(dfgSlot, mTarget)
		elseif Qdmg+Wdmg+Edmg+Rdmg+ExtraDamage > THealth then
			CastSpell(dfgSlot, mTarget)
		elseif (Qdmg*2)+Wdmg+Edmg+Rdmg+ExtraDamage > THealth then
			CastSpell(dfgSlot, mTarget)

		end		
		
	end
end
---------------------------------------------- **** STUN STUN STUN WITH BALL *****-----------------------------------------------------
function GrabObject()
	local Grab = nil
	if SkipGrab then return false end
	if Grabbed then return true end
	Grab = GetWObject() 
	if Grab ~= nil and not Grabbed then
		CastSpell(_W, Grab.x, Grab.z)
		return true
	end
	return false
end

function GetWObject()
	local CurrentObject = nil

	local CurrentBall = nil
	local BallNumber = nil
	
	if Config.Combo.PrioPet and PetChamp and GetPet() ~= nil then
		return GetPet()
	end
	
	-- Get the ball which is longest in the game to extend its duration
	for i=1, BallTable do
		if Balls[i].pos ~= nil and GetDistance(Balls[i].pos) < 925  then
			CurrentBall = Balls[i]
			if CurrentObject == nil then CurrentObject = CurrentBall end
			if CurrentBall.time < CurrentObject.time then
				CurrentObject.wBall = false
				CurrentObject = CurrentBall
				CurrentObject.wBall = true

			end
					
		end

	end
	if CurrentObject ~= nil then
		return CurrentObject.pos
	else
		for i, AvaibleMinion in pairs(Minions.objects) do
			if AvaibleMinion ~= nil and AvaibleMinion.valid and AvaibleMinion.team == TEAM_ENEMY then 
				CurrentObject = AvaibleMinion 
			end
		end
		return CurrentObject

	end
	return nil
end

function GetPet()
	for i, AvaibleMinion in pairs(Minions.objects) do
		if AvaibleMinion ~= nil and AvaibleMinion.valid and AvaibleMinion.team == TEAM_ENEMY then 
		
			if AvaibleMinion.name:find("Tibbers") then
				return AvaibleMinion
			elseif AvaibleMinion.name:find("H-28") then
				return AvaibleMinion
			elseif AvaibleMinion.name:find("Voidling") then
				return AvaibleMinion
			elseif AvaibleMinion.name:find("Inky") then
				return AvaibleMinion
			elseif AvaibleMinion.name:find("Blinky") then
				return AvaibleMinion
			elseif AvaibleMinion.name:find("Clyde") then
				return AvaibleMinion			
			end
			
		end
	end
	return nil
end

function getHitBoxRadius(unit)
	if unit ~= nil then 
		return GetDistance(unit.minBBox, unit.maxBBox)/2
	else
		return 0
	end
end

function GetStunBall()
	if ValidTarget(mTarget) and mTarget ~= nil then
		local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(mTarget, 250/1000, Qradius, QErange)
		
		if Position == nil then return end
		local stunball = nil
		if Position then

			local Ball = nil
			for i=1, BallTable do
				if Balls[i].pos ~= nil and GetDistance(Balls[i].pos) < 800 and Eready  then
					if Wready and GetWObject() == Balls[i].pos then return nil end
					local hit = checkhitlinepass(myHero, Balls[i].pos, 80, 1300, Position, getHitBoxRadius(mTarget)) 
					
					if hit then 
					Balls[i].stunball = true 
					stunball = Balls[i].pos
					return stunball
					end
					
				else
					Balls[i].stunball = false
				end
			end
			return stunball
		end	
	end
end

function Stun(unit, manual)
	
	local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(unit, 250/1000, Qradius, QErange)
	
	if (HitChance < 2) then return end
	if Position and GetDistance(Position) < 1300 and  myHero.mana > Qmana + Emana then   
		local x,y,z = (Vector(Position) - Vector(myHero)):normalized():unpack()
		Correction = GetDistance(myHero, Position) / 2 -- Qradius
	 
		local posX = Position.x - (x * Correction)
		local posY = Position.y - (y * Correction) 
		local posZ = Position.z - (z * Correction)
		
		
		--DrawCircle(posX,posY,posZ,100,0xff0000)
		if Qready and Eready then
			CastSpell(_Q, posX, posZ)
			Delay = 1-(GetDistance(Position)/1000)
			DelayAction(function()            
				CastSpell(_E, posX, posZ)   
			end, Delay)
		end
		SkipGrab = true
	end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function Ulti()

	if Rready then
		if Qdmg > THealth and QCurrCd < 1.5 then return 
		elseif  Wdmg > THealth and WCurrCd < 1.5 then return 
		elseif Grabbed and Wdmg > THealth then return 
		elseif Qdmg+Edmg > THealth and QCurrCd < 2 and ECurrCd < 2 then return 
		elseif Qready and Wready and Qdmg+Wdmg > THealth then return 
		elseif Qready and Grabbed and Qdmg+Wdmg > THealth then return 
		elseif Qready and Wready and Eready and Qdmg+Wdmg+Edmg > THealth then return 
		
		elseif THealth < Rdmg + Idmg and GetDistance(mTarget) < 600 then
			if Iready then
				CastSpell(Islot, mTarget)
			end
			CastSpell(_R, mTarget)
		
		
		elseif WCurrCd < 1.5 and Wdmg + Rdmg > THealth then
			if not Qready then
				CastSpell(_R, mTarget)
			end
		elseif Grabbed and Wdmg + Rdmg > THealth then
			if not Qready then
				CastSpell(_R, mTarget)
			end		
		
		elseif Qready and Qdmg + Rdmg > THealth then
			CastSpell(_R, mTarget)
		
				
		elseif mTarget and Qready and Grabbed and Qdmg + Wdmg + Rdmg > THealth then
			--CastSpell(_Q, mTarget.x, mTarget.z)
            --CastSpell(_W, mTarget.x, mTarget.z)
			UseQ(mTarget)
			UseW(mTarget)
			CastSpell(_R, mTarget)
		end
 		
	end
end
function Combo()
	if mTarget == nil then return end
	Dfg()
	Ulti()
	
	if Qready and Eready and GetDistance(mTarget) <=Qrange then
		local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(mTarget, Qdelay/1000, Qradius, Qrange)
		
		if CastPosition == nil then return end
		if (HitChance < 2) then return end
		
		local predictedpos = Vector(CastPosition.x, 0, CastPosition.z)
		local mypos = Vector(myHero.x, 0, myHero.z)
		Delay = 1-(GetDistance(predictedpos)/1000)
		CastSpell(_Q, predictedpos.x, predictedpos.z)
		DelayAction(function()            
				CastSpell(_E, predictedpos.x, predictedpos.z)   
			end, Delay)
	end
			
	if Qready then
		UseQ(mTarget)
	end
	
	if Eready then		--and not Grabbed 
		local StunBall = GetStunBall()
		if StunBall and GetDistance(StunBall)< Erange then			
			CastSpell(_E, StunBall.x, StunBall.z)
			return 
		end
	end
	
	
	if Eready and Qready and not Wready then
		Stun(mTarget)
		return
	end
		
	if GetDistance(mTarget) > Qrange + Qradius + 25 and GetDistance(mTarget) < QErange and Qready and Eready then --
		Stun(mTarget)
		return
	end			
	
	if GetDistance(mTarget) < 925 and Wready then
--		if Qready and qMana + wMana < MyMana then
--			CastSpell(_Q, myHero.x, myHero.z)
--		end
		if Grabbed then
			--CastSpell(_W, mTarget.x, mTarget.z)
			
			UseW(mTarget)
		end
		if not SkipGrab then
			local Grab = GetWObject()
			if Grab ~= nil and not Grabbed then
				CastSpell(_W, Grab.x, Grab.z)
			else
				--CastSpell(_W, mTarget.x, mTarget.z)
				UseW(mTarget)
			end
		end	
	end
end
----------------------------------------------------------------------------------------------------------------------------------------------------------
--[[ 3. Ball Manager ]]--
function OnCreateObj(obj)
	if BallCount <= 0 then BallCount = 0 end
	if obj.name:find("Syndra_DarkSphere_idle") or obj.name:find("Syndra_DarkSphere5_idle") then	
		BallCount = BallCount+1
		for i=1, BallTable do
			if Balls[i].pos == nil then
				Balls[i] = { pos = obj, time=os.clock() }
				return 
			end
		end
	end
	
	if obj ~= nil and obj.type == "obj_AI_Minion" and obj.name ~= nil then
		if obj.name == "TT_Spiderboss7.1.1" then Vilemaw = obj
		elseif obj.name == "Worm12.1.1" then Nashor = obj
		elseif obj.name == "Dragon6.1.1" then Dragon = obj
		elseif obj.name == "AncientGolem1.1.1" then Golem1 = obj
		elseif obj.name == "AncientGolem7.1.1" then Golem2 = obj
		elseif obj.name == "LizardElder4.1.1" then Lizard1 = obj
		elseif obj.name == "LizardElder10.1.1" then Lizard2 = obj end
	end
end

function OnDeleteObj(obj)
	if obj.name:find("Syndra_DarkSphere_idle") or obj.name:find("Syndra_DarkSphere5_idle") then
		for i=1, BallTable do
			if obj == Balls[i].pos then
				Balls[i].pos = nil
				Balls[i].time = nil
				Balls[i].stunball = false
				Balls[i].wball = false
				break
			end
		end
		BallCount = BallCount -1
	end
	
	if obj ~= nil and obj.name ~= nil then
		if obj.name == "TT_Spiderboss7.1.1" then Vilemaw = nil
		elseif obj.name == "Worm12.1.1" then Nashor = nil
		elseif obj.name == "Dragon6.1.1" then Dragon = nil
		elseif obj.name == "AncientGolem1.1.1" then Golem1 = nil
		elseif obj.name == "AncientGolem7.1.1" then Golem2 = nil
		elseif obj.name == "LizardElder4.1.1" then Lizard1 = nil
		elseif obj.name == "LizardElder10.1.1" then Lizard2 = nil end
	end
end

function OnProcessSpell(unit,spell)
	if spell.name:find("SyndraW") then
		Grabbed = true
	end
	if spell.name:find("SyndraE") or spell.name:find("syndrae5") then	
		SkipTil = os.clock()+1
	end
	if unit.type == "obj_AI_Hero" then
		LastChampionSpell[unit.networkID] = {name = spell.name, time=os.clock()}
	end
 if not Config.Utility.antigapclosers then return end
    local jarvanAddition = unit.charName == "JarvanIV" and unit:CanUseSpell(_Q) ~= READY and _R or _Q -- Did not want to break the table below.
    local isAGapcloserUnit = {
--        ['Ahri']        = {true, spell = _R, range = 450,   projSpeed = 2200},
        ['Aatrox']      = {true, spell = _Q,                  range = 1000,  projSpeed = 1200, },
        ['Akali']       = {true, spell = _R,                  range = 800,   projSpeed = 2200, }, -- Targeted ability
        ['Alistar']     = {true, spell = _W,                  range = 650,   projSpeed = 2000, }, -- Targeted ability
        ['Diana']       = {true, spell = _R,                  range = 825,   projSpeed = 2000, }, -- Targeted ability
        ['Gragas']      = {true, spell = _E,                  range = 600,   projSpeed = 2000, },
        ['Graves']      = {true, spell = _E,                  range = 425,   projSpeed = 2000, exeption = true },
        ['Hecarim']     = {true, spell = _R,                  range = 1000,  projSpeed = 1200, },
        ['Irelia']      = {true, spell = _Q,                  range = 650,   projSpeed = 2200, }, -- Targeted ability
        ['JarvanIV']    = {true, spell = jarvanAddition,      range = 770,   projSpeed = 2000, }, -- Skillshot/Targeted ability
        ['Jax']         = {true, spell = _Q,                  range = 700,   projSpeed = 2000, }, -- Targeted ability
        ['Jayce']       = {true, spell = 'JayceToTheSkies',   range = 600,   projSpeed = 2000, }, -- Targeted ability
        ['Khazix']      = {true, spell = _E,                  range = 900,   projSpeed = 2000, },
        ['Leblanc']     = {true, spell = _W,                  range = 600,   projSpeed = 2000, },
        ['LeeSin']      = {true, spell = 'blindmonkqtwo',     range = 1300,  projSpeed = 1800, },
        ['Leona']       = {true, spell = _E,                  range = 900,   projSpeed = 2000, },
        ['Malphite']    = {true, spell = _R,                  range = 1000,  projSpeed = 1500 + unit.ms},
        ['Maokai']      = {true, spell = _Q,                  range = 600,   projSpeed = 1200, }, -- Targeted ability
        ['MonkeyKing']  = {true, spell = _E,                  range = 650,   projSpeed = 2200, }, -- Targeted ability
        ['Pantheon']    = {true, spell = _W,                  range = 600,   projSpeed = 2000, }, -- Targeted ability
        ['Poppy']       = {true, spell = _E,                  range = 525,   projSpeed = 2000, }, -- Targeted ability
        --['Quinn']       = {true, spell = _E,                  range = 725,   projSpeed = 2000, }, -- Targeted ability
        ['Renekton']    = {true, spell = _E,                  range = 450,   projSpeed = 2000, },
        ['Sejuani']     = {true, spell = _Q,                  range = 650,   projSpeed = 2000, },
        ['Shen']        = {true, spell = _E,                  range = 575,   projSpeed = 2000, },
        ['Tristana']    = {true, spell = _W,                  range = 900,   projSpeed = 2000, },
        ['Tryndamere']  = {true, spell = 'Slash',             range = 650,   projSpeed = 1450, },
        ['XinZhao']     = {true, spell = _E,                  range = 650,   projSpeed = 2000, }, -- Targeted ability
    }
    if unit.type == 'obj_AI_Hero' and unit.team == TEAM_ENEMY and isAGapcloserUnit[unit.charName] and GetDistance(unit) < 2000 and spell ~= nil then
        if spell.name == (type(isAGapcloserUnit[unit.charName].spell) == 'number' and unit:GetSpellData(isAGapcloserUnit[unit.charName].spell).name or isAGapcloserUnit[unit.charName].spell) then
            if spell.target ~= nil and spell.target.name == myHero.name or isAGapcloserUnit[unit.charName].spell == 'blindmonkqtwo' then
--                print('Gapcloser: ',unit.charName, ' Target: ', (spell.target ~= nil and spell.target.name or 'NONE'), " ", spell.name, " ", spell.projectileID)
        CastSpell(_E, unit.x, unit.z)
            else
                spellExpired = false
                informationTable = {
                    spellSource = unit,
                    spellCastedTick = GetTickCount(),
                    spellStartPos = Point(spell.startPos.x, spell.startPos.z),
                    spellEndPos = Point(spell.endPos.x, spell.endPos.z),
                    spellRange = isAGapcloserUnit[unit.charName].range,
                    spellSpeed = isAGapcloserUnit[unit.charName].projSpeed,
                    spellIsAnExpetion = isAGapcloserUnit[unit.charName].exeption or false,
                }
            end
        end
    end

end

---------------------------------------------------------------------------------------------------------------------------------------------
--[[ 4.KS ]]--
function KS()
	for _, enemy in pairs(GetEnemyHeroes()) do
		if GetDistance(enemy) < 1300 and ValidTarget(enemy) then
		
			if Config.Combo.EQks and Qready and Eready and enemy.health < Edmg and GetDistance(enemy) > 900 and GetDistance(enemy) < 1300 then
				Stun(enemy)
			end
			if Iready and Config.Combo.Ignite and Idmg > THealth and GetDistance(enemy) < 650  then
				CastSpell(Islot, enemy)
			end
		end
	end
end

-------------------------------------------------------------------------------------------------------------------------------------------
--[[ 5. Harass ]]--
function Harass()
	if mTarget == nil then return end
	if Qready and mTarget and GetDistance(mTarget) < 800 then
		UseQ(mTarget)
	end
		
	if Config.Combo.Eharass then
		if Eready and mTarget and not Grabbed then
			local StunBall = GetStunBall()
			if StunBall and GetDistance(StunBall)<725 then
				CastSpell(_E, StunBall.x, StunBall.z)
				return 
			end
		end
	end
	if Config.Combo.QEharass then
		if GetDistance(mTarget) > 800  then
			if Eready and Qready and not Wready then
				Stun(mTarget)
				return
			end
			if GetDistance(mTarget) > 900 and GetDistance(mTarget) < 1200 and Qready and Eready then
				Stun(mTarget)
				return
			end
			
		end		
	end	
	if Config.Combo.Wharass then
		if mTarget and GetDistance(mTarget) < 925 and Wready  then
			if Grabbed then
				--CastSpell(_W, wPos.x, wPos.z)
				UseW(mTarget)
			end
			if not SkipGrab and GrabObject() then
				--CastSpell(_W, wPos.x, wPos.z)
				UseW(mTarget)
			end
			
		end
	end
		
end
---------------------------------------------------------------------------------------------------------------------------------
--[[ 6. Jungle Steal ]]--
function JungleSteal()

	if Nashor ~= nil then if not Nashor.valid or Nashor.dead or Nashor.health <= 0 then Nashor = nil end end
	if Dragon ~= nil then if not Dragon.valid or Dragon.dead or Dragon.health <= 0 then Dragon = nil end end
	if Golem1 ~= nil then if not Golem1.valid or Golem1.dead or Golem1.health <= 0 then Golem1 = nil end end
	if Golem2 ~= nil then if not Golem2.valid or Golem2.dead or Golem2.health <= 0 then Golem2 = nil end end
	if Lizard1 ~= nil then if not Lizard1.valid or Lizard1.dead or Lizard1.health <= 0 then Lizard1 = nil end end
	if Lizard2 ~= nil then if not Lizard2.valid or Lizard2.dead or Lizard2.health <= 0 then Lizard2 = nil end end
	
	if Nashor ~= nil and GetDistance(Nashor) < 1300 and Nashor.visible then Kill(Nashor, true) end
	if Dragon ~= nil and GetDistance(Dragon) < 1300 and Dragon.visible then Kill(Dragon, true) end
	if Golem1 ~= nil and GetDistance(Golem1) < 1300 and Golem1.visible then Kill(Golem1) end
	if Golem2 ~= nil and GetDistance(Golem2) < 1300 and Golem2.visible then Kill(Golem2) end
	if Lizard1 ~= nil and GetDistance(Lizard1) < 1300 and Lizard1.visible then Kill(Lizard1) end
	if Lizard2 ~= nil and GetDistance(Lizard2) < 1300 and Lizard2.visible then Kill(Lizard2) end	


end

function Kill(object, static)
	local GrabbedObject = false
	if static == nil then static = false end
	DmgOnObject = 0
	local jQdmg = getDmg("Q", object, myHero)
	local jWdmg = getDmg("W", object, myHero)
	
	if not static then
		if Grabbed then
			CastSpell(_W, myHero.x+50, myHero.z+50)
		 
		elseif Qready and Wready  and jQdmg+jWdmg > object.health and GetDistance(object) < 900 then
			CastSpell(_W, object.x, object.z)
			GrabbedObject = true
		elseif Wready and jWdmg > object.health and GetDistance(object) < 1000  then
			CastSpell(_W, object.x, object.z)
		elseif Qready and jQdmg > object.health and GetDistance(object) < 900 then
			CastSpell(_Q, object.x, object.z)
		end
		
	else
		if Grabbed then
			CastSpell(_W, object.x, object.z)
		elseif GetDistance(object) > 1000 and GetDistance(object) < 1400 then
			if Eready and Qready and object.health < jEdmg then
				Stun(object)
			end
		elseif GetDistance(object) < 1000 and Wready and GetWObject() ~= nil and jWdmg > object.health then
			CastSpell(_W, GetWObject().x, GetWObject().z)
			GrabbedObject = true
		elseif GetDistance(object) < 1000 and Wready and GetWObject() == nil and jWdmg > object.health then
			CastSpell(_Q, myHero.x, myHero.z)
			GrabbedObject = true
		elseif GetDistance(object) < 1000 and Wready and Qready and jQdmg + jWdmg > object.health then
			CastSpell(_Q, object.x, object.z)
		elseif GetDistance(object) < 1000 and Qready and jQdmg > object.health then
			CastSpell(_Q, object.x, object.z)
		end
 
	end
end

--------------------------------------------------------------------------------------------
