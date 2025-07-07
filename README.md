# 8Z's Dodge System

A lightweight dodging and sliding system inspired by Warhammer 40k: Darktide. No binds or extra content required!

## How to Use
**Dodging**: While moving backwards or sideways on the ground, press your jump button to perform a dodge. This behaves like a sidestep or dash, quickly moving you in the direction while providing you brief invulnerability against damage.

**Sliding**: During a dodge or while sprinting, press your crouch button to enter a slide. Sliding carries you a short distance, while giving you a chance to evade bullet damage.

Dodging and sliding both consume your dodge meter. If you run out, your dodges and slides will become less effective and provide no invulnerability. Stop dodging or sliding for a moment for it to recover.

Many details about the addon can be configured in **Utilities -> 8Z's Dodge System**.

## Developer Info

### Functions

- `DODGE_8Z:GetStamina(ply)`: Returns the current stamina of the player.
- `DODGE_8Z:TakeStamina(ply, amount)` Removes `amount` stamina from the player. Returns true if player had enough stamina, and false if not.
- `DODGE_8Z:GiveStamina(ply, amount)` Gives `amount` stamina to the player.

### Hooks

You can use hooks to programatically override things on a per-player basis, such as limiting who can dodge and how many dodges they have.

All hooks provide two arguments, the player entity and the default value. Return a value to override the ConVar setting.

- `Dodge8Z_AllowDodge` (bool)
- `Dodge8Z_AllowSlide` (bool)
- `Dodge8Z_GetDodgeSpeed` (float)
- `Dodge8Z_GetDodgeLimit` (int)
- `Dodge8Z_GetMaxStamina` (int)
- `Dodge8Z_GetStaminaRegenDelay` (float)
- `Dodge8Z_GetStaminaRegenRate` (float)
- `Dodge8Z_GetStaminaDrainRate` (float)

```lua
-- This snippet allows admins to dodge always, while other players can only dodge if 8z_dodge_enabled is set to 1.
hook.Add("Dodge8Z_AllowDodge", "admins_can_dodge", function(ply, default)
    if ply:IsAdmin() then
        return true
    end
end)

-- Scales the amount of dodges to the player's current health! Please return an integer all the time.
hook.Add("Dodge8Z_GetDodgeLimit", "admins_infinite_dodge", function(ply, default)
    return math.ceil(ply:Health() / 25)
end)
```