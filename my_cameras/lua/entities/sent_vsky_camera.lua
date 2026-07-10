AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Дрон-камера"
ENT.Author = "ratbar1999"
ENT.Spawnable = false

if SERVER then
function ENT:Initialize()
self:SetModel("models/dav0r/camera.mdl")

    -- ПОЛНОСТЬЮ НОВАЯ ФИЗИКА: ДРОН
    self:PhysicsInit(SOLID_VPHYSICS)
    
    -- MOVETYPE_NOCLIP позволяет камере свободно летать сквозь стены
    -- когда мы двигаем её кодом (на WASD), без багов столкновений!
    self:SetMoveType(MOVETYPE_NOCLIP) 
    self:SetSolid(SOLID_VPHYSICS)
    
    -- Делаем так, чтобы она не мешала игрокам ходить, но в неё попадал луч для удаления
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableGravity(false) -- Отключаем гравитацию
    end
end


end

if CLIENT then
function ENT:Draw()
self:DrawModel()
end
end