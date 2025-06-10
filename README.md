# 8Z's Dodge System

A lightweight dodging and sliding system inspired by Warhammer 40k: Darktide. No binds or extra content required!

## How to Use
**Dodging**: While moving backwards or sideways on the ground, press your jump button to perform a dodge. This behaves like a sidestep or dash, quickly moving you in the direction while providing you brief invulnerability against damage.

**Sliding**: During a dodge or while sprinting, press your crouch button to enter a slide. Sliding carries you a short distance, while giving you a chance to evade bullet damage.

Dodging and sliding both consume your dodge meter. If you run out, your dodges and slides will become less effective and provide no invulnerability. Stop dodging or sliding for a moment for it to recover.

Many details about the addon can be configured in **Utilities -> 8Z's Dodge System**.

## Hooks for Developers

You can use hooks to programatically override things on a per-player basis, such as limiting who can dodge and how many dodges they have. All hooks have one parameter, being the player.

As with all hooks in Garry's Mod, returning `nil` or not returning will defer to the default value.

**Dodge8Z_AllowDodge**: Whether the player can use dodge functionality. This takes priority over the ConVar setting!

**Dodge8Z_AllowSlide**: Whether the player can use slide functionality. This takes priority over the ConVar setting!

**Dodge8Z_GetDodgeLimit**: Return a number to override the dodge limit for the player.

```lua
-- This snippet allows admins to dodge always, while other players can only dodge if 8z_dodge_enabled is set to 1.
hook.Add("Dodge8Z_AllowDodge", "admins_can_dodge", function(ply)
    if ply:IsAdmin() then
        return true
    end
end)

-- Scales the amount of dodges to the player's current health! Please return an integer all the time.
hook.Add("Dodge8Z_GetDodgeLimit", "admins_infinite_dodge", function(ply)
    return math.ceil(ply:Health() / 25)
end)
```