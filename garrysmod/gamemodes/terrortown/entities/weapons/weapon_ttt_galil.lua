--[[Author informations]]--
SWEP.Author = "Zaratusa"
SWEP.Contact = "http://steamcommunity.com/profiles/76561198032479768"

if SERVER then
	AddCSLuaFile()
	resource.AddWorkshop("253736902")
else
	SWEP.PrintName = "Galil"
	SWEP.Slot = 2
	SWEP.Icon = "vgui/ttt/icon_galil"

	-- client side model settings
	SWEP.UseHands = true -- should the hands be displayed
	SWEP.ViewModelFlip = false -- should the weapon be hold with the left or the right hand
	SWEP.ViewModelFOV = 58
end

-- always derive from weapon_tttbase
SWEP.Base = "weapon_tttbase"

--[[Default GMod values]]--
SWEP.Primary.Ammo = "SMG1"
SWEP.Primary.Delay = 0.13
SWEP.Primary.Recoil = 0.8
SWEP.Primary.Cone = 0.025
SWEP.Primary.Damage = 14
SWEP.Primary.Automatic = true
SWEP.Primary.ClipSize = 30
SWEP.Primary.ClipMax = 60
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Sound = Sound("Weapon_Galil.Single")

SWEP.HeadshotMultiplier  = 1.7

--[[Model settings]]--
SWEP.HoldType = "ar2"
SWEP.ViewModel = Model("models/weapons/cstrike/c_rif_galil.mdl")
SWEP.WorldModel = Model("models/weapons/w_rif_galil.mdl")

SWEP.IronSightsPos = Vector(-6.358, -11, 2.62)
SWEP.IronSightsAng = Vector(-0.6, 0, 0)

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

-- If NoSights is true, the weapon won't have ironsights
SWEP.NoSights = false
