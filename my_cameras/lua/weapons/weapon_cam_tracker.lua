AddCSLuaFile()

SWEP.PrintName = "Создатель жучков"
SWEP.Author = "ratbar1999"
SWEP.Instructions = "ЛКМ: Прицепить камеру к объекту или игроку"
SWEP.Spawnable = true
SWEP.Category = "RatiCameras"
SWEP.Base = "weapon_base"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"

function SWEP:PrimaryAttack()
self:SetNextPrimaryFire(CurTime() + 0.5)

self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
local ply = self:GetOwner()
if IsValid(ply) then ply:SetAnimation(PLAYER_ATTACK1) end

if CLIENT then return end
if not IsValid(ply) then return end

local tr = util.TraceLine({
    start = ply:GetShootPos(),
    endpos = ply:GetShootPos() + ply:GetAimVector() * 2000,
    filter = ply
})

if tr.Hit and not tr.HitSky then
    local hitEnt = tr.Entity

    if IsValid(hitEnt) and not hitEnt:IsWorld() then
        if hitEnt:GetClass() == "sent_vsky_camera" then return end

        local cam = ents.Create("sent_vsky_camera")
        if not IsValid(cam) then return end

        cam:SetPos(tr.HitPos + tr.HitNormal * 50)
        cam:SetAngles(ply:EyeAngles()) 
        cam:SetOwner(ply)
        cam:Spawn()

        cam:SetCollisionGroup(COLLISION_GROUP_WORLD)
        cam:SetParent(hitEnt)

        ply.MyCams = ply.MyCams or {}
        
        local validCams = {}
        for _, c in ipairs(ply.MyCams) do
            if IsValid(c) then table.insert(validCams, c) end
        end
        ply.MyCams = validCams
        
        table.insert(ply.MyCams, cam)

        ply:ChatPrint("Жучок прикреплен к " .. hitEnt:GetClass() .. "!")
        self:EmitSound("weapons/crossbow/hit1.wav")
    else
        ply:ChatPrint("Нужно попасть в проп, объект или игрока!")
    end
end


end

function SWEP:SecondaryAttack()
end