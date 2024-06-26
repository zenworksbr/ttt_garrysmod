AddCSLuaFile()

SWEP.HoldType               = "knife"

if CLIENT then
   SWEP.PrintName           = "knife_name"
   SWEP.Slot                = 6

   SWEP.ViewModelFlip       = false
   SWEP.ViewModelFOV        = 54
   SWEP.DrawCrosshair       = false

   SWEP.EquipMenuData = {
      type = "item_weapon",
      desc = [[Uma faca muito especial.
      Mata instantaneamente se usada pelas costas do alvo.
      Se for arremessada, não poderá ser recuperada, mas também será letal.
      ]]
   };

   SWEP.Icon                = "vgui/ttt/icon_knife"
   SWEP.IconLetter          = "j"
end

SWEP.Base                   = "weapon_tttbase"

SWEP.ShowViewModel          = true
SWEP.ShowWorldModel         = true
SWEP.UseHands               = true
SWEP.ViewModel              = "models/weapons/cstrike/c_knife_t.mdl"
SWEP.WorldModel             = "models/weapons/w_knife_t.mdl"

SWEP.Primary.Damage         = 26
SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = true
SWEP.Primary.Delay          = 0.5
SWEP.Primary.Ammo           = "none"

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = true
SWEP.Secondary.Ammo         = "none"
SWEP.Secondary.Delay        = 1

SWEP.Kind                   = WEAPON_EQUIP
SWEP.CanBuy                 = {ROLE_TRAITOR} -- only traitors can buy
SWEP.LimitedStock           = true -- only buyable once
SWEP.WeaponID               = AMMO_KNIFE

SWEP.IsSilent               = true

-- Pull out faster than standard guns
SWEP.DeploySpeed            = 2

-- SWEP.WElements = {
-- 	["knife"] = { type = "Model", model = "models/weapons/w_models/w_knife.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(2.799, 0.899, -0.519), angle = Angle(-180, 167.143, -5.844), size = Vector(0.8, 0.8, 0.8), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
-- }

SWEP.DeploySounds = {
   "sound/weapons/knife_open1.wav",
   "sound/weapons/knife_open2.wav",
   "sound/weapons/knife_open3.wav",
   "sound/weapons/knife_open4.wav",
   "sound/weapons/knife_open5.wav",
   "sound/weapons/knife_open6.wav",
   "sound/weapons/knife_open7.wav",
   "sound/weapons/knife_open8.wav"
}

SWEP.HitSounds = {
   "sound/weapons/blade_hit1.wav",
   "sound/weapons/blade_hit2.wav",
   "sound/weapons/blade_hit3.wav",
   "sound/weapons/blade_hit4.wav"
}

SWEP.BStabSound = "sound/weapons/spy_assassin_knife_bckstb.wav"

SWEP.HitAnims = {
   "stab_a",
   "stab_b",
   "stab_c"
}

SWEP.HitWorldSound = "sound/weapons/blade_hitworld.wav"
SWEP.MissSound = "sound/weapons/knife_swing.wav"

-- local function isIdle(vm)
--    return vm:GetSequence() == vm:LookupSequence( "idle" )
-- end

-- function SWEP:Deploy()
--    local vm = self.Owner:GetViewModel()
--    vm:SendViewModelMatchingSequence( vm:LookupSequence( "draw" ) )

--    self.Owner:EmitSound( self.DeploySounds[ math.random(1, #self.DeploySounds) ] )

--    return true
-- end

-- local start_anim = false
-- local end_anim = false
-- function SWEP:Think()

--    local vm = self.Owner:GetViewModel()
--    local spos = self:GetOwner():GetShootPos()
--    local sdest = spos + (self:GetOwner():GetAimVector() * 70)

--    local kmins = Vector(1,1,1) * -10
--    local kmaxs = Vector(1,1,1) * 10

--    local tr = util.TraceHull({start=spos, endpos=sdest, filter=self:GetOwner(), mask=MASK_SHOT_HULL, mins=kmins, maxs=kmaxs})

--    if not tr.Hit or not tr.HitNotWorld then return end
--    local target = tr.Entity
--    if target:GetPos():Distance(self:GetPos()) > 50 then return end
--    if not IsValid(target) then return end

--    local victim_angles = Entity(hitEnt:EntIndex()):GetAimVector()
--    local attacker_angles = self:GetOwner():GetAimVector()
--    local alignment = math.deg(victim_angles:Dot(attacker_angles))
--    if alignment > 0 && alignment < 90 then
--       vm:SendViewModelMatchingSequence( vm:LookupSequence( "backstab_idle" ) )
--       -- if not start_anim then
--       --    vm:SendViewModelMatchingSequence( vm:LookupSequence( "backstab_up" ) )
--       --    start_anim = true
--       -- end
--       -- if not isIdle(vm) then
--       --    vm:SendViewModelMatchingSequence( vm:LookupSequence( "backstab_idle" ) )
--       --    start_anim = false
--       -- end
--    -- else
--    --    if not end_anim then
--    --       vm:SendViewModelMatchingSequence( vm:LookupSequence( "backstab_down" ) )
--    --       end_anim = true
--    --    end
--    end
--    vm:SendViewModelMatchingSequence( vm:LookupSequence( "idle" ) )
--    end_anim = false
-- end

-- function SWEP:Initialize()
--    self:SetWeaponHoldType( self.HoldType )
-- 	// other initialize code goes here
-- end

local function isBackstab(wep, target)
   local victim_angles = target:GetAimVector()
   local attacker_angles = wep:GetOwner():GetAimVector()
   local alignment = math.deg(victim_angles:Dot(attacker_angles))
   return (alignment > 0 && alignment < 90)
end

function SWEP:PrimaryAttack()
   self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
   self:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )

   if not IsValid(self:GetOwner()) then return end

   self:GetOwner():LagCompensation(true)

   local spos = self:GetOwner():GetShootPos()
   local sdest = spos + (self:GetOwner():GetAimVector() * 70)

   local kmins = Vector(1,1,1) * -10
   local kmaxs = Vector(1,1,1) * 10

   local tr = util.TraceHull({start=spos, endpos=sdest, filter=self:GetOwner(), mask=MASK_SHOT_HULL, mins=kmins, maxs=kmaxs})

   -- Hull might hit environment stuff that line does not hit
   if not IsValid(tr.Entity) then
      tr = util.TraceLine({start=spos, endpos=sdest, filter=self:GetOwner(), mask=MASK_SHOT_HULL})
   end

   local hitEnt = tr.Entity
   local vm = self.Owner:GetViewModel()

   -- effects
   if IsValid(hitEnt) then
      -- vm:SendViewModelMatchingSequence( vm:LookupSequence( self.HitAnims[ math.random(1, #self.HitAnims) ] ) )
      -- ACT_VM_HITCENTER

      local edata = EffectData()
      edata:SetStart(spos)
      edata:SetOrigin(tr.HitPos)
      edata:SetNormal(tr.Normal)
      edata:SetEntity(hitEnt)

      if hitEnt:IsPlayer() or hitEnt:GetClass() == "prop_ragdoll" then
         util.Effect("BloodImpact", edata)
         self.Owner:EmitSound( self.HitSounds[ math.random(1, #self.HitSounds) ] )
      else
         self.Owner:EmitSound(self.HitWorldSound)
      end
      
   else
      self:SendWeaponAnim( ACT_VM_MISSCENTER )
      -- vm:SendViewModelMatchingSequence( vm:LookupSequence( self.HitAnims[ math.random(1, #self.HitAnims) ] ) )
      self.Owner:EmitSound(self.MissSound)
   end

   if SERVER then
      self:GetOwner():SetAnimation( PLAYER_ATTACK1 )
   end


   if SERVER and tr.Hit and tr.HitNonWorld and IsValid(hitEnt) then
      if hitEnt:IsPlayer() then
         -- knife damage is never karma'd, so don't need to take that into
         -- account we do want to avoid rounding error strangeness caused by
         -- other damage scaling, causing a death when we don't expect one, so
         -- when the target's health is close to kill-point we just kill
         if isBackstab(self.Weapon, hitEnt) then
            
            local dmg = DamageInfo()
            dmg:SetDamage(self.Primary.Damage * 20)
            dmg:SetAttacker(self:GetOwner())
            dmg:SetInflictor(self)
            dmg:SetDamageForce(self:GetOwner():GetAimVector() * 5)
            dmg:SetDamagePosition(self:GetOwner():GetPos())
            dmg:SetDamageType(DMG_SLASH)

            hitEnt:DispatchTraceAttack(dmg, spos + (self:GetOwner():GetAimVector() * 3), sdest)
            vm:SendViewModelMatchingSequence( vm:LookupSequence( 'backstab' ) )
            self.Owner:EmitSound(self.BStabSound)
         else
            local dmg = DamageInfo()
            dmg:SetDamage(self.Primary.Damage)
            dmg:SetAttacker(self:GetOwner())
            dmg:SetInflictor(self)
            dmg:SetDamageForce(self:GetOwner():GetAimVector() * 5)
            dmg:SetDamagePosition(self:GetOwner():GetPos())
            dmg:SetDamageType(DMG_SLASH)

            hitEnt:DispatchTraceAttack(dmg, spos + (self:GetOwner():GetAimVector() * 3), sdest)
         end
      end
   end

   self:GetOwner():LagCompensation(false)
end

function SWEP:ThrowKill(tr, spos, sdest)
   local vm = self.Owner:GetViewModel()
   local target = tr.Entity

   local dmg = DamageInfo()
   dmg:SetDamage(self.Primary.Damage * 100)
   dmg:SetAttacker(self:GetOwner())
   dmg:SetInflictor(self)
   dmg:SetDamageForce(self:GetOwner():GetAimVector())
   dmg:SetDamagePosition(self:GetOwner():GetPos())
   dmg:SetDamageType(DMG_SLASH)

   -- now that we use a hull trace, our hitpos is guaranteed to be
   -- terrible, so try to make something of it with a separate trace and
   -- hope our effect_fn trace has more luck

   -- first a straight up line trace to see if we aimed nicely
   local retr = util.TraceLine({start=spos, endpos=sdest, filter=self:GetOwner(), mask=MASK_SHOT_HULL})

   -- if that fails, just trace to worldcenter so we have SOMETHING
   if retr.Entity != target then
      local center = target:LocalToWorld(target:OBBCenter())
      retr = util.TraceLine({start=spos, endpos=center, filter=self:GetOwner(), mask=MASK_SHOT_HULL})
   end

   -- create knife effect creation fn
   local bone = retr.PhysicsBone
   local pos = retr.HitPos
   local norm = tr.Normal
   local ang = Angle(-28,0,0) + norm:Angle()
   ang:RotateAroundAxis(ang:Right(), -90)
   pos = pos - (ang:Forward() * 7)

   local prints = self.fingerprints
   local ignore = self:GetOwner()

   target.effect_fn = function(rag)
      -- we might find a better location
      local rtr = util.TraceLine({start=pos, endpos=pos + norm * 40, filter=ignore, mask=MASK_SHOT_HULL})

      if IsValid(rtr.Entity) and rtr.Entity == rag then
         bone = rtr.PhysicsBone
         pos = rtr.HitPos
         ang = Angle(-28,0,0) + rtr.Normal:Angle()
         ang:RotateAroundAxis(ang:Right(), -90)
         pos = pos - (ang:Forward() * 10)

      end

      local knife = ents.Create("prop_physics")
      knife:SetModel("models/weapons/w_weapons/w_knife.mdl")
      knife:SetPos(pos)
      knife:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
      knife:SetAngles(ang)
      knife.CanPickup = false

      knife:Spawn()

      local phys = knife:GetPhysicsObject()
      if IsValid(phys) then
         phys:EnableCollisions(false)
      end

      constraint.Weld(rag, knife, bone, 0, 0, true)

      -- need to close over knife in order to keep a valid ref to it
      rag:CallOnRemove("ttt_knife_cleanup", function() SafeRemoveEntity(knife) end)
   end


   -- seems the spos and sdest are purely for effects/forces?
   target:DispatchTraceAttack(dmg, spos + (self:GetOwner():GetAimVector() * 3), sdest)

   -- target appears to die right there, so we could theoretically get to
   -- the ragdoll in here...

   self:Remove()
end

function SWEP:SecondaryAttack()
   self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
   self:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )


   self:SendWeaponAnim( ACT_VM_MISSCENTER )

   if SERVER then
      local ply = self:GetOwner()
      if not IsValid(ply) then return end

      ply:SetAnimation( PLAYER_ATTACK1 )

      local ang = ply:EyeAngles()

      if ang.p < 90 then
         ang.p = -10 + ang.p * ((90 + 10) / 90)
      else
         ang.p = 360 - ang.p
         ang.p = -10 + ang.p * -((90 + 10) / 90)
      end

      local vel = math.Clamp((90 - ang.p) * 4, 1500, 800)

      local vfw = ang:Forward()
      local vrt = ang:Right()

      local src = ply:GetPos() + (ply:Crouching() and ply:GetViewOffsetDucked() or ply:GetViewOffset())

      src = src + (vfw * 1) + (vrt * 3)

      local thr = vfw * vel + ply:GetVelocity()

      local knife_ang = Angle(-28,0,0) + ang
      knife_ang:RotateAroundAxis(knife_ang:Right(), -90)

      local knife = ents.Create("ttt_knife_proj")
      if not IsValid(knife) then return end
      knife:SetPos(src)
      knife:SetAngles(knife_ang)

      knife:Spawn()

      knife.Damage = self.Primary.Damage * 100

      knife:SetOwner(ply)

      local phys = knife:GetPhysicsObject()
      if IsValid(phys) then
         phys:SetVelocity(thr)
         phys:AddAngleVelocity(Vector(0, 1500, 0))
         phys:Wake()
      end

      self:Remove()
   end
end

function SWEP:Equip()
   self:SetNextPrimaryFire( CurTime() + (self.Primary.Delay * 1.5) )
   self:SetNextSecondaryFire( CurTime() + (self.Secondary.Delay * 1.5) )
end

function SWEP:PreDrop()
   -- for consistency, dropped knife should not have DNA/prints
   self.fingerprints = {}
end

function SWEP:OnRemove()
   if CLIENT and IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer() and self:GetOwner():Alive() then
      RunConsoleCommand("lastinv")
   end
end

if CLIENT then

   local T = LANG.GetTranslation
   function SWEP:DrawHUD()
      local tr = self:GetOwner():GetEyeTrace(MASK_SHOT)

      if tr.HitNonWorld and IsValid(tr.Entity) and tr.Entity:IsPlayer()
         and tr.Entity:Health() < (self.Primary.Damage + 10) 
         and isBackstab(self.Weapon, tr.Entity) then

         local x = ScrW() / 2.0
         local y = ScrH() / 2.0

         surface.SetDrawColor(255, 0, 0, 255)

         local outer = 20
         local inner = 10
         surface.DrawLine(x - outer, y - outer, x - inner, y - inner)
         surface.DrawLine(x + outer, y + outer, x + inner, y + inner)

         surface.DrawLine(x - outer, y + outer, x - inner, y + inner)
         surface.DrawLine(x + outer, y - outer, x + inner, y - inner)

         draw.SimpleText(T("knife_instant"), "TabLarge", x, y - 30, COLOR_RED, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
      end

      return self.BaseClass.DrawHUD(self)
   end
end
