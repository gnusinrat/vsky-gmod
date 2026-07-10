AddCSLuaFile()

SWEP.PrintName = "Tranquilizer Gun (VSKY)"
SWEP.Author = "YerSoMashy + ratbar1999"
SWEP.Category = "ratbar1999"
SWEP.Instructions = "ЛКМ чтобы усыпить NPC/игрока."
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Base = "weapon_base"

SWEP.ViewModel = "models/lambdaplayers/weapons/c_pist_m9_tranq.mdl"
SWEP.WorldModel = "models/lambdaplayers/weapons/w_pist_m9_tranq.mdl"
SWEP.UseHands = true

SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 20
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Pistol"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end

    self:EmitSound("lambdaplayers/weapons/tranqgun/tranqgun_fire.mp3", 75, 100, 1, CHAN_WEAPON)
    self:ShootEffects()
    self:TakePrimaryAmmo(1)

    if SERVER then
        local owner = self:GetOwner()
        local pos = owner:GetShootPos()
        local fwd = owner:GetAimVector()
        
        -- Уникальная функция выстрела
        M9TranqGun_VSKY_FireDart(pos, fwd, owner, self)
    end

    self:SetNextPrimaryFire(CurTime() + 1.5)
    self:Reload()
end

function SWEP:Reload()
    if self:Clip1() < self.Primary.ClipSize and self:GetOwner():GetAmmoCount(self.Primary.Ammo) > 0 then
        self:DefaultReload(ACT_VM_RELOAD)
        self:EmitSound("lambdaplayers/weapons/tranqgun/tranqgun_insert.mp3")

        timer.Simple(0.5, function()
            if IsValid(self) then self:EmitSound("lambdaplayers/weapons/tranqgun/tranqgun_slide.mp3") end
        end)
    end
end