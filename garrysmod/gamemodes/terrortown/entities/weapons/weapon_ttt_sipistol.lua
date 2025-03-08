AddCSLuaFile()

SWEP.HoldType              = "revolver"
SWEP.ReloadHoldType        = "pistol"

if CLIENT then
   SWEP.PrintName             = "USP-S"
   SWEP.Slot               = 1

   SWEP.ViewModelFlip      = false
   SWEP.ViewModelFOV       = 70
   SWEP.UseHands           = true
   

   SWEP.EquipMenuData = {
      type = "item_weapon",
      desc = "sipistol_desc"
   };

   SWEP.Icon               = "vgui/ttt/icon_silenced"
   SWEP.IconLetter         = "a"
end

SWEP.Base                  = "weapon_tttbase"

SWEP.Primary.Recoil        = 1.40
SWEP.Primary.Damage        = 35
SWEP.Primary.Delay         = 0.35
SWEP.Primary.Cone          = 0.01
SWEP.Primary.ClipSize      = 12
SWEP.Primary.Automatic     = true
SWEP.Primary.DefaultClip   = 12
SWEP.Primary.ClipMax       = 24
SWEP.Primary.Ammo          = "Pistol"
SWEP.Primary.Sound         = Sound( "Weapon_USP.SilencedShot" )
SWEP.Primary.SoundLevel    = 50

SWEP.Kind                  = WEAPON_PISTOL
SWEP.CanBuy                = {ROLE_TRAITOR} -- only traitors can buy
SWEP.WeaponID              = AMMO_SIPISTOL

SWEP.AmmoEnt               = "item_ammo_pistol_ttt"
SWEP.IsSilent              = true
SWEP.LimitedStock		      = true

SWEP.UseHands              = true
SWEP.ViewModel             = "models/weapons/cstrike/c_pist_usp.mdl"
SWEP.WorldModel            = "models/weapons/w_pist_usp_silencer.mdl"

SWEP.MuzzleAttachment           = "1" -- Should be "1" for CSS models or "muzzle" for hl2 models
SWEP.ShellAttachment            = "2" -- Should be "2" for CSS models or "shell" for hl2 models

SWEP.IronSightsPos         = Vector( -5.91, -4, 2.84 )
SWEP.IronSightsAng         = Vector(-0.5, 0, 0)

SWEP.PrimaryAnim           = ACT_VM_PRIMARYATTACK_SILENCED
SWEP.ReloadAnim            = ACT_VM_RELOAD_SILENCED

function SWEP:Deploy()
   self:SendWeaponAnim(ACT_VM_DRAW_SILENCED)
   return self.BaseClass.Deploy(self)
end

-- We were bought as special equipment, and we have an extra to give
function SWEP:WasBought(buyer)
   if IsValid(buyer) and IsPlayer(buyer) then -- probably already self:GetOwner()
      buyer:GiveAmmo(24, "item_ammo_pistol_ttt", true)
   end
end