AddCSLuaFile()

DEFINE_BASECLASS "weapon_tttbase"

SWEP.HoldType               = "physgun"

if CLIENT then
   SWEP.PrintName           = "Lançador de Newton"
   SWEP.Slot                = 8

   SWEP.ViewModelFlip       = false
   SWEP.ViewModelFOV        = 60

   SWEP.EquipMenuData = {
      type = "item_weapon",
      desc = "newton_desc"
   };

   SWEP.Icon               = "vgui/ttt/icon_supernewtonbs"
end

SWEP.Base                  = "weapon_tttbase"

SWEP.Primary.Ammo          = "none"
SWEP.Primary.ClipSize      = -1
SWEP.Primary.DefaultClip   = -1
SWEP.Primary.Automatic     = true
SWEP.Primary.Delay         = 6
SWEP.Primary.Cone          = 0.005
SWEP.Primary.Sound         = Sound( "weapons/disparonewton.wav" )
SWEP.Primary.SoundLevel    = 54

SWEP.Secondary.ClipSize    = 10
SWEP.Secondary.DefaultClip = 10
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"
SWEP.Secondary.Delay       = 0.8

SWEP.NoSights              = true

SWEP.Kind                  = WEAPON_ROLE
SWEP.CanBuy                = {ROLE_TRAITOR}
SWEP.WeaponID              = AMMO_PUSH

SWEP.UseHands              = true
SWEP.ViewModel             = "models/weapons/c_newton_launcher.mdl"
SWEP.WorldModel            = "models/weapons/w_newton_launcher.mdl"

AccessorFuncDT(SWEP, "charge", "Charge")

SWEP.IsCharging            = false
SWEP.NextCharge            = 0

local CHARGE_AMOUNT        = 0.02
local CHARGE_DELAY         = 0.02

local math = math

function SWEP:Initialize()
   if SERVER then
      self:SetSkin(1)
   end
   return self.BaseClass.Initialize(self)
end

game.AddParticles( "particles/tttsupernewtonbs.pcf" )

function SWEP:SetupDataTables()
   self:DTVar("Float", 0, "charge")
end

function SWEP:PrimaryAttack()
   if self.IsCharging then return end
   
   self.Primary.Delay = 4	-- Min Time of waiting for the gun to recharge

   self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
   self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )

   self:FirePulse(1000, 800)
end

function SWEP:SecondaryAttack()
   if self.IsCharging then return end

   self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
   self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
   self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_START)
   self.Weapon:EmitSound( Sound("weapons/newtonaumentaenergia2.wav") )

   self.IsCharging = true
end

function SWEP:FirePulse(force_fwd, force_up)
   if not IsValid(self.Owner) then return end
   
   bullet = {}
   bullet.Src    = self.Owner:GetShootPos()
   bullet.Dir    = self.Owner:GetAimVector()
   bullet.Spread = Vector( cone, cone, 0 )
   bullet.Tracer = 1
   bullet.Force  = force_fwd / 10
   bullet.TracerName = "AirboatGunHeavyTracer"
   local num = 6
   
	if (force_fwd < 2000) then
	   bullet.Num = 6
	   bullet.Damage = 7
	   self.Primary.Delay = 4

   elseif (force_fwd < 3000) then
	   bullet.Num = 7
	   bullet.Damage = 8
	   self.Primary.Delay = 5
   
   elseif (force_fwd < 4000) then
	   bullet.Num = 8
	   bullet.Damage = 8
	   self.Primary.Delay = 6
   
   else
	   bullet.Num = 9
	   bullet.Damage = 9
	   self.Primary.Delay = 8
   end

   self.Owner:SetAnimation( PLAYER_ATTACK1 )

   sound.Play(self.Primary.Sound, self:GetPos(), self.Primary.SoundLevel)

   self:SendWeaponAnim(ACT_VM_IDLE)

   local cone = self.Primary.Cone or 0.1

   local owner = self.Owner
   local fwd = force_fwd / num
   local up = force_up / num
   bullet.Callback = function(att, tr, dmginfo)
                        local ply = tr.Entity
                        if SERVER and IsValid(ply) and ply:IsPlayer() and (not ply:IsFrozen()) then
                           local pushvel = tr.Normal * fwd

                           pushvel.z = math.max(pushvel.z, up)

                           ply:SetGroundEntity(nil)
                           ply:SetLocalVelocity(ply:GetVelocity() + pushvel)

                           ply.was_pushed = {att=owner, t=CurTime(), wep=self:GetClass()}

                        end
                     end

   self.Owner:FireBullets( bullet )

end

local CHARGE_FORCE_FWD_MIN = 1000
local CHARGE_FORCE_FWD_MAX = 4000
local CHARGE_FORCE_UP_MIN = 800
local CHARGE_FORCE_UP_MAX = 2000
function SWEP:ChargedAttack()
   local charge = math.Clamp(self:GetCharge(), 0, 1)
   
   self.IsCharging = false
   self:SetCharge(0)

   if charge <= 0 then return end

   local max = CHARGE_FORCE_FWD_MAX
   local diff = max - CHARGE_FORCE_FWD_MIN

   local force_fwd = ((charge * diff) - diff) + max

   max = CHARGE_FORCE_UP_MAX
   diff = max - CHARGE_FORCE_UP_MIN

   local force_up = ((charge * diff) - diff) + max
   
   if (force_fwd < 2000) then
	   self.Primary.Delay = 4

   elseif (force_fwd < 3000) then
	   self.Primary.Delay = 5
   
   elseif (force_fwd < 4000) then
	   self.Primary.Delay = 6
   
   else
	   self.Primary.Delay = 8
   end

   self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
   self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )

   self:FirePulse(force_fwd, force_up)
end

function SWEP:PreDrop(death_drop)
   -- allow dropping for now, see if it helps against heisenbug on owner death
--   if death_drop then
   -- self.IsCharging = false
   -- self:SetCharge(0)
--   elseif self.IsCharging then
--      self:ChargedAttack()
--   end
end

function SWEP:OnRemove()
   self.IsCharging = false
   self:SetCharge(0)
end

function SWEP:Deploy()
   -- self.IsCharging = false
   -- self:SetCharge(0)
   return true
end

function SWEP:Holster()
   return not self.IsCharging
end

function SWEP:Think()
   BaseClass.Think(self)
   if self.IsCharging and IsValid(self:GetOwner()) and self:GetOwner():IsTerror() then
      -- on client this is prediction
      if not self:GetOwner():KeyDown(IN_ATTACK2) then
         self:ChargedAttack()
         return true
      end

      
      if SERVER and self:GetCharge() < 1 and self.NextCharge < CurTime() then
         self:SetCharge(math.min(1, self:GetCharge() + CHARGE_AMOUNT))

         self.NextCharge = CurTime() + CHARGE_DELAY
      end
   end
end

if CLIENT then
   local surface = surface
   function SWEP:DrawHUD()
      local x = ScrW() / 2.0
      local y = ScrH() / 2.0

      local nxt = self:GetNextPrimaryFire()
      local charge = self.dt.charge

      if LocalPlayer():IsTraitor() then
         surface.SetDrawColor(255, 0, 0, 255)
      else
         surface.SetDrawColor(0, 255, 0, 255)
      end

      if nxt < CurTime() or CurTime() % 0.5 < 0.2 or charge > 0 then
         local length = 10
         local gap = 5

         surface.DrawLine( x - length, y, x - gap, y )
         surface.DrawLine( x + length, y, x + gap, y )
         surface.DrawLine( x, y - length, x, y - gap )
         surface.DrawLine( x, y + length, x, y + gap )
      end

      if nxt > CurTime() and charge == 0 then
         local w = 40

         w = (w * ( math.max(0, nxt - CurTime()) /  self.Primary.Delay )) / 2

         local bx = x + 30
         surface.DrawLine(bx, y - w, bx, y + w)

         bx = x - 30
         surface.DrawLine(bx, y - w, bx, y + w) 
      end

      if charge > 0 then
         y = y + (y / 3)

         local w, h = 100, 20

         surface.DrawOutlinedRect(x - w/2, y - h, w, h)

         if LocalPlayer():IsTraitor() then
            surface.SetDrawColor(255, 0, 0, 155)
         else
            surface.SetDrawColor(0, 255, 0, 155)
         end

         surface.DrawRect(x - w/2, y - h, w * charge, h)

         surface.SetFont("TabLarge")
         surface.SetTextColor(255, 255, 255, 180)
         surface.SetTextPos( (x - w / 2) + 3, y - h - 15)
         surface.DrawText("FORÇA")
      end
   end
end