AddCSLuaFile()

SWEP.PrintName = "Rouxls Warp" SWEP.Author = "Rouxls Kaard" SWEP.Instructions = "Мини-босс напрокат. Появится, даже если не нанят. " SWEP.Category = "Deltarune" SWEP.Spawnable = true SWEP.AdminOnly = false SWEP.Base = "weapon_base"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.DrawAmmo = false
SWEP.Slot = 3
SWEP.SlotPos = 1

SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.UseHands = true
SWEP.DrawCrosshair = false

if SERVER then
util.AddNetworkString("RouxlsTeleportEffect")
util.AddNetworkString("RouxlsPlayerColorEffect")
end

function SWEP:Initialize()
self:SetHoldType("magic")
end

function SWEP:DrawWorldModel()
-- Пусто, чтобы лом не рисовался
end

function SWEP:Deploy()
local owner = self:GetOwner()
if IsValid(owner) and owner:IsPlayer() then
local rArm = owner:LookupBone("ValveBiped.Bip01_R_UpperArm")
local lArm = owner:LookupBone("ValveBiped.Bip01_L_UpperArm")
if rArm then owner:ManipulateBoneAngles(rArm, Angle(20, -60, 0)) end
if lArm then owner:ManipulateBoneAngles(lArm, Angle(-20, -60, 0)) end
end

if IsValid(self:GetOwner()) then
    local vm = self:GetOwner():GetViewModel()
    if IsValid(vm) then
        vm:SetNoDraw(true)
    end
end
return true


end

function SWEP:Holster()
local owner = self:GetOwner()
if IsValid(owner) and owner:IsPlayer() then
local rArm = owner:LookupBone("ValveBiped.Bip01_R_UpperArm")
local lArm = owner:LookupBone("ValveBiped.Bip01_L_UpperArm")
if rArm then owner:ManipulateBoneAngles(rArm, Angle(0, 0, 0)) end
if lArm then owner:ManipulateBoneAngles(lArm, Angle(0, 0, 0)) end

    local vm = owner:GetViewModel()
    if IsValid(vm) then
        vm:SetNoDraw(false)
    end
    
    if SERVER and owner.IsRouxlsHidden then
        owner:SetNoDraw(false)
        owner:DrawShadow(true)
        owner:SetRenderMode(RENDERMODE_NORMAL)
        owner:SetColor(Color(255, 255, 255, 255))
        owner:SetMaterial("")
        owner:SetNotSolid(false)
        owner:SetMoveType(MOVETYPE_WALK)
        owner:GodDisable()
        owner.IsRouxlsHidden = false
    end
end
return true


end

function SWEP:OnRemove()
self:Holster()
end

function SWEP:PrimaryAttack()
self:SetNextPrimaryFire(CurTime() + 1.5)
local owner = self:GetOwner()
if not IsValid(owner) then return end

if SERVER then
    if owner.IsRouxlsHidden then return end
    owner.IsRouxlsHidden = true -- Защита от спама
    
    net.Start("RouxlsTeleportEffect")
    net.WriteEntity(owner)
    net.WriteVector(owner:GetPos())
    net.Broadcast()

    net.Start("RouxlsPlayerColorEffect")
    net.WriteEntity(owner)
    net.WriteBool(true)
    net.Broadcast()
    
    owner:EmitSound("rouxls/rouxls_warp.mp3", 75, 100)
    
    -- Ровно через 0.5 сек (в момент когда он станет белым) уводим в глухой инвиз
    timer.Simple(0.5, function()
        if IsValid(owner) then
            owner:SetNoDraw(true)
            owner:DrawShadow(false)
            owner:SetRenderMode(RENDERMODE_NONE)
            owner:SetColor(Color(0, 0, 0, 0))
            owner:SetNotSolid(true)
            owner:SetMoveType(MOVETYPE_NOCLIP)
            owner:GodEnable()
        end
    end)
end


end

function SWEP:SecondaryAttack()
self:SetNextSecondaryFire(CurTime() + 1.5)
local owner = self:GetOwner()
if not IsValid(owner) then return end

if SERVER then
    if not owner.IsRouxlsHidden then return end
    owner.IsRouxlsHidden = false
    
    -- Мгновенно возвращаем физику и рендер, чтобы показать эффект цвета
    owner:SetNoDraw(false)
    owner:DrawShadow(true)
    owner:SetRenderMode(RENDERMODE_NORMAL)
    owner:SetColor(Color(255, 255, 255, 255))
    owner:SetMaterial("")
    owner:SetNotSolid(false)
    owner:SetMoveType(MOVETYPE_WALK)
    owner:GodDisable()
    
    net.Start("RouxlsTeleportEffect")
    net.WriteEntity(owner)
    net.WriteVector(owner:GetPos())
    net.Broadcast()

    net.Start("RouxlsPlayerColorEffect")
    net.WriteEntity(owner)
    net.WriteBool(false)
    net.Broadcast()
    
    owner:EmitSound("rouxls/rouxls_warp.mp3", 75, 100)
end


end

if CLIENT then
local ActiveBeams = {}
local ActiveColorEffects = {}
local BeamWhiteMat = Material("vgui/white")

net.Receive("RouxlsTeleportEffect", function()
    local ply = net.ReadEntity()
    local fallbackPos = net.ReadVector()
    table.insert(ActiveBeams, {
        ply = ply,
        pos = fallbackPos,
        startTime = CurTime()
    })
end)

net.Receive("RouxlsPlayerColorEffect", function()
    local ply = net.ReadEntity()
    local isHiding = net.ReadBool()
    if IsValid(ply) then
        table.insert(ActiveColorEffects, {
            ply = ply,
            startTime = CurTime(),
            isHiding = isHiding
        })
    end
end)

hook.Add("PostDrawTranslucentRenderables", "DrawRouxlsLightBeam", function()
    local curTime = CurTime()
    
    for i = #ActiveBeams, 1, -1 do
        local effect = ActiveBeams[i]
        -- УВЕЛИЧЕНО ВРЕМЯ ЖИЗНИ ЛУЧА: теперь луч длится 1.3 секунды, чтобы соответствовать звуку
        local duration = 1.3 
        local progress = (curTime - effect.startTime) / duration 
        
        if progress > 1 then
            table.remove(ActiveBeams, i)
            continue
        end
        
        local pos = effect.pos
        if IsValid(effect.ply) and not effect.ply:IsDormant() then
            pos = effect.ply:GetPos()
        end
        
        -- Прямоугольник РАСШИРЯЕТСЯ из центра
        local width = 0
        if progress < 0.1 then
            width = (progress / 0.1) * 250 -- Резко вырастает в начале (первые 10% времени)
        elseif progress > 0.85 then
            width = (1 - (progress - 0.85) / 0.15) * 250 -- Резко схлопывается ближе к концу звука
        else
            width = 250 -- Стоит на максимальной ширине, пока идет звук
        end
        
        local topPos = pos + Vector(0, 0, 8000)
        
        render.SetMaterial(BeamWhiteMat)
        render.DrawBeam(pos, topPos, width, 0, 1, Color(255, 255, 255, 255))
    end
end)

hook.Add("Think", "RouxlsPlayerColorThink", function()
    local curTime = CurTime()

    for i = #ActiveColorEffects, 1, -1 do
        local effect = ActiveColorEffects[i]
        -- Анимация цвета по-прежнему длится 0.5 секунд, чтобы игрок успел пропасть
        local progress = (curTime - effect.startTime) / 0.5

        if progress > 1 then
            if IsValid(effect.ply) then
                effect.ply:SetMaterial("")
                if not effect.isHiding then
                    effect.ply:SetRenderMode(RENDERMODE_NORMAL)
                    effect.ply:SetColor(Color(255, 255, 255, 255))
                end
            end
            table.remove(ActiveColorEffects, i)
            continue
        end

        if IsValid(effect.ply) and not effect.ply:IsDormant() then
            effect.ply:SetRenderMode(RENDERMODE_TRANSCOLOR)
            local rg
            
            if effect.isHiding then
                -- ИСЧЕЗНОВЕНИЕ: Обычный -> Плоский Синий -> Плоский Белый
                if progress < 0.5 then
                    rg = 255 * (1 - (progress * 2))
                    effect.ply:SetMaterial("")
                    effect.ply:SetColor(Color(rg, rg, 255, 255))
                else
                    rg = 255 * ((progress - 0.5) * 2)
                    effect.ply:SetMaterial("models/debug/debugwhite")
                    effect.ply:SetColor(Color(rg, rg, 255, 255))
                end
            else
                -- ПОЯВЛЕНИЕ: Плоский Белый -> Плоский Синий -> Обычный
                if progress < 0.5 then
                    rg = 255 * (1 - (progress * 2))
                    effect.ply:SetMaterial("models/debug/debugwhite")
                    effect.ply:SetColor(Color(rg, rg, 255, 255))
                else
                    rg = 255 * ((progress - 0.5) * 2)
                    effect.ply:SetMaterial("")
                    effect.ply:SetColor(Color(rg, rg, 255, 255))
                end
            end
        end
    end
end)


end