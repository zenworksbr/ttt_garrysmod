--[[Author informations]]--
SWEP.Author = "Zaratusa"
SWEP.Contact = "http://steamcommunity.com/profiles/76561198032479768"

if SERVER then
	AddCSLuaFile()
	resource.AddWorkshop("253737302")
else
	SWEP.PrintName = "MP5"
	SWEP.Slot = 2
	SWEP.Icon = "vgui/ttt/icon_mp5"

	-- client side model settings
	SWEP.UseHands = true -- should the hands be displayed
	SWEP.ViewModelFlip = false -- should the weapon be hold with the left or the right hand
	SWEP.ViewModelFOV = 60
end

-- always derive from weapon_tttbase
SWEP.Base = "weapon_tttbase"

--[[Default GMod values]]--
SWEP.Primary.Ammo = "SMG1"
SWEP.Primary.Delay = 0.1
SWEP.Primary.Recoil	= 0.6
SWEP.Primary.Cone = 0.03
SWEP.Primary.Damage = 12
SWEP.HeadshotMultiplier = 2
SWEP.Primary.Automatic = true
SWEP.Primary.ClipSize = 30
SWEP.Primary.ClipMax = 60
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Sound = Sound("Weapon_MP5Navy.Single")

--[[Model settings]]--
SWEP.HoldType = "smg"
SWEP.ViewModel = Model("models/weapons/cstrike/c_smg_mp5.mdl")
SWEP.WorldModel = Model("models/weapons/w_smg_mp5.mdl")

SWEP.IronSightsPos = Vector(-5.32, -10, 1.6)
SWEP.IronSightsAng = Vector(2.2, 0, 0)

SWEP.NoSights = false

--[[TTT config values]]--

-- Kind specifies the category this weapon is in. Players can only carry one of
-- each. Can be: WEAPON_... MELEE, PISTOL, HEAVY, NADE, CARRY, EQUIP1, EQUIP2 or ROLE.
-- Matching SWEP.Slot values: 0      1       2     3      4      6       7        8
SWEP.Kind = WEAPON_HEAVY

-- If AutoSpawnable is true and SWEP.Kind is not WEAPON_EQUIP1/2,
-- then this gun can be spawned as a random weapon.
SWEP.AutoSpawnable = true

-- The AmmoEnt is the ammo entity that can be picked up when carrying this gun.
SWEP.AmmoEnt = "item_ammo_smg1_ttt"

-- If AllowDrop is false, players can't manually drop the gun with Q
SWEP.AllowDrop = true

-- If IsSilent is true, victims will not scream upon death.
SWEP.IsSilent = false