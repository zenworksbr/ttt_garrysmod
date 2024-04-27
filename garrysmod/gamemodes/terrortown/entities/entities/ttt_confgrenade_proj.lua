AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "ttt_basegrenade_proj"
ENT.Model = Model("models/weapons/w_eq_fraggrenade_thrown.mdl")
-- ENT.Model = Model( "models/weapons/w_grenade.mdl" )
-- ENT.WorldMaterial = 'zapgrenade/models/items/w_grenadesheet_proj'
-- ENT.GrenadeLight = Material("sprites/light_glow02_add")
-- ENT.GrenadeColor = Color(173, 255, 236)
-- in case we remove zap grenade

local ttt_allow_jump = CreateConVar("ttt_allow_discomb_jump", "0")

local function PushPullRadius(pos, pusher)
local radius = 300 -- 300
local phys_force = -1000 -- -1000
local push_force = 600 -- 600

   -- pull physics objects and push players
   for k, target in ipairs(ents.FindInSphere(pos, radius)) do
      if IsValid(target) then
         local tpos = target:LocalToWorld(target:OBBCenter())
         local dir = (tpos - pos):GetNormal()
         local phys = target:GetPhysicsObject()

         if target:IsPlayer() and (not target:IsFrozen()) and ((not target.was_pushed) or target.was_pushed.t != CurTime()) then

            -- always need an upwards push to prevent the ground's friction from
            -- stopping nearly all movement
            dir.z = math.abs(dir.z) + 1

            local push = dir * push_force

            -- try to prevent excessive upwards force
            local vel = target:GetVelocity() + push
            vel.z = math.min(vel.z, push_force)

            -- mess with discomb jumps
            if pusher == target and (not ttt_allow_jump:GetBool()) then
               vel = VectorRand() * vel:Length()
               vel.z = math.abs(vel.z)
            end

            target:SetVelocity(vel)

            target.was_pushed = {att=pusher, t=CurTime(), wep="weapon_ttt_confgrenade"}

         elseif IsValid(phys) then
            phys:ApplyForceCenter(dir * -1 * phys_force)
         end
      end
   end

   local phexp = ents.Create("prop_combine_ball")
   if IsValid(phexp) then
      phexp:SetPos(pos)
      phexp:SetKeyValue("magnitude", 100) --max
      phexp:SetKeyValue("radius", radius)
      -- 1 = no dmg, 2 = push ply, 4 = push radial, 8 = los, 16 = viewpunch
      phexp:SetKeyValue("spawnflags", 1 + 2 + 16)
      phexp:Spawn()
      phexp:Fire("Explode", "", 0.01)
   end
end

function ENT:Explode(tr)
   if SERVER then
      self:SetNoDraw(true)
      self:SetSolid(SOLID_NONE)

      -- pull out of the surface
      if tr.Fraction != 1.0 then
         self:SetPos(tr.HitPos + tr.HitNormal * 0.6)
      end

      local pos = self:GetPos()

      -- make sure we are removed, even if errors occur later
      self:Remove()

      PushPullRadius(pos, self:GetThrower())

      local effect = EffectData()
      effect:SetStart(pos)
      effect:SetOrigin(pos)

      if tr.Fraction != 1.0 then
         effect:SetNormal(tr.HitNormal)
      end
      
      util.Effect("HelicopterMegaBomb", effect, true, true)
      util.Effect("cball_explode", effect, true, true)

   else
      local spos = self:GetPos()
      local trs = util.TraceLine({start=spos + Vector(0,0,64), endpos=spos + Vector(0,0,-128), filter=self})
      util.Decal("SmallScorch", trs.HitPos + trs.HitNormal, trs.HitPos - trs.HitNormal)      

      self:SetDetonateExact(0)
   end
end

-- function ENT:Initialize()

--    --new code for custom skin
-- 	self:SetModel("models/weapons/w_grenade.mdl")
-- 	self:SetSubMaterial(0, self.WorldMaterial)
--    -- self.Entity:EmitSound( "weapons/slam/throw.wav", SNDLVL_100dB )
-- 	--code for sprite trail
--    if SERVER then
--       util.SpriteTrail(self, 0, Color(173, 255, 236), false, 25, 1, 4, 1/(15+1)*0.5, "trails/laser.vmt")
--    end

--    return self.BaseClass.Initialize( self )
-- end

-- hook.Add( "PreRender", "ZapGrenProj_DynamicLight", function()
-- 	for k, v in pairs( ents.FindByClass( "ttt_zapgren_proj" ) ) do
-- 		local dlight = DynamicLight( v:EntIndex() )
-- 		if ( dlight ) then
-- 			dlight.pos = v:GetPos()
-- 			dlight.r = 173
-- 			dlight.g = 255
-- 			dlight.b = 236
-- 			dlight.brightness = 5
-- 			dlight.Decay = 384
-- 			dlight.Size = 128
-- 			dlight.DieTime = CurTime() + 0.1
-- 			dlight.Style = 6
-- 		end
			
-- 	end
-- end )
