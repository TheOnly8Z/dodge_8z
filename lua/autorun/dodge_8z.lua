local cvar_enable = CreateConVar("8z_dodge_enabled", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY, "Enable 8Z's Dodge System for all players.", 0, 1)
local cvar_speed = CreateConVar("8z_dodge_speed", "500", FCVAR_ARCHIVE + FCVAR_REPLICATED, "How fast the dodge moves the player.", 0)
local cvar_duration = CreateConVar("8z_dodge_duration", "0.1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "How long the dodge lasts.", 0)
local cvar_cooldown = CreateConVar("8z_dodge_cooldown", "0.5", FCVAR_ARCHIVE + FCVAR_REPLICATED, "How long must the player wait between dodges. Does not count dodge duration.", 0)
local cvar_sprint = CreateConVar("8z_dodge_sprint", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Allow dodge while sprinting.", 0, 1)
local cvar_sprint_boost = CreateConVar("8z_dodge_sprint_boost", "0.2", FCVAR_ARCHIVE + FCVAR_REPLICATED, "While sprinting into a dodge or slide, boost speed by this amount.", 0)
local cvar_forwardstrafe = CreateConVar("8z_dodge_forwardstrafe", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Controls what happens when you attempt a dodge while holding forward and a strafe direction. 0 - No dodge; 1 - sideways dodge; 2 - dodge forwards.", 0, 2)
local cvar_sound = CreateConVar("8z_dodge_sound", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Play dodge sounds.", 0, 1)

local cvar_limit = CreateConVar("8z_dodge_limit", "4", FCVAR_ARCHIVE + FCVAR_REPLICATED, "The amount of dodges a player can perform before dodges start losing effectiveness, reducing speed and losing its invulnerability effect. Set to 0 for no limit.", 0)
local cvar_reset = CreateConVar("8z_dodge_reset", "0.85", FCVAR_ARCHIVE + FCVAR_REPLICATED, "If no dodges are performed within this amount of time, the dodge limit is reset.", 0)

local cvar_invuln_player = CreateConVar("8z_dodge_invuln_player", "0", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Damage invulnerability also applies to player sources. Damage type settings still apply.", 0, 1)

local cvar_invuln_grace = CreateConVar("8z_dodge_invuln_grace", "0.1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Additional grace time after a dodge that still applies invulnerability.", 0)
local cvar_invuln_melee = CreateConVar("8z_dodge_invuln_melee", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "While dodging, immune to non-player melee damage (DMG_GENERIC, DMG_SLASH, DMG_CLUB).", 0, 1)
local cvar_invuln_bullet = CreateConVar("8z_dodge_invuln_bullet", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "While dodging, immune to non-player bullet damage (DMG_BULLET, DMG_BUCKSHOT, DMG_SNIPER).", 0, 1)
local cvar_invuln_all = CreateConVar("8z_dodge_invuln_all", "0", FCVAR_ARCHIVE + FCVAR_REPLICATED, "While dodging, immune to all non-player damage. Takes priority over the other invulnerability options.", 0, 1)
local cvar_invuln_chance = CreateConVar("8z_dodge_invuln_chance", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "While dodging, fractional chance to avoid an instance of damage (1 = 100%). The relevant damage type ConVar must also be enabled.", 0, 1)

local cvar_slide = CreateConVar("8z_dodge_slide", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Crouch after a dodge to enter a slide, retaining dodge speed for a moment.", 0, 1)
local cvar_slide_sound = CreateConVar("8z_dodge_slide_sound", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Play sliding sounds.", 0, 1)
local cvar_slide_fromsprint = CreateConVar("8z_dodge_slide_fromsprint", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Allow entering slide while sprinting.", 0, 1)
local cvar_slide_duration = CreateConVar("8z_dodge_slide_duration", "0.3", FCVAR_ARCHIVE + FCVAR_REPLICATED, "How long can the dodge slide last.", 0)
local cvar_slide_invuln_melee = CreateConVar("8z_dodge_slide_invuln_melee", "0", FCVAR_ARCHIVE + FCVAR_REPLICATED, "While dodge sliding, immune to non-player melee damage (DMG_GENERIC, DMG_SLASH, DMG_CLUB).", 0, 1)
local cvar_slide_invuln_bullet = CreateConVar("8z_dodge_slide_invuln_bullet", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "While dodge sliding, immune to non-player bullet damage (DMG_BULLET, DMG_BUCKSHOT, DMG_SNIPER).", 0, 1)
local cvar_slide_invuln_all = CreateConVar("8z_dodge_slide_invuln_all", "0", FCVAR_ARCHIVE + FCVAR_REPLICATED, "While dodge sliding, immune to all non-player damage. Takes priority over the other invulnerability options.", 0, 1)
local cvar_slide_invuln_chance = CreateConVar("8z_dodge_slide_invuln_chance", "0.5", FCVAR_ARCHIVE + FCVAR_REPLICATED, "While dodge sliding, fractional chance to avoid an instance of damage (1 = 100%). The relevant damage type ConVar must also be enabled.", 0, 1)

local cvar_hud = CreateConVar("8z_dodge_hud", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Allow clients to use the dodge HUD. If disabled, clients cannot see the HUD even if they turn it on.", 0, 1)


hook.Add("SetupMove", "dodge_8z", function(ply, mv, cmd)
    if not cvar_enable:GetBool() then return end

    if IsFirstTimePredicted() and ply:Alive() and ply:OnGround() and ply:GetMoveType() == MOVETYPE_WALK
            and ply:GetNW2Float("Dodge8Z_Next", 0) <= CurTime()
            and ply:GetNW2Float("Dodge8Z_Slide", 0) <= CurTime() then

        -- Start a dodge
        if cvar_enable:GetBool() and not ply:Crouching()
                and cmd:KeyDown(IN_JUMP) and not ply:GetNW2Bool("Dodge8Z_BlockJump", false)
                and (cvar_sprint:GetBool() or not cmd:KeyDown(IN_SPEED))
                and (cvar_forwardstrafe:GetInt() ~= 0 or cmd:GetForwardMove() <= 0)
                and (cmd:GetForwardMove() < 0 or cmd:GetSideMove() ~= 0) then

            -- If a dodge is inputted while fully out of dodges, jump is still blocked
            if (cvar_limit:GetInt() == 0 or ply:GetNW2Int("Dodge8Z_Count", 0) < cvar_limit:GetInt() * 2) then
                -- Not hard-coding IN_ enums for movement keys for controllers' sake
                local fmove = cmd:GetForwardMove()
                if cvar_forwardstrafe:GetInt() == 1 then
                    fmove = math.min(0, cmd:GetForwardMove())
                end
                ply:SetNW2Vector("Dodge8Z_Dir", (ply:GetForward() * fmove + ply:GetRight() * cmd:GetSideMove()):GetNormalized())
                ply:SetNW2Float("Dodge8Z_Active", CurTime() + cvar_duration:GetFloat())
                ply:SetNW2Float("Dodge8Z_Next", CurTime() + math.max(cvar_duration:GetFloat(), cvar_cooldown:GetFloat()))
                ply:SetNW2Int("Dodge8Z_Count", ply:GetNW2Int("Dodge8Z_Count", 0) + 1)
                if cvar_limit:GetInt() == 0 or ply:GetNW2Int("Dodge8Z_Count", 0) <= cvar_limit:GetInt() then
                    ply:SetNW2Float("Dodge8Z_Invuln", CurTime() + cvar_duration:GetFloat() + cvar_invuln_grace:GetFloat())
                end
                if ply:GetInfoNum("cl_8z_dodge_viewpunch", 1) == 1 then
                    ply:ViewPunch(Angle(math.Clamp(cmd:GetForwardMove(), -1, 0) * 1, 0, math.Clamp(cmd:GetSideMove(), -1, 1) * 1))
                end
                if cvar_sound:GetBool() then
                    ply:EmitSound("player/suit_sprint.wav", 70, cvar_limit:GetInt() == 0 and 100 or Lerp(ply:GetNW2Int("Dodge8Z_Count", 0)  / (cvar_limit:GetInt() * 2), 100, 90), 1, CHAN_AUTO)
                end
            else
                if cvar_sound:GetBool() then
                    ply:EmitSound("player/suit_sprint.wav", 70, 85, 1, CHAN_AUTO)
                end
                ply:SetNW2Float("Dodge8Z_Next", CurTime() + 0.5)
            end

            -- Block the jump attempt
            ply:SetNW2Bool("Dodge8Z_BlockJump", true)
            mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))

        -- Sprint into slide
        elseif cvar_slide:GetBool() and cvar_slide_fromsprint:GetBool() and cmd:KeyDown(IN_SPEED)
                and (cmd:GetForwardMove() ~= 0 or cmd:GetSideMove() ~= 0) and mv:KeyPressed(IN_DUCK) and ply:GetVelocity():LengthSqr() >= 1000
                and (cvar_limit:GetInt() == 0 or ply:GetNW2Int("Dodge8Z_Count", 0) < cvar_limit:GetInt() * 2) then
            ply:SetNW2Vector("Dodge8Z_Dir", (ply:GetForward() * cmd:GetForwardMove() + ply:GetRight() * cmd:GetSideMove()):GetNormalized())
            ply:SetNW2Float("Dodge8Z_Next", CurTime() + cvar_slide_duration:GetFloat() * (1 + cvar_sprint_boost:GetFloat()) + 0.1)
            ply:SetNW2Float("Dodge8Z_Slide", CurTime() + cvar_slide_duration:GetFloat() * (1 + cvar_sprint_boost:GetFloat()))
            ply:SetNW2Float("Dodge8Z_SlideSpeed", math.max(ply:GetWalkSpeed(), ply:GetNW2Vector("Dodge8Z_Dir"):Dot(ply:GetVelocity())) * (1 + cvar_sprint_boost:GetFloat()))
            ply:SetNW2Int("Dodge8Z_Count", ply:GetNW2Int("Dodge8Z_Count", 0) + 1)
            if cvar_slide_sound:GetBool() then
                ply.Dodge8Z_SlideSound = CreateSound(ply, "physics/body/body_medium_scrape_smooth_loop1.wav")
                ply.Dodge8Z_SlideSound:PlayEx(0.5, 110)
                ply.Dodge8Z_SlideSound:ChangePitch(90, cvar_slide_duration:GetFloat())
                ply:EmitSound("physics/body/body_medium_impact_soft6.wav", 70, 105, 1, CHAN_AUTO)
            end
            if ply:GetInfoNum("cl_8z_dodge_viewpunch", 1) == 1 then
                ply:ViewPunch(Angle(math.Clamp(cmd:GetForwardMove(), -1, 1) * -2, 0, math.Clamp(cmd:GetSideMove(), -1, 1) * -3))
            end
        end
    end

    if ply:Alive() and ply:OnGround() and mv:KeyDown(IN_JUMP) and ply:GetNW2Float("Dodge8Z_Next", 0) > CurTime() and ply:GetInfoNum("cl_8z_dodge_blockjump", 0) == 1 then
        mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))
    end

    -- After a dodge is inputted, jumping is blocked until space is released
    if ply:GetNW2Bool("Dodge8Z_BlockJump") and (not cmd:KeyDown(IN_JUMP) or ply:GetMoveType() ~= MOVETYPE_WALK) then
        ply:SetNW2Bool("Dodge8Z_BlockJump", false)
    end

    -- During a dodge, cannot move or jump
    if ply:GetNW2Float("Dodge8Z_Active", 0) > CurTime() then
        mv:SetForwardSpeed(0)
        mv:SetSideSpeed(0)
        mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP + IN_DUCK)))
    elseif ply:GetNW2Bool("Dodge8Z_BlockJump") then
        mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))
    elseif ply:GetNW2Float("Dodge8Z_Slide", 0) > CurTime() then
        -- Forced crouch while dodge sliding
        mv:SetButtons(bit.bor(mv:GetButtons(), IN_DUCK))
        mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))
    end

    -- Dodge reset
    if ply:GetNW2Int("Dodge8Z_Count", 0) > 0 and CurTime() - ply:GetNW2Float("Dodge8Z_Next", 0) > cvar_reset:GetFloat() then
        ply:SetNW2Int("Dodge8Z_Count", 0)
    end
end)

hook.Add("Move", "dodge_8z", function(ply, mv)
    local active = ply:GetNW2Float("Dodge8Z_Active", 0)
    local slide = ply:GetNW2Float("Dodge8Z_Slide", 0)
    local count = ply:GetNW2Int("Dodge8Z_Count", 0)
    if active > CurTime() then
        if not ply:Alive() or not ply:OnGround() or ply:GetMoveType() ~= MOVETYPE_WALK then
            ply:SetNW2Float("Dodge8Z_Active", 0)
            ply:SetNW2Float("Dodge8Z_Invuln", 0)
            -- Prevent dash velocity from launching players off cliffs too fast
            if not ply:OnGround() and ply:GetMoveType() == MOVETYPE_WALK then
                mv:SetVelocity(mv:GetVelocity() * 0.5)
            end
            return
        end

        local speed = cvar_speed:GetFloat()
        if cvar_sprint:GetBool() and ply:KeyDown(IN_SPEED) then
            speed = speed * (1 + cvar_sprint_boost:GetFloat())
        end
        local limit = cvar_limit:GetInt()
        if limit > 0 and (count > limit) then
            speed = speed * Lerp((count - limit) / limit, 1, 0.5)
        end

        mv:SetVelocity(ply:GetNW2Vector("Dodge8Z_Dir") * speed) --Lerp((active - CurTime()) / (cvar_duration:GetFloat() / 2), mv:KeyDown(IN_SPEED) and ply:GetRunSpeed() or ply:GetWalkSpeed(), cvar_speed:GetFloat()))
        ply:SetNW2Float("Dodge8Z_SlideSpeed", speed)
    elseif slide > CurTime() then
        if not ply:Alive() or not ply:OnGround() or ply:GetMoveType() ~= MOVETYPE_WALK then
            ply:SetNW2Float("Dodge8Z_Slide", 0)
            ply:SetNW2Float("Dodge8Z_Next", math.max(ply:GetNW2Float("Dodge8Z_Next", 0), CurTime() + 0.1))
            if ply.Dodge8Z_SlideSound then
                ply.Dodge8Z_SlideSound:Stop()
                ply.Dodge8Z_SlideSound = nil
            end
            return
        end

        mv:SetVelocity(ply:GetNW2Vector("Dodge8Z_Dir") * Lerp(((slide - CurTime()) / cvar_slide_duration:GetFloat()) ^ 0.5, ply:GetCrouchedWalkSpeed() * ply:GetWalkSpeed(), ply:GetNW2Float("Dodge8Z_SlideSpeed")))
    elseif active > 0 and IsFirstTimePredicted() then
        if cvar_slide:GetBool() and mv:KeyDown(IN_DUCK) then
            ply:SetNW2Float("Dodge8Z_Slide", CurTime() + cvar_slide_duration:GetFloat())
            ply:SetNW2Int("Dodge8Z_Count", count + 1)
            if cvar_slide_sound:GetBool() then
                ply.Dodge8Z_SlideSound = CreateSound(ply, "physics/body/body_medium_scrape_smooth_loop1.wav")
                ply.Dodge8Z_SlideSound:PlayEx(0.5, 110)
                ply.Dodge8Z_SlideSound:ChangePitch(90, cvar_slide_duration:GetFloat())
                ply:EmitSound("physics/body/body_medium_impact_soft6.wav", 70, 105, 1, CHAN_AUTO)
            end
            if ply:GetInfoNum("cl_8z_dodge_viewpunch", 1) == 1 then
                ply:ViewPunch(Angle(ply:GetNW2Vector("Dodge8Z_Dir").x * -2, 0, ply:GetNW2Vector("Dodge8Z_Dir").z * -3))
            end
        end
        ply:SetNW2Float("Dodge8Z_Active", 0)
    elseif slide > 0 then
        ply:SetNW2Float("Dodge8Z_Slide", 0)
        ply:SetNW2Float("Dodge8Z_Next", math.max(ply:GetNW2Float("Dodge8Z_Next", 0), CurTime() + 0.1))
        if ply.Dodge8Z_SlideSound then
            ply.Dodge8Z_SlideSound:Stop()
            ply.Dodge8Z_SlideSound = nil
        end
    end
end)

local dodge_sounds = {
    "weapons/fx/nearmiss/bulletltor03.wav",
    "weapons/fx/nearmiss/bulletltor04.wav",
    "weapons/fx/nearmiss/bulletltor05.wav",
    "weapons/fx/nearmiss/bulletltor06.wav",
    "weapons/fx/nearmiss/bulletltor07.wav",
    "weapons/fx/nearmiss/bulletltor09.wav",
    "weapons/fx/nearmiss/bulletltor10.wav",
    "weapons/fx/nearmiss/bulletltor11.wav",
    "weapons/fx/nearmiss/bulletltor12.wav",
    "weapons/fx/nearmiss/bulletltor13.wav",
    "weapons/fx/nearmiss/bulletltor14.wav",
}
hook.Add("EntityTakeDamage", "dodge_8z", function(ply, dmginfo)
    if ply:IsPlayer() and ply:GetNW2Float("Dodge8Z_Invuln", 0) > CurTime()
        and (not IsValid(dmginfo:GetAttacker()) or not dmginfo:GetAttacker():IsPlayer() or cvar_invuln_player:GetBool()) and
        math.random() < cvar_invuln_chance:GetFloat() and (
        cvar_invuln_all:GetBool() or
        (cvar_invuln_melee:GetBool() and (dmginfo:GetDamageType() == 0 or dmginfo:IsDamageType(DMG_CLUB) or dmginfo:IsDamageType(DMG_SLASH))) or
        (cvar_invuln_bullet:GetBool() and (dmginfo:IsDamageType(DMG_BULLET) or dmginfo:IsDamageType(DMG_BUCKSHOT) or dmginfo:IsDamageType(DMG_SNIPER)))
        ) then
        ply:EmitSound(dodge_sounds[math.random(1, #dodge_sounds)], 70, math.Rand(97, 103), 1, CHAN_AUTO)
        return true
    end

    if ply:IsPlayer() and ply:GetNW2Float("Dodge8Z_Slide", 0) > CurTime()
        and (not IsValid(dmginfo:GetAttacker()) or not dmginfo:GetAttacker():IsPlayer() or cvar_invuln_player:GetBool()) and
        math.random() < cvar_slide_invuln_chance:GetFloat() and (
        cvar_slide_invuln_all:GetBool() or
        (cvar_slide_invuln_melee:GetBool() and (dmginfo:GetDamageType() == 0 or dmginfo:IsDamageType(DMG_CLUB) or dmginfo:IsDamageType(DMG_SLASH))) or
        (cvar_slide_invuln_bullet:GetBool() and (dmginfo:IsDamageType(DMG_BULLET) or dmginfo:IsDamageType(DMG_BUCKSHOT) or dmginfo:IsDamageType(DMG_SNIPER)))
        ) then
        ply:EmitSound(dodge_sounds[math.random(1, #dodge_sounds)], 70, math.Rand(97, 103), 1, CHAN_AUTO)
        return true
    end
end)

if CLIENT then
    local ccvar_hud = CreateClientConVar("cl_8z_dodge_hud", "1", true, false, "Enable the dodge HUD. It won't show up if there is no dodge limit.", 0, 1)
    local ccvar_hud_alwayson = CreateClientConVar("cl_8z_dodge_hud_alwayson", "0", true, false, "Make the HUD always visible.", 0)
    local ccvar_hud_x = CreateClientConVar("cl_8z_dodge_hud_x", "0.5", true, false, "Horizontal position of the HUD, as a fraction of screen width.", 0, 1)
    local ccvar_hud_y = CreateClientConVar("cl_8z_dodge_hud_y", "0.65", true, false, "Vertical position of the HUD, as a fraction of screen height.", 0, 1)
    local ccvar_hud_w = CreateClientConVar("cl_8z_dodge_hud_w", "256", true, false, "Width of the HUD element in pixels.", 0)
    local ccvar_hud_h = CreateClientConVar("cl_8z_dodge_hud_h", "12", true, false, "Height of the HUD element in pixels.", 0)
    local ccvar_hud_a = CreateClientConVar("cl_8z_dodge_hud_alpha", "1", true, false, "Opaqueness of the HUD element, as a fraction.", 0, 1)
    local ccvar_hud_textpos = CreateClientConVar("cl_8z_dodge_hud_textpos", "0", true, false, "Move the numeric counter to the left and the 'DODGES' text to the right.", 0, 1)
    local ccvar_hud_shadow = CreateClientConVar("cl_8z_dodge_hud_shadow", "1", true, false, "Enable black shadows on the main UI. Does not affect the text", 0, 1)

    CreateClientConVar("cl_8z_dodge_viewpunch", "1", true, true, "Apply viewpunch when dodging and sliding (camera pitch/tilt).", 0, 1)
    CreateClientConVar("cl_8z_dodge_blockjump", "0", true, true, "Disable sideways/backwards jump to prevent accidently jumping while spamming dodge.", 0, 1)

    DODGE_8Z_COLORS = {}
    DODGE_8Z_COLORS.main = Color(150, 220, 150, 255)
    DODGE_8Z_COLORS.bar = Color(200, 250, 200, 255)
    DODGE_8Z_COLORS.empty = Color(80, 80, 80, 255)
    DODGE_8Z_COLORS.missing = Color(220, 120, 120, 255)

    local function colorccvars(name, clr_key, alpha, helptext)
        local clr = DODGE_8Z_COLORS[clr_key]
        local cvar_r = CreateClientConVar(name .. "_r", clr and clr.r or "255", true, false, helptext and (helptext .. " (Red component)") or "", 0, 255)
        local cvar_g = CreateClientConVar(name .. "_g", clr and clr.g or "255", true, false, helptext and (helptext .. " (Green component)") or "", 0, 255)
        local cvar_b = CreateClientConVar(name .. "_b", clr and clr.b or "255", true, false, helptext and (helptext .. " (Blue component)") or "", 0, 255)
        local cvar_a
        if alpha then
            cvar_a = CreateClientConVar(name .. "_a", clr and clr.a or "255", true, false, helptext and (helptext .. " (Alpha component)") or "", 0, 255)
        end
        if alpha then
            DODGE_8Z_COLORS[clr_key] = Color(cvar_r:GetInt(), cvar_g:GetInt(), cvar_b:GetInt(), cvar_a:GetInt())
        else
            DODGE_8Z_COLORS[clr_key] = Color(cvar_r:GetInt(), cvar_g:GetInt(), cvar_b:GetInt())
        end
    end

    local function getcolorcvar(name)
        local cvar_r = GetConVar(name .. "_r")
        local cvar_g = GetConVar(name .. "_g")
        local cvar_b = GetConVar(name .. "_b")
        local cvar_a = GetConVar(name .. "_a")
        if cvar_a then
            return Color(cvar_r:GetInt(), cvar_g:GetInt(), cvar_b:GetInt(), cvar_a:GetInt())
        else
            return Color(cvar_r:GetInt(), cvar_g:GetInt(), cvar_b:GetInt())
        end
    end

    local function resetcolorcvar(name)
        GetConVar(name .. "_r"):Revert()
        GetConVar(name .. "_g"):Revert()
        GetConVar(name .. "_b"):Revert()
        local cvar_a = GetConVar(name .. "_a")
        if cvar_a then
            cvar_a:Revert()
        end
    end


    colorccvars("cl_8z_dodge_color_main", "main", false, "The color for the frame and text.")
    colorccvars("cl_8z_dodge_color_bar", "bar", false, "The color for unspent dodge bars.")
    colorccvars("cl_8z_dodge_color_empty", "empty", false, "The color for spent dodge bars.")
    colorccvars("cl_8z_dodge_color_missing", "missing", false, "The color for negative dodge bars.")

    local function draw_dodge_bar(x, y, w, h)
        local t = 2
        local total = cvar_limit:GetInt()
        local count = LocalPlayer():GetNW2Int("Dodge8Z_Count", 0)
        local bars = total - count
        local wbar = math.Round(w / total)

        if ccvar_hud_shadow:GetBool() then
            surface.SetDrawColor(color_black)
            surface.DrawRect(x - w / 2 - t * 2 + 1, y + h + t * 2, w + t * 4, 1)
            surface.DrawRect(x - w / 2 - t * 1, y + h / 2 + 1, 1, h / 2 + t - 1)
            surface.DrawRect(x + w / 2 + t * 2, y + h / 2 + 1, 1, h / 2 + t * 2 - 1)
        end

        surface.SetDrawColor(DODGE_8Z_COLORS.main)
        surface.DrawRect(x - w / 2 - t * 2, y + h + t, w + t * 4, t)
        surface.DrawRect(x - w / 2 - t * 2, y + h / 2, t, h / 2 + t)
        surface.DrawRect(x + w / 2 + t, y + h / 2, t, h / 2 + t)


        surface.SetFont("TargetID")
        surface.SetTextColor(DODGE_8Z_COLORS.main)
        local txt = language.GetPhrase("#dodge_8z.ui.dodges")
        if ccvar_hud_textpos:GetBool() then
            local tw = surface.GetTextSize(txt)
            surface.SetTextPos(x + w / 2 - tw, y + h + t * 2)
        else
            surface.SetTextPos(x - w / 2, y + h + t * 2)
        end
            surface.DrawText(txt)

        if bars <= 0 then
            surface.SetTextColor(DODGE_8Z_COLORS.missing)
        end
        if ccvar_hud_textpos:GetBool() then
            surface.SetTextPos(x - w / 2, y + h + t * 2)
        else
            local tw = surface.GetTextSize(bars)
            surface.SetTextPos(x + w / 2 - tw, y + h + t * 2)
        end
        surface.DrawText(bars)

        for i = 1, total do
            if bars >= i then
                surface.SetDrawColor(DODGE_8Z_COLORS.bar)
            elseif bars < 0 and bars + total <= (total - i) then
                surface.SetDrawColor(DODGE_8Z_COLORS.missing)
            else
                surface.SetDrawColor(DODGE_8Z_COLORS.empty)
            end
            surface.DrawRect(x - w / 2 + w * (i - 1) / total + t / 2, y, wbar - t, h)
        end
    end

    local last_value = 0
    local last_value_t = 0
    local a = 0
    hook.Add("HUDPaint", "dodge_8z", function()
        if not ply:Alive() or not cvar_hud:GetBool() or not ccvar_hud:GetBool() or cvar_limit:GetInt() == 0 then return end

        if last_value ~= LocalPlayer():GetNW2Int("Dodge8Z_Count", 0) then
            last_value = LocalPlayer():GetNW2Int("Dodge8Z_Count", 0)
            last_value_t = SysTime()
            a = 1
        end

        local dt = SysTime() - last_value_t
        if last_value == 0 and dt > 1.5 then
            a = math.Approach(a, 0, RealFrameTime() * 2)
        end

        local am = surface.GetAlphaMultiplier()
        surface.SetAlphaMultiplier((ccvar_hud_alwayson:GetBool() and 1 or a) * ccvar_hud_a:GetFloat())
        draw_dodge_bar(ScrW() * ccvar_hud_x:GetFloat(), ScrH() * ccvar_hud_y:GetFloat(), ccvar_hud_w:GetInt(), ccvar_hud_h:GetInt())
        surface.SetAlphaMultiplier(am)
    end)

    hook.Add("AddToolMenuCategories", "dodge_8z", function()
        spawnmenu.AddToolCategory("Utilities", "Dodge8Z", "#dodge_8z")
    end)

    hook.Add( "PopulateToolMenu", "dodge_8z", function()
        spawnmenu.AddToolMenuOption( "Utilities", "Dodge8Z", "Dodge8Z_Server", "#dodge_8z.server", "", "", function( panel )
            local t = panel:Help("#dodge_8z.category.dodge")
            t:SetFont("DermaDefaultBold")

            panel:ControlHelp("#dodge_8z.help.dodge")

            panel:CheckBox("#dodge_8z.enable", "8z_dodge_enabled")
            panel:NumSlider("#dodge_8z.speed", "8z_dodge_speed", 0, 2000, 0)
            panel:NumSlider("#dodge_8z.duration", "8z_dodge_duration", 0, 0.5, 2)
            panel:NumSlider("#dodge_8z.cooldown", "8z_dodge_cooldown", 0, 2, 2)
            panel:CheckBox("#dodge_8z.sound", "8z_dodge_sound")

            panel:NumSlider("#dodge_8z.invuln_chance", "8z_dodge_invuln_chance", 0, 1, 2)
            panel:CheckBox("#dodge_8z.invuln_all", "8z_dodge_invuln_all")
            panel:CheckBox("#dodge_8z.invuln_melee", "8z_dodge_invuln_melee")
            panel:CheckBox("#dodge_8z.invuln_bullet", "8z_dodge_invuln_bullet")

            t = panel:Help("#dodge_8z.category.slide")
            t:SetFont("DermaDefaultBold")

            panel:ControlHelp("#dodge_8z.help.slide")

            panel:CheckBox("#dodge_8z.enable", "8z_dodge_slide")
            panel:NumSlider("#dodge_8z.duration", "8z_dodge_slide_duration", 0, 1, 2)
            panel:CheckBox("#dodge_8z.cvar.slide_fromsprint", "8z_dodge_slide_fromsprint")
            panel:ControlHelp("#dodge_8z.desc.slide_fromsprint")
            panel:CheckBox("#dodge_8z.sound", "8z_dodge_slide_sound")

            panel:NumSlider("#dodge_8z.invuln_chance", "8z_dodge_slide_invuln_chance", 0, 1, 2)
            panel:CheckBox("#dodge_8z.invuln_all", "8z_dodge_slide_invuln_all")
            panel:CheckBox("#dodge_8z.invuln_melee", "8z_dodge_slide_invuln_melee")
            panel:CheckBox("#dodge_8z.invuln_bullet", "8z_dodge_slide_invuln_bullet")

            t = panel:Help("#dodge_8z.category.invuln")
            t:SetFont("DermaDefaultBold")

            panel:CheckBox("#dodge_8z.cvar.invuln_player", "8z_dodge_invuln_player")
            panel:ControlHelp("#dodge_8z.desc.invuln_player")
            panel:NumSlider("#dodge_8z.cvar.invuln_grace", "8z_dodge_invuln_grace", 0, 0.25, 2)
            panel:ControlHelp("#dodge_8z.desc.invuln_grace")

            t = panel:Help("#dodge_8z.category.advanced")
            t:SetFont("DermaDefaultBold")

            panel:CheckBox("#dodge_8z.cvar.hud", "8z_dodge_hud")
            panel:ControlHelp("#dodge_8z.desc.hud")

            panel:CheckBox("#dodge_8z.cvar.sprint", "8z_dodge_sprint")
            panel:NumSlider("#dodge_8z.cvar.sprint_boost", "8z_dodge_sprint_boost", 0, 1, 2)
            panel:ControlHelp("#dodge_8z.desc.sprint_boost")

            panel:NumSlider("#dodge_8z.cvar.limit", "8z_dodge_limit", 0, 10, 0)
            panel:ControlHelp("#dodge_8z.desc.limit")

            panel:NumSlider("#dodge_8z.cvar.reset", "8z_dodge_reset", 0, 2, 2)
            panel:ControlHelp("#dodge_8z.desc.reset")

            local cb = panel:ComboBox("#dodge_8z.cvar.forwardstrafe", "8z_dodge_forwardstrafe")
            cb:AddChoice("#dodge_8z.cvar.forwardstrafe.0", 0, cvar_forwardstrafe:GetInt() == 0)
            cb:AddChoice("#dodge_8z.cvar.forwardstrafe.1", 1, cvar_forwardstrafe:GetInt() == 1)
            cb:AddChoice("#dodge_8z.cvar.forwardstrafe.2", 2, cvar_forwardstrafe:GetInt() == 2)
            panel:ControlHelp("#dodge_8z.desc.forwardstrafe")

        end )

        spawnmenu.AddToolMenuOption( "Utilities", "Dodge8Z", "Dodge8Z_Client", "#dodge_8z.client", "", "", function( panel )

            local t = panel:Help("#dodge_8z.category.preferences")
            t:SetFont("DermaDefaultBold")

            panel:CheckBox("#dodge_8z.cvar.viewpunch", "cl_8z_dodge_viewpunch")
            panel:CheckBox("#dodge_8z.cvar.blockjump", "cl_8z_dodge_blockjump")
            panel:ControlHelp("#dodge_8z.desc.blockjump")

            t = panel:Help("#dodge_8z.category.hud")
            t:SetFont("DermaDefaultBold")

            panel:CheckBox("#dodge_8z.cvar.hud", "cl_8z_dodge_hud")
            panel:CheckBox("#dodge_8z.cvar.hud_alwayson", "cl_8z_dodge_hud_alwayson")
            panel:CheckBox("#dodge_8z.cvar.hud_textpos", "cl_8z_dodge_hud_textpos")
            panel:CheckBox("#dodge_8z.cvar.hud_shadow", "cl_8z_dodge_hud_shadow")
            panel:NumSlider("#dodge_8z.cvar.hud_x", "cl_8z_dodge_hud_x", 0, 1, 2)
            panel:NumSlider("#dodge_8z.cvar.hud_y", "cl_8z_dodge_hud_y", 0, 1, 2)
            panel:NumSlider("#dodge_8z.cvar.hud_w", "cl_8z_dodge_hud_w", 0, 1024, 0)
            panel:NumSlider("#dodge_8z.cvar.hud_h", "cl_8z_dodge_hud_h", 0, 64, 0)
            panel:NumSlider("#dodge_8z.cvar.hud_alpha", "cl_8z_dodge_hud_alpha", 0, 1, 2)

            t = panel:Help("#dodge_8z.category.colors")
            t:SetFont("DermaDefaultBold")

            local btn = panel:Button("#dodge_8z.apply")
            btn.DoClick = function(self2)
                DODGE_8Z_COLORS.main = getcolorcvar("cl_8z_dodge_color_main")
                DODGE_8Z_COLORS.bar = getcolorcvar("cl_8z_dodge_color_bar")
                DODGE_8Z_COLORS.empty = getcolorcvar("cl_8z_dodge_color_empty")
                DODGE_8Z_COLORS.missing = getcolorcvar("cl_8z_dodge_color_missing")
            end

            btn = panel:Button("#dodge_8z.reset")
            btn.DoClick = function(self2)
                resetcolorcvar("cl_8z_dodge_color_main")
                resetcolorcvar("cl_8z_dodge_color_bar")
                resetcolorcvar("cl_8z_dodge_color_empty")
                resetcolorcvar("cl_8z_dodge_color_missing")
                DODGE_8Z_COLORS.main = getcolorcvar("cl_8z_dodge_color_main")
                DODGE_8Z_COLORS.bar = getcolorcvar("cl_8z_dodge_color_bar")
                DODGE_8Z_COLORS.empty = getcolorcvar("cl_8z_dodge_color_empty")
                DODGE_8Z_COLORS.missing = getcolorcvar("cl_8z_dodge_color_missing")
            end

            local cmixer = vgui.Create("DColorMixer")
            cmixer:SetAlphaBar(false)
            cmixer:SetLabel("#dodge_8z.cvar.color_main")
            cmixer:SetConVarR("cl_8z_dodge_color_main_r")
            cmixer:SetConVarG("cl_8z_dodge_color_main_g")
            cmixer:SetConVarB("cl_8z_dodge_color_main_b")
            panel:AddItem(cmixer)

            cmixer = vgui.Create("DColorMixer")
            cmixer:SetAlphaBar(false)
            cmixer:SetLabel("#dodge_8z.cvar.color_bar")
            cmixer:SetConVarR("cl_8z_dodge_color_bar_r")
            cmixer:SetConVarG("cl_8z_dodge_color_bar_g")
            cmixer:SetConVarB("cl_8z_dodge_color_bar_b")
            panel:AddItem(cmixer)

            cmixer = vgui.Create("DColorMixer")
            cmixer:SetAlphaBar(false)
            cmixer:SetLabel("#dodge_8z.cvar.color_empty")
            cmixer:SetConVarR("cl_8z_dodge_color_empty_r")
            cmixer:SetConVarG("cl_8z_dodge_color_empty_g")
            cmixer:SetConVarB("cl_8z_dodge_color_empty_b")
            panel:AddItem(cmixer)

            cmixer = vgui.Create("DColorMixer")
            cmixer:SetAlphaBar(false)
            cmixer:SetLabel("#dodge_8z.cvar.color_missing")
            cmixer:SetConVarR("cl_8z_dodge_color_missing_r")
            cmixer:SetConVarG("cl_8z_dodge_color_missing_g")
            cmixer:SetConVarB("cl_8z_dodge_color_missing_b")
            panel:AddItem(cmixer)
        end )
    end )
end