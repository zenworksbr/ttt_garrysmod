AddCSLuaFile()

DEFINE_BASECLASS "weapon_tttbase"

-- SWEP.HoldType              = "ar2"
SWEP.HoldType	  		      = "rpg"

if CLIENT then
   SWEP.PrintName          = "polter_name"
   SWEP.Slot               = 7

   SWEP.ViewModelFlip      = false
   SWEP.ViewModelFOV       = 54

   SWEP.EquipMenuData = {
      type = "item_weapon",
      desc = "polter_desc"
   };

   SWEP.Icon               = "vgui/ttt/icon_polter"
end

SWEP.Base                  = "weapon_tttbase"

SWEP.Primary.Recoil        = 0.1
SWEP.Primary.Delay         = 12.0
SWEP.Primary.Cone          = 0.02
SWEP.Primary.ClipSize      = 6
SWEP.Primary.DefaultClip   = 6
SWEP.Primary.ClipMax       = 6
SWEP.Primary.Ammo          = "Gravity"
SWEP.Primary.Automatic     = false
SWEP.Primary.Sound         = Sound( "weapons/airboat/airboat_gun_energy1.wav" )
-- SWEP.Primary.Sound         = Sound("weapons/tfdisplacer/shot.wav")

SWEP.Secondary.Automatic   = false

SWEP.Kind                  = WEAPON_EQUIP2
SWEP.CanBuy                = {ROLE_TRAITOR} -- only traitors can buy
SWEP.WeaponID              = AMMO_POLTER

SWEP.UseHands              = true
SWEP.ViewModel             = "models/weapons/c_rpg.mdl"
SWEP.WorldModel            = "models/weapons/w_rocket_launcher.mdl"
SWEP.ShowViewModel 		   = true
SWEP.ShowWorldModel 		   = false

SWEP.NoSights              = true

SWEP.IsCharging            = false
SWEP.NextCharge            = 0
SWEP.MaxRange              = 1200

SWEP.ViewModelBoneMods = {
	["base"] = { scale = Vector(0.1, 0.1, 0.1), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
}

SWEP.VElements = {
	["v_element"] = { type = "Model", model = "models/choev/weapons/half-life/displacer_cannon.mdl", bone = "Base", rel = "", pos = Vector(-0.5, 4, 1), angle = Angle(0, -90, 0), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.WElements = {
	["w_element3"] = { type = "Model", model = "models/choev/weapons/half-life/displacer_cannon.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(2, 0.5, -0.5), angle = Angle(103, 175, 0), size = Vector(0.9, 0.9, 0.9), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

AccessorFuncDT(SWEP, "charge", "Charge")

local math = math

-- Returns if an entity is a valid physhammer punching target. Does not take
-- distance into account.
local function ValidTarget(ent)
   return IsValid(ent) and ent:GetMoveType() == MOVETYPE_VPHYSICS and ent:GetPhysicsObject() and (not ent:IsWeapon()) and (not ent:GetNWBool("punched", false)) and (not ent:IsPlayer())
   -- NOTE: cannot check for motion disabled on client
end

function SWEP:SetupDataTables()
   self:DTVar("Float", 0, "charge")
end

local ghostmdl = Model("models/Items/combine_rifle_ammo01.mdl")
function SWEP:Initialize()
   if CLIENT then
      -- create ghosted indicator
      local ghost = ents.CreateClientProp(ghostmdl)
      if IsValid(ghost) then
         ghost:SetPos(self:GetPos())
         ghost:Spawn()

         -- PhysPropClientside whines here about not being able to parse the
         -- physmodel. This is not important as we won't use that anyway, and it
         -- happens in sandbox as well for the ghosted ents used there.

         ghost:SetSolid(SOLID_NONE)
         ghost:SetMoveType(MOVETYPE_NONE)
         ghost:SetNotSolid(true)
         ghost:SetRenderMode(RENDERMODE_TRANSCOLOR)
         ghost:AddEffects(EF_NOSHADOW)
         ghost:SetNoDraw(true)

         self.Ghost = ghost
      end
   end

   self.IsCharging = false
   self:SetCharge(0)

   -- new model
   if CLIENT then
		-- Create a new table for every weapon instance
		self.VElements = table.FullCopy( self.VElements )
		self.WElements = table.FullCopy( self.WElements )
		self.ViewModelBoneMods = table.FullCopy( self.ViewModelBoneMods )
      self:SetWeaponHoldType( self.HoldType )
		
		self:CreateModels(self.VElements) -- create viewmodels
		self:CreateModels(self.WElements) -- create worldmodels
		
		-- init view model bone build function
		if IsValid(self.Owner) then
			if self.Owner:IsNPC() then return end
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				self:ResetBonePositions(vm)
				
				-- Init viewmodel visibility
				if (self.ShowViewModel == nil or self.ShowViewModel) then
					vm:SetColor(Color(255,255,255,255))
				else
					-- we set the alpha to 1 instead of 0 because else ViewModelDrawn stops being called
					vm:SetColor(Color(255,255,255,1))
					-- ^ stopped working in GMod 13 because you have to do Entity:SetRenderMode(1) for translucency to kick in
					-- however for some reason the view model resets to render mode 0 every frame so we just apply a debug material to prevent it from drawing
					vm:SetMaterial("Debug/hsv")			
				end
			end
		end
	end
   -- new model

   return self.BaseClass.Initialize(self)
end

function SWEP:PreDrop()
   self.IsCharging = false
   self:SetCharge(0)

   -- OnDrop does not happen on client
   self:CallOnClient("HideGhost", "")
end

function SWEP:HideGhost()
   if IsValid(self.Ghost) then
      self.Ghost:SetNoDraw(true)
   end
end

function SWEP:PrimaryAttack()
   self:SetNextPrimaryFire(CurTime() + 0.1)
   if not self:CanPrimaryAttack() then return end
   if IsValid(self.hammer) then return end
   if SERVER then
      if self.IsCharging then return end

      local ply = self:GetOwner()
      if not IsValid(ply) then return end

      local tr = util.TraceLine({start=ply:GetShootPos(), endpos=ply:GetShootPos() + ply:GetAimVector() * self.MaxRange, filter={ply, self}, mask=MASK_SOLID})

      if tr.HitNonWorld and ValidTarget(tr.Entity) and tr.Entity:GetPhysicsObject():IsMoveable() then

         self:CreateHammer(tr.Entity, tr.HitPos)

         self:EmitSound(self.Primary.Sound)

         self:TakePrimaryAmmo(1)

         self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
      end
   end
end

function SWEP:SecondaryAttack()
   if self.IsCharging then return end

   self:SetNextSecondaryFire( CurTime() + 0.1 )

   if not (self:CanPrimaryAttack() and (self:GetNextPrimaryFire() - CurTime()) <= 0) then return end
   if IsValid(self.hammer) then return end
   if SERVER then
      local ply = self:GetOwner()
      if not IsValid(ply) then return end

      local range = 30000

      local tr = util.TraceLine({start=ply:GetShootPos(), endpos=ply:GetShootPos() + ply:GetAimVector() * range, filter={ply, self}, mask=MASK_SOLID})

      if tr.HitNonWorld and ValidTarget(tr.Entity) and tr.Entity:GetPhysicsObject():IsMoveable() then

         if self.IsCharging and self:GetCharge() >= 1 then
            return
         elseif tr.Fraction * range > self.MaxRange then
            self.IsCharging = true
         end
      end
   end
end

function SWEP:CreateHammer(tgt, pos)
   local hammer = ents.Create("ttt_physhammer")
   if IsValid(hammer) then
      local ang = self:GetOwner():GetAimVector():Angle()
      ang:RotateAroundAxis(ang:Right(), 90)

      hammer:SetPos(pos)
      hammer:SetAngles(ang)

      hammer:Spawn()

      hammer:SetOwner(self:GetOwner())

      local stuck = hammer:StickTo(tgt)

      if not stuck then hammer:Remove() end
      self.hammer = hammer
   end
end

function SWEP:OnRemove()
   if CLIENT and IsValid(self.Ghost) then
      self.Ghost:Remove()
   end

   self.IsCharging = false
   self:SetCharge(0)
end

function SWEP:Holster()
   if CLIENT and IsValid(self.Ghost) then
      self.Ghost:SetNoDraw(true)
      local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetBonePositions(vm)
		end
      self:EmitSound("weapons/tfdisplacer/deactivate.wav")
   end
   

   self.IsCharging = false
   self:SetCharge(0)

   return self.BaseClass.Holster(self)
end


if SERVER then

   local CHARGE_AMOUNT = 0.015
   local CHARGE_DELAY = 0.025

   function SWEP:Think()
      BaseClass.Think(self)
      if not IsValid(self:GetOwner()) then return end

      if self.IsCharging and self:GetOwner():KeyDown(IN_ATTACK2) then
         local tr = self:GetOwner():GetEyeTrace(MASK_SOLID)
         if tr.HitNonWorld and ValidTarget(tr.Entity) then

            if self:GetCharge() >= 1 then
               self:CreateHammer(tr.Entity, tr.HitPos)

               self:EmitSound(self.Primary.Sound)

               self:TakePrimaryAmmo(1)

               self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

               self.IsCharging = false
               self:SetCharge(0)
               return true
            elseif self.NextCharge < CurTime() then
               local d = tr.Entity:GetPos():Distance(self:GetOwner():GetPos())
               local f = math.max(1, math.floor(d / self.MaxRange))

               self:SetCharge(math.min(1, self:GetCharge() + (CHARGE_AMOUNT / f)))

               self.NextCharge = CurTime() + CHARGE_DELAY
            end
         else
            self.IsCharging = false
            self:SetCharge(0)
         end

      elseif self:GetCharge() > 0 then
         -- owner let go of rmouse
         self:SetCharge(0)
         self.IsCharging = false
      end
   end
end

local function around( val )
   return math.Round( val * (10 ^ 3) ) / (10 ^ 3);
end

if CLIENT then
   local surface = surface

   function SWEP:UpdateGhost(pos, c, a)
      if IsValid(self.Ghost) then
         if self.Ghost:GetPos() != pos then
            self.Ghost:SetPos(pos)
            local ang = LocalPlayer():GetAimVector():Angle()
            ang:RotateAroundAxis(ang:Right(), 90)

            self.Ghost:SetAngles(ang)

            self.Ghost:SetColor(Color(c.r, c.g, c.b, a))

            self.Ghost:SetNoDraw(false)
         end
      end
   end

   local linex = 0
   local liney = 0
   local laser = Material("trails/laser")

   SWEP.vRenderOrder = nil
   function SWEP:ViewModelDrawn()

      local client = LocalPlayer()
      local vm = client:GetViewModel()
      if not IsValid(vm) then return end

      if !IsValid(vm) then return end
		
		if (!self.VElements) then return end
		
		self:UpdateBonePositions(vm)

		if (!self.vRenderOrder) then
			
			-- we build a render order because sprites need to be drawn after models
			self.vRenderOrder = {}

			for k, v in pairs( self.VElements ) do
				if (v.type == "Model") then
					table.insert(self.vRenderOrder, 1, k)
				elseif (v.type == "Sprite" or v.type == "Quad") then
					table.insert(self.vRenderOrder, k)
				end
			end
			
		end

		for k, name in ipairs( self.vRenderOrder ) do
		
			local v = self.VElements[name]
			if (!v) then self.vRenderOrder = nil break end
			if (v.hide) then continue end
			
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			
			if (!v.bone) then continue end
			
			local pos, ang = self:GetBoneOrientation( self.VElements, v, vm )
			
			if (!pos) then continue end
			
			if (v.type == "Model" and IsValid(model)) then

				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				--model:SetModelScale(v.size)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix( "RenderMultiply", matrix )
				
				if (v.material == "") then
					model:SetMaterial("")
				elseif (model:GetMaterial() != v.material) then
					model:SetMaterial( v.material )
				end
				
				if (v.skin and v.skin != model:GetSkin()) then
					model:SetSkin(v.skin)
				end
				
				if (v.bodygroup) then
					for k, v in pairs( v.bodygroup ) do
						if (model:GetBodygroup(k) != v) then
							model:SetBodygroup(k, v)
						end
					end
				end
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(true)
				end
				
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(false)
				end
				
			elseif (v.type == "Sprite" and sprite) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
				
			elseif (v.type == "Quad" and v.draw_func) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func( self )
				cam.End3D2D()

			end
			
		end

      local plytr = client:GetEyeTrace(MASK_SHOT)

      local muzzle_angpos = vm:GetAttachment(1)
      local spos = muzzle_angpos.Pos + muzzle_angpos.Ang:Forward() * 10
      local epos = client:GetShootPos() + client:GetAimVector() * self.MaxRange

      -- Painting beam
      local tr = util.TraceLine({start=spos, endpos=epos, filter=client, mask=MASK_ALL})

      local c = COLOR_RED
      local a = 150
      local d = (plytr.StartPos - plytr.HitPos):Length()
      if plytr.HitNonWorld then
         if ValidTarget(plytr.Entity) then
            if d < self.MaxRange then
               c = COLOR_GREEN
               a = 255
            else
               c = COLOR_YELLOW
            end
         end
      end

      self:UpdateGhost(plytr.HitPos, c, a)

      render.SetMaterial(laser)
      render.DrawBeam(spos, tr.HitPos, 5, 0, 0, c)

      -- Charge indicator
      local vm_ang = muzzle_angpos.Ang
      local cpos = muzzle_angpos.Pos + (vm_ang:Up() * -8) + (vm_ang:Forward() * -5.5) + (vm_ang:Right() * 0)
      local cang = vm:GetAngles()
      cang:RotateAroundAxis(cang:Forward(), 90)
      cang:RotateAroundAxis(cang:Right(), 90)
      cang:RotateAroundAxis(cang:Up(), 90)

      cam.Start3D2D(cpos, cang, 0.05)

      surface.SetDrawColor(255, 55, 55, 50)
      surface.DrawOutlinedRect(0, 0, 50, 15)

      local sz = 48
      local next = self:GetNextPrimaryFire()
      local ready = (next - CurTime()) <= 0
      local frac = 1.0
      if not ready then
         frac = 1 - ((next - CurTime()) / self.Primary.Delay)
         sz = sz * math.max(0, frac)
      end

      surface.SetDrawColor(255, 10, 10, 170)
      surface.DrawRect(1, 1, sz, 13)

      surface.SetTextColor(255,255,255,15)
      surface.SetFont("Default")
      surface.SetTextPos(2,0)
      surface.DrawText(string.format("%.3f", around(frac)))

      surface.SetDrawColor(0,0,0, 80)
      surface.DrawRect(linex, 1, 3, 13)

      surface.DrawLine(1, liney, 48, liney)

      linex = linex + 3 > 48 and 0 or linex + 1
      liney = liney > 13 and 0 or liney + 1

      cam.End3D2D()

   end

   SWEP.wRenderOrder = nil
	function SWEP:DrawWorldModel()
		
		if (self.ShowWorldModel == nil or self.ShowWorldModel) then
			self:DrawModel()
		end
		
		if (!self.WElements) then return end
		
		if (!self.wRenderOrder) then

			self.wRenderOrder = {}

			for k, v in pairs( self.WElements ) do
				if (v.type == "Model") then
					table.insert(self.wRenderOrder, 1, k)
				elseif (v.type == "Sprite" or v.type == "Quad") then
					table.insert(self.wRenderOrder, k)
				end
			end

		end
		
		if (IsValid(self.Owner)) then
			bone_ent = self.Owner
		else
			-- when the weapon is dropped
			bone_ent = self
		end
		
		for k, name in pairs( self.wRenderOrder ) do
		
			local v = self.WElements[name]
			if (!v) then self.wRenderOrder = nil break end
			if (v.hide) then continue end
			
			local pos, ang
			
			if (v.bone) then
				pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent )
			else
				pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand" )
			end
			
			if (!pos) then continue end
			
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			
			if (v.type == "Model" and IsValid(model)) then

				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				--model:SetModelScale(v.size)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix( "RenderMultiply", matrix )
				
				if (v.material == "") then
					model:SetMaterial("")
				elseif (model:GetMaterial() != v.material) then
					model:SetMaterial( v.material )
				end
				
				if (v.skin and v.skin != model:GetSkin()) then
					model:SetSkin(v.skin)
				end
				
				if (v.bodygroup) then
					for k, v in pairs( v.bodygroup ) do
						if (model:GetBodygroup(k) != v) then
							model:SetBodygroup(k, v)
						end
					end
				end
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(true)
				end
				
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(false)
				end
				
			elseif (v.type == "Sprite" and sprite) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
				
			elseif (v.type == "Quad" and v.draw_func) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func( self )
				cam.End3D2D()

         end
		end	
   end

   function SWEP:GetBoneOrientation( basetab, tab, ent, bone_override )
		
		local bone, pos, ang
		if (tab.rel and tab.rel != "") then
			
			local v = basetab[tab.rel]
			
			if (!v) then return end
			

			pos, ang = self:GetBoneOrientation( basetab, v, ent )
			
			if (!pos) then return end
			
			pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
		else
		
			bone = ent:LookupBone(bone_override or tab.bone)

			if (!bone) then return end
			
			pos, ang = Vector(0,0,0), Angle(0,0,0)
			local m = ent:GetBoneMatrix(bone)
			if (m) then
				pos, ang = m:GetTranslation(), m:GetAngles()
			end
			
			if (IsValid(self.Owner) and self.Owner:IsPlayer() and 
				ent == self.Owner:GetViewModel() and self.ViewModelFlip) then
				ang.r = -ang.r -- Fixes mirrored models
			end
		
		end
		
		return pos, ang
	end

	function SWEP:CreateModels( tab )

		if (!tab) then return end

		for k, v in pairs( tab ) do
			if (v.type == "Model" and v.model and v.model != "" and (!IsValid(v.modelEnt) or v.createdModel != v.model) and 
					string.find(v.model, ".mdl") and file.Exists (v.model, "GAME") ) then
				
				v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
				if (IsValid(v.modelEnt)) then
					v.modelEnt:SetPos(self:GetPos())
					v.modelEnt:SetAngles(self:GetAngles())
					v.modelEnt:SetParent(self)
					v.modelEnt:SetNoDraw(true)
					v.createdModel = v.model
				else
					v.modelEnt = nil
				end
				
			elseif (v.type == "Sprite" and v.sprite and v.sprite != "" and (!v.spriteMaterial or v.createdSprite != v.sprite) 
				and file.Exists ("materials/"..v.sprite..".vmt", "GAME")) then
				
				local name = v.sprite.."-"
				local params = { ["$basetexture"] = v.sprite }
				-- make sure we create a unique name based on the selected options
				local tocheck = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
				for i, j in pairs( tocheck ) do
					if (v[j]) then
						params["$"..j] = 1
						name = name.."1"
					else
						name = name.."0"
					end
				end

				v.createdSprite = v.sprite
				v.spriteMaterial = CreateMaterial(name,"UnlitGeneric",params)
				
			end
		end
		
	end
	
	local allbones
	local hasGarryFixedBoneScalingYet = false

	function SWEP:UpdateBonePositions(vm)
		
		if self.ViewModelBoneMods then
			
			if (!vm:GetBoneCount()) then return end
			
			-- !! WORKAROUND !! --
			-- We need to check all model names :/
			local loopthrough = self.ViewModelBoneMods
			if (!hasGarryFixedBoneScalingYet) then
				allbones = {}
				for i=0, vm:GetBoneCount() do
					local bonename = vm:GetBoneName(i)
					if (self.ViewModelBoneMods[bonename]) then 
						allbones[bonename] = self.ViewModelBoneMods[bonename]
					else
						allbones[bonename] = { 
							scale = Vector(1,1,1),
							pos = Vector(0,0,0),
							angle = Angle(0,0,0)
						}
					end
				end
				
				loopthrough = allbones
			end
			-- !! ----------- !! --
			
			for k, v in pairs( loopthrough ) do
				local bone = vm:LookupBone(k)
				if (!bone) then continue end
				
				-- !! WORKAROUND !! --
				local s = Vector(v.scale.x,v.scale.y,v.scale.z)
				local p = Vector(v.pos.x,v.pos.y,v.pos.z)
				local ms = Vector(1,1,1)
				if (!hasGarryFixedBoneScalingYet) then
					local cur = vm:GetBoneParent(bone)
					while(cur >= 0) do
						local pscale = loopthrough[vm:GetBoneName(cur)].scale
						ms = ms * pscale
						cur = vm:GetBoneParent(cur)
					end
				end
				
				s = s * ms
				-- !! ----------- !! --
				
				if vm:GetManipulateBoneScale(bone) != s then
					vm:ManipulateBoneScale( bone, s )
				end
				if vm:GetManipulateBoneAngles(bone) != v.angle then
					vm:ManipulateBoneAngles( bone, v.angle )
				end
				if vm:GetManipulateBonePosition(bone) != p then
					vm:ManipulateBonePosition( bone, p )
				end
			end
		else
			self:ResetBonePositions(vm)
		end
		   
	end
	 
	function SWEP:ResetBonePositions(vm)
		
		if (!vm:GetBoneCount()) then return end
		for i=0, vm:GetBoneCount() do
			vm:ManipulateBoneScale( i, Vector(1, 1, 1) )
			vm:ManipulateBoneAngles( i, Angle(0, 0, 0) )
			vm:ManipulateBonePosition( i, Vector(0, 0, 0) )
		end
		
	end


	function table.FullCopy( tab )

		if (!tab) then return nil end
		
		local res = {}
		for k, v in pairs( tab ) do
			if (type(v) == "table") then
				res[k] = table.FullCopy(v)
			elseif (type(v) == "Vector") then
				res[k] = Vector(v.x, v.y, v.z)
			elseif (type(v) == "Angle") then
				res[k] = Angle(v.p, v.y, v.r)
			else
				res[k] = v
			end
		end
		
		return res
		
	end

   local draw = draw
   function SWEP:DrawHUD()
      local x = ScrW() / 2.0
      local y = ScrH() / 2.0


      local charge = self.dt.charge

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
         surface.DrawText("CHARGE")
      end
   end
end

function SWEP:Deploy()
   self.Weapon:SendWeaponAnim(ACT_VM_DRAW);
	self:SetNextPrimaryFire( CurTime() + self:SequenceDuration())
	self:SetNextSecondaryFire( CurTime() + self:SequenceDuration())
	self:NextThink( CurTime() + self:SequenceDuration() )
	self:EmitSound("weapons/tfdisplacer/activate.wav")

   return true
end