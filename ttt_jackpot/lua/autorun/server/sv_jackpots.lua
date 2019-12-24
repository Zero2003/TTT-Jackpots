util.AddNetworkString("jackpot_start");
util.AddNetworkString("jackpot_over");
util.AddNetworkString("jackpot_no_winner");
util.AddNetworkString("ttt_jackpots_info");
include("jackpot_config.lua");

local prefix = "[JACKPOT]: "
local count = count || 0
local jackpotround = jackpotround || false
local jackpot_divide = jackpot_divide || 0
local jackpot_last_proper_kill = jackpot_last_proper_kill || nil

if !file.Exists("ttt_jackpot_wins.txt", "DATA") then
    if SERVER then
        print("Performing first time installation of ttt_jackpots...")
        file.Append("ttt_jackpot_wins.txt", "This file will only be used if jackpot_server_log_to_file is set to true in jackpot_config.lua\n")
    end
end

hook.Add("TTTBeginRound", "TTT_Jackpot", function ()
    if count < jackpot_round_delay then
        count = count + 1
        jackpotround = false
        if jackpot_developer_mode then
            for k, v in ipairs(player.GetHumans()) do
                if IsValid(v) then
                    v:ChatPrint(prefix .. "jackpot round = " .. tostring(jackpotround))
                end
            end
        end
        return;
    else
        count = 0
        jackpotround = true
        if jackpot_developer_mode then
            for k, v in ipairs(player.GetHumans()) do
                if IsValid(v) then
                    v:ChatPrint(prefix .. "jackpot round = " .. tostring(jackpotround))
                end
            end
        end
    end
    timer.Simple(1, function ()
        jackpot_traitors = {}
        jackpot_divide = 0
        for k, v in ipairs(player.GetHumans()) do
            if v:IsActiveTraitor() then
                table.insert(jackpot_traitors, v)
                jackpot_divide = jackpot_divide + 1
            end
        end
    end);
    net.Start("jackpot_start");
    net.Broadcast()
end);

hook.Add("TTTEndRound", "jackpot_win", function (r)
    if jackpotround then
        if r == WIN_TRAITOR then
            for k, v in ipairs(player.GetHumans()) do
                if table.HasValue(jackpot_traitors, v) && IsValid(v) then
                    if jackpot_divide <= 4 then
                        jackpot_divide = 8
                    end
                    local amount = jackpot_reward / jackpot_divide
                    v:PS_GivePoints(amount)
                    v:ChatPrint(prefix .. "You won " .. amount .. "!")
                    if jackpot_server_log && !jackpot_server_log_to_file then
                        local istraitor = v:IsTraitor()
                        if !isbool(tobool(istraitor)) && jackpot_developer_mode then
                            ServerLog("[JACKPOT FATAL]: Tried to log tobool(istraitor) and got tobool(istraitor) is not a bool!")
                            return;
                        end
                        if istraitor then
                            ServerLog("[" .. os.date() .. "] " .. v:Nick() .. " (TRAITOR) won " .. amount .. ".")
                        elseif !istraitor then
                            ServerLog("[" .. os.date() .. "] " .. v:Nick() .. " (INNOCENT) won " .. amount .. ".")
                        end
                    elseif jackpot_server_log_to_file && !jackpot_server_log then
                        local istraitor = v:IsTraitor()
                        if !isbool(tobool(istraitor)) && jackpot_developer_mode then
                            ServerLog("[JACKPOT FATAL]: Tried to log tobool(istraitor) and got tobool(istraitor) is not a bool!")
                            return;
                        end
                        if istraitor then
                            file.Append("ttt_jackpot_wins.txt", "[" .. os.date("%c", os.time()) .. "] " .. v:Nick() .. " (TRAITOR) won " .. amount .. ".\n")
                        elseif !istraitor then
                            file.Append("ttt_jackpot_wins.txt", "[" .. os.date("%c", os.time()) .. "] " .. v:Nick() .. " (INNOCENT) won " .. amount .. ".\n")
                        end
                    elseif jackpot_server_log_to_file && jackpot_server_log_to_file then
                        local istraitor = v:IsTraitor()
                        if !isbool(tobool(istraitor)) && jackpot_developer_mode then
                            ServerLog("[JACKPOT FATAL]: Tried to log tobool(istraitor) and got tobool(istraitor) is not a bool!")
                            return;
                        end
                        if istraitor then
                            ServerLog("[" .. os.date() .. "] " .. v:Nick() .. " (TRAITOR) won " .. amount .. ".")
                            file.Append("ttt_jackpot_wins.txt", "[" .. os.date("%c", os.time()) .. "] " .. v:Nick() .. " (TRAITOR) won " .. amount .. ".\n")
                        elseif !istraitor then
                            ServerLog("[" .. os.date() .. "] " .. v:Nick() .. " (INNOCENT) won " .. amount .. ".")
                            file.Append("ttt_jackpot_wins.txt", "[" .. os.date("%c", os.time()) .. "] " .. v:Nick() .. " (INNOCENT) won " .. amount .. ".\n")
                        end
                    end
                end
            end
        elseif r == WIN_INNOCENT then
            if jackpot_developer_mode then
                for k, v in ipairs(player.GetHumans()) do
                    v:ChatPrint("WIN TYPE = WIN_INNOCENT")
                    v:ChatPrint("jackpot_last_proper_kill = " .. tostring(jackpot_last_proper_kill))
                end
            end
            if IsValid(jackpot_last_proper_kill) then
                local plys = 0
                for k, v in ipairs(player.GetHumans()) do
                    if IsValid(v) then
                        plys = plys + 1
                    end
                end
                if !jackpot_last_proper_kill:IsBot() then
                    if plys <= 8 then
                        jackpot_reward_give = jackpot_reward / 8
                    else
                        jackpot_reward_give = jackpot_reward
                    end
                    jackpot_last_proper_kill:PS_GivePoints(jackpot_reward_give)
                    jackpot_last_proper_kill:ChatPrint(prefix .. "You won " .. jackpot_reward_give .. "!")
                end
            else
                if !IsValid(jackpot_last_proper_kill) && jackpot_developer_mode then
                    for k, v in ipairs(player.GetHumans()) do
                        if IsValid(v) then
                            v:ChatPrint(prefix .. "Innocents won, but there was no valid last killer!")
                        end
                    end
                end
            end
        elseif r == WIN_TIMELIMIT then
            net.Start("jackpot_no_winner");
                net.WriteBool(tobool(jackpot_developer_mode))
            net.Broadcast()
            return;
        end
        net.Start("jackpot_over")
            net.WriteBool(tobool(jackpot_developer_mode))
        net.Broadcast()
    else return; end
end);

hook.Add("PlayerDeath", "jackpot_last_killer", function (vic, inf, kill)
    if jackpotround then
        if !IsValid(vic) or !IsValid(kill) or vic:IsBot() && !jackpot_developer_mode then return; end
        if vic:IsActiveTraitor() && !kill:IsActiveTraitor() then
            jackpot_last_proper_kill = kill
        end
    else return; end
end);

hook.Add("TTTPrepareRound", "jackpot_over", function ()
	net.Start("jackpot_over")
		net.WriteBool(tobool(jackpot_developer_mode))
	net.Broadcast()
end);

net.Receive("ttt_jackpots_info", function (_, ply)
    net.Start("ttt_jackpots_info")
        net.WriteString(tostring(jackpot_version))
        net.WriteString(tostring(jackpot_dateupdated))
        net.WriteString("https://github.com/Zero2003/TTT-Jackpots")
    net.Send(ply)
end);
