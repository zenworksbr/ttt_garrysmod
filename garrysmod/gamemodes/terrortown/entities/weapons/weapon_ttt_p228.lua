--resource.AddFile("materials/vgui/ttt/icon_p228.vmt")

if SERVER then
   AddCSLuaFile()
   resource.AddWorkshop( "136948527" )
end
   
SWEP.HoldType = "pistol"
   

if CLIENT then
   SWEP.PrintName = "P228"
   SWEP.Slot = 1
   
   SWEP.Icon = "VGUI/ttt/icon_p228"
end

SWEP.Kind = WEAPON_PISTOL
SWEP.WeaponID = AMMO_PISTOL

SWEP.Base = "weapon_tttbase"
SWEP.Primary.Recoil	= 1.5
SWEP.Primary.Damage = 10
SWEP.Primary.Delay = 0.07
SWEP.Primary.Cone = 0.02
SWEP.Primary.ClipSize = 20
SWEP.Primary.Automatic = false
SWEP.Primary.DefaultClip = 20
SWEP.Primary.ClipMax = 60
SWEP.Primary.Ammo = "Pistol"
SWEP.AutoSpawnable = false
SWEP.AmmoEnt = "item_ammo_pistol_ttt"

SWEP.ViewModel  = "models/weapons/v_pist_p228.mdl"
SWEP.WorldModel = "models/weapons/w_pist_p228.mdl"

SWEP.IronSightsPos = Vector(-5.95, -9, 2.87)
SWEP.IronSightsAng = Vector(-1, -0.03, 0)

SWEP.Primary.Sound = Sound( "Weapon_P228.Single" )
SWEP.NoSights = false

SWEP.Spawnable = true
SWEP.AutoSpawnable = true