AddCSLuaFile()

if SERVER then
	resource.AddWorkshop(420589986)	
end

if CLIENT then
   
   SWEP.Slot = 1
   SWEP.Icon = "vgui/ttt/magnum"
end

SWEP.PrintName = "Magnum .357"

-- Always derive from weapon_tttbase
SWEP.Base = "weapon_tttbase"

-- Standard GMod values
SWEP.HoldType = "pistol"

SWEP.Kind                  = WEAPON_PISTOL
SWEP.WeaponID              = AMMO_DEAGLE

SWEP.Primary.Ammo          = "AlyxGun" -- hijack an ammo type we don't use otherwise
SWEP.Primary.Recoil        = 6
SWEP.Primary.Damage        = 45
SWEP.Primary.Delay         = 1
SWEP.Primary.Cone          = 0.02
SWEP.Primary.ClipSize      = 6
SWEP.Primary.ClipMax       = 24
SWEP.Primary.DefaultClip   = 6
SWEP.Primary.Automatic     = true
SWEP.Primary.Sound         = Sound( "weapon_357.Single" )

SWEP.HeadshotMultiplier    = 4

SWEP.AutoSpawnable         = true
SWEP.Spawnable             = true
SWEP.AmmoEnt               = "item_ammo_revolver_ttt"

-- Model settings
SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 54
SWEP.ViewModel = "models/weapons/c_357.mdl"
SWEP.WorldModel	= "models/weapons/w_357.mdl"

SWEP.IronSightsPos = Vector ( -4.64, -3.96, 0.68 )
SWEP.IronSightsAng = Vector ( 0.214, -0.1767, 0 )

