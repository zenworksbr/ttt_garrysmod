--[[Author informations]]--
SWEP.Author = "Zaratusa"
SWEP.Contact = "http://steamcommunity.com/profiles/76561198032479768"

if SERVER then
	AddCSLuaFile()
	resource.AddWorkshop("253736639")
else

	SWEP.Slot = 2
	SWEP.Icon = "vgui/ttt/icon_famas"

	-- client side model settings
	SWEP.UseHands = true -- should the hands be displayed
	SWEP.ViewModelFlip = false -- should the weapon be hold with the left or the right hand
	SWEP.ViewModelFOV = 64
end

SWEP.PrintName = "Famas"

-- always derive from weapon_tttbase
SWEP.Base = "weapon_tttbase"

--[[Default GMod values]]--
SWEP.Primary.Ammo = "SMG1"
SWEP.Primary.Delay = 0.08
SWEP.Primary.Recoil = 0.8
SWEP.Primary.Cone = 0.025
SWEP.Primary.Damage = 17
SWEP.Primary.Automatic = true
SWEP.Primary.ClipSize = 30
SWEP.Primary.ClipMax = 60
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Sound = Sound("Weapon_FAMAS.Single")
-- SWEP.Secondary.Sound = Sound("weapons/famas/famas-burst.wav")
-- SWEP.Primary.AlternateSound = Sound("weapons/glock/glock_sliderelease.wav")

-- Alternate fire mode
-- SWEP.Primary.Mode = SWEP.Primary.Mode or "auto"
-- print(SWEP.Primary.Mode)
-- SWEP.Primary.BurstAmount   	= 3
-- SWEP.Primary.BurstDelay	   	= 0.04
-- SWEP.Secondary.Delay		= 0.8

--[[Model settings]]--
SWEP.HoldType = "ar2"
SWEP.ViewModel = Model("models/weapons/cstrike/c_rif_famas.mdl")
SWEP.WorldModel = Model("models/weapons/w_rif_famas.mdl")

SWEP.IronSightsPos = Vector(-6.24, -2.757, 1.2)
SWEP.IronSightsAng = Vector(0.2, 0, -1)

SWEP.NoSights = true

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
SWEP.NoSights = true

-- local shooting = shooting or false

-- function SWEP:SecondaryAttack()
-- 	if shooting then return end
-- 	if self.Primary.Mode == "auto" then 
-- 		self.Primary.Mode = "burst"
-- 		self:EmitSound( self.Primary.AlternateSound )
-- 		print(self.Primary.Mode)
-- 	else
-- 		self.Primary.Mode = "auto"
-- 		self:EmitSound( self.Primary.AlternateSound )
-- 		print(self.Primary.Mode)
-- 	end
-- end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then 
		self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )	
		return 
	end
	-- if self.Primary.Mode == "auto" then
	self:TakePrimaryAmmo( 1 )
	self:ShootBullet( self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self:GetPrimaryCone() )
	self:EmitSound( self.Primary.Sound, self.Primary.SoundLevel )
	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	-- else
	-- if not self:CanPrimaryAttack() then return end
	-- timer.Simple(self.Primary.BurstDelay, function() 
	-- 	if self.Weapon != nil then 
	-- self:ShootBullet( self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self:GetPrimaryCone() )
	-- self.Weapon:SetNextPrimaryFire(CurTime() + self.Primary.BurstDelay)
	-- self:EmitSound( self.Secondary.Sound, self.Primary.SoundLevel )
	-- self:TakePrimaryAmmo( 3 )
	-- 	end 
	-- end)
	-- self:SetNextPrimaryFire( CurTime() + self.Secondary.Delay )
	-- end

	local owner = self:GetOwner()
	if not IsValid(owner) or owner:IsNPC() or (not owner.ViewPunch) then return end
 
	owner:ViewPunch( Angle( util.SharedRandom(self:GetClass(),-0.2,-0.1,0) * self.Primary.Recoil, util.SharedRandom(self:GetClass(),-0.1,0.1,1) * self.Primary.Recoil, 0 ) )
end

function SWEP:CanPrimaryAttack()
	if shooting then return false end
	if self.Weapon:Clip1() <= 0 then
	   self:EmitSound( "Weapon_Pistol.Empty" )
	   self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	   self:Reload()
	   return false
	end
	return true
end

function SWEP:GetHeadshotMultiplier(victim, dmginfo)

local att = dmginfo:GetAttacker()
   if not IsValid(att) then return 2 end

   local dist = victim:GetPos():Distance(att:GetPos())
   local d = math.max(0, dist - 150)

   -- decay from 3.2 to 1.7
   return 1.7 + math.max(0, (1.5 - 0.002 * (d ^ 1.25)))

end