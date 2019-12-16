local prefix = "[JACKPOT]: "
local prefix_color = Color(150, 30, 45)
local jackpot_playcalled = false

local function jackpot_playsound(bool)
    if !bool then
        sound.Play("ambient/alarms/klaxon1.wav", LocalPlayer():GetPos(), 75, 100, 1)
        timer.Simple(1, function ()
            jackpot_playsound(true)
        end);
    else
        sound.Play("ambient/alarms/klaxon1.wav", LocalPlayer():GetPos(), 45, 100, 1)
    end
end

net.Receive("jackpot_start", function ()
    hook.Add("HUDPaint", "Jackpot_Draw", function ()
        local w = ScrW() / 2
        local h = ScrH() / 2
        draw.DrawText("JACKPOT ROUND STARTED", "CloseCaption_Bold", w, h, Color(255, 0, 0), TEXT_ALIGN_CENTER)
        if !jackpot_playcalled then
            jackpot_playcalled = true
            jackpot_playsound(false)
        end
        timer.Simple(3, function ()
            jackpot_playcalled = false
            hook.Remove("HUDPaint", "Jackpot_Draw")
        end);
    end);
    timer.Simple(3, function ()
        hook.Add("HUDPaint", "jackpot_drawcur", function ()
            local w = ScrW() / 2.3
            local h = ScrH() / 256
            local h2 = 100
            local c = 50
            for i = 1, 32 do
                draw.RoundedBox(8, w, h - h2, 300, 200, Color(c, c, c))
                h2 = h2 + 10
                c = c + 10
            end
            local h2 = 100
            local c = 175
            for i = 1, 16 do
                draw.RoundedBox(8, w + 10, h - h2, 280, 200, Color(c, c, 0))
                h2 = h2 + 10
                c = c + 10
            end
            local h2 = 100
            local c = 10
            for i = 1, 16 do
                draw.RoundedBox(8, w + 20, h - h2, 260, 200, Color(c, c, c))
                h2 = h2 + 10
                c = c + 5
            end
            draw.DrawText("JACKPOT ROUND", "DermaLarge", w + 50, h + 30, Color(200, 200, 0))
            draw.DrawText("JACKPOT ROUND", "DermaLarge", w + 48, h + 28, Color(255, 255, 0))
        end);
    end);
end);

net.Receive("jackpot_over", function ()
    local bool = net.ReadBool()
    hook.Remove("HUDPaint", "Jackpot_Draw")
    hook.Remove("HUDPaint", "jackpot_drawcur")
    if bool then
        chat.AddText(Color(40, 40, 156), prefix .. "removed Jackpot_Draw hook from HUDPaint.")
    end
end);

net.Receive("jackpot_no_winner", function ()
    local bool = net.ReadBool()
    hook.Remove("HUDPaint", "Jackpot_Draw")
    if bool then
        chat.AddText(Color(40, 40, 156), prefix .. "removed Jackpot_Draw hook from HUDPaint.")
        chat.AddText(prefix_color, prefix .. "WIN TYPE = WIN_TIMELIMIT")
    end
end);
