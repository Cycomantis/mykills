--MyKills
--29-Jul-2015
--v1.0.1b

--Author: Cycomantis
--[[Notes
MyKills is a simple light weight Battleground statistics tracking addon. 
MyKills tracks your total Damage, Healing, Killing Blows, Deaths, and Kill/Death Ratio for the current battleground. 
It also tracks total Killing Blows, Deaths, and Kill/Death Ratio for both the current session(from log in to log out), and lifetime(from first installation of the addon) as well as your current Kill Streak.
MyKills by default will only be displayed in Battlegrounds, this option can be changed using the /mykills show and /mykills hide commands from your chat window. Only information in Battlegrounds will be displayed.

Commands:
/mykills show --displays MyKills
/mykills hide --hides MyKills
/mykills reset --reset both Current Battleground and Session stats.

MyKills is still in early beta, and features can/will still be added. Feedback/recommendations are highly encouraged.
Things to Add:
-Win/Loss for Session and Lifetime
-Convert Persistent Vars to a Table
-Reset Lifetime Stats Command??
-Overall Code Clean-up, standardization, and optimize

Inspired by KillTally by Zendil-The Underbog
]]

--Event Handler
function MK_OnEvent(self, event, ...)
	if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
		RequestBattlefieldScoreData()
	elseif (event == "UPDATE_BATTLEFIELD_SCORE") then
		MK_OnCombatLogEvent(self, event, ...)
	elseif (event == "ADDON_LOADED") then
		if (MKLifetimeKills == nil) then
			MKLifetimeKills = 0
		end
		if (MKLifetimeDeaths == nil) then
			MKLifetimeDeaths = 0
		end
		if (MKKillStreak == nil) then
			MKKillStreak = 0
		end
		if (MKShowMe == nil) then
			MKShowMe = false
		end
		MK_UpdateFrame()
	elseif (event == "PLAYER_ENTERING_WORLD") then
		MK_EnterInstance()
	elseif (event == "PLAYER_DEAD") then
		MK_OnDeath()
	end
end

--Functions
function MK_EnterInstance(self)
	local instanceType = select(2, IsInInstance())
	if (instanceType == "pvp") then
		MKFrame:Show()
		print("PVP Area, MyKills shown.")
		MKDmg = 0
		MKHeals = 0
		MKKillingBlows = 0
		MKOldKillingBlows = 0
		MKDeaths = 0
		MKRatio = 0
		MK_UpdateFrame()
	elseif MKShowMe then
		MKFrame:Show()
	else
		MKFrame:Hide()
		print("Non-PVP Area, MyKills hidden.")
	end
end

function MK_checkPlayerName()
	if ((playername == nil) or (playername == "") or (playername == "Unknown")) then
		playername = UnitName("player");
	end
end

function MK_OnCombatLogEvent(self, event, ...)
	local instanceType = select(2, IsInInstance())
	if (instanceType == "pvp") then
		if (GetNumBattlefieldScores() > 0) then
			MK_checkPlayerName()
			for playerIndex = 1, GetNumBattlefieldScores() do
				local name = GetBattlefieldScore(playerIndex)
				if name == playername then
					playerNumber = playerIndex
				end
			end
			name, killingBlows, honorableKills, deaths, honorGained, faction, race, class, classToken, damageDone, healingDone, bgRating, ratingChange, preMatchMMR, mmrChange, talentSpec = GetBattlefieldScore(playerNumber)
			MKDmg = damageDone
			MKHeals = healingDone
			MKKillingBlows = MKKillingBlows + (killingBlows - MKOldKillingBlows)
			MKKillStreak = MKKillStreak + (killingBlows - MKOldKillingBlows)
			MKSessionKills =  MKSessionKills + (killingBlows - MKOldKillingBlows)
			MKLifetimeKills = MKLifetimeKills + (killingBlows - MKOldKillingBlows)
			MKDeaths = MKDeaths + (deaths - MKOldDeaths)
			MKSessionDeaths = MKSessionDeaths + (deaths - MKOldDeaths)
			MKLifetimeDeaths = MKLifetimeDeaths + (deaths - MKOldDeaths)
			MKOldKillingBlows = killingBlows
			MKOldDeaths = deaths
			MK_UpdateFrame()
		end
	end
end

function MK_OnDeath(self)
	local instanceType = select(2, IsInInstance())
	if (instanceType == "pvp") then
		if (time() - MKLastDeath > 1) then
			print("Killstreak ended. Previous streak: "..MKKillStreak)
			MKKillStreak = 0
			MKLastDeath = time()
		end
	end
end

function MK_UpdateFrame(self)
	if (MKDeaths == 0) then
		MKRatio = 0
	else
		MKRatio = string.format("%.2f", MKKillingBlows / MKDeaths)
	end
	if (MKSessionDeaths == 0) then
		MKSessionRatio = 0
	else
		MKSessionRatio = string.format("%.2f", MKSessionKills / MKSessionDeaths)
	end
	if (MKLifetimeDeaths == 0) then
		MKLifetimeRatio = 0
	else
		MKLifetimeRatio = string.format("%.2f", MKLifetimeKills / MKLifetimeDeaths)
	end
	UpdateAddOnMemoryUsage()
	mem = string.format("%.2f",GetAddOnMemoryUsage("MyKills") / 1000).." MB";
	frameText = "Damage: "..MKDmg.."\nHealing: "..MKHeals.."\n\nKilling Blows: "..MKKillingBlows.."\nKill Streak: "..MKKillStreak.."\nDeaths: "..MKDeaths.."\nRatio: "..MKRatio.."\n\nSession Kills: "..MKSessionKills.."\nSession Deaths: "..MKSessionDeaths.."\nSession Ratio: "..MKSessionRatio.."\n\nLifetime Kills: "..MKLifetimeKills.."\nLifetime Deaths: "..MKLifetimeDeaths.."\nLifetime Ratio: "..MKLifetimeRatio.."\nMEM Usage: "..mem;
	MKText:SetText(frameText)
end

function MK_OnLoad(self)
	MKFrame:RegisterForDrag("LeftButton")
	SlashCmdList["MyKillsCMD"] = MK_Command;
    SLASH_MyKillsCMD1 = "/MyKills";
	MKFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	MKFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	MKFrame:RegisterEvent("PLAYER_DEAD")
	MKFrame:RegisterEvent("ADDON_LOADED")
	MKFrame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
	MKDmg = 0
	MKHeals = 0
	MKKillingBlows = 0
	MKKillStreak = 0
	MKDeaths = 0
	MKRatio = 0
	MKSessionKills = 0
	MKSessionDeaths = 0
	MKSessionRatio = 0
    MKLastDeath = 0
	MKLifetimeKills = 0
	MKLifetimeDeaths = 0
	MKLifetimeRatio = 0
	MKLastKillTime = 0
	MKOldKillingBlows = 0
	MKOldDeaths = 0
	MKShowMe = false
	MK_UpdateFrame()
end

function MK_Reset(self)
	MKDmg = 0
	MKHeals = 0
	MKKillingBlows = 0
	MKKillStreak = 0
	MKDeaths = 0
	MKRatio = 0
	MKSessionKills = 0
	MKSessionDeaths = 0
	MKSessionRatio = 0
    MKLastDeath = 0
	MK_UpdateFrame()
end

function MK_OnUpdate(self)
	
end

function MK_DragStart(self)
    MKFrame:StartMoving()
end

function MK_DragStop(self)
    MKFrame:StopMovingOrSizing()
end

function MK_Command(msg)
	local setting = strsub(string.lower(msg), 1, 5)
	if( setting == "hide" ) then
		MKFrame:Hide()
		MKShowMe = false
		print("MyKills hidden.")
	elseif( setting == "show" ) then
		MKFrame:Show()
		MKShowMe = true
		print("MyKills showing.")
	elseif( setting == "reset" ) then
		MK_Reset()
		print("MyKills reset.")
	else
		print("Commands are:")
		print("'/MyKills hide")
		print("'/MyKills show")
		print("'/MyKills reset")
	end
end