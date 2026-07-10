AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    -- Инициализация физики и коллизий
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    
    -- Разрешаем использование через кнопку E
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    local linked = self:GetLinkedTeleporter()
    if not IsValid(linked) then
        activator:ChatPrint("Этот телепорт ни с чем не связан!")
        return
    end

    -- Защита от спама (чтобы игрок не застрял в цикле)
    if activator.TeleportCooldown and activator.TeleportCooldown > CurTime() then return end

    -- Вычисляем точку появления (чуть спереди и выше связанного телепорта)
    local destPos = linked:GetPos() + linked:GetForward() * 50 + Vector(0, 0, 10)

    -- Звуковые эффекты телепортации
    activator:EmitSound("ambient/machines/teleport1.wav")
    linked:EmitSound("ambient/machines/teleport4.wav")

    -- Перемещение игрока
    activator:SetPos(destPos)
    
    -- Поворачиваем камеру игрока от телепорта
    local newAngle = linked:GetForward():Angle()
    activator:SetEyeAngles(Angle(0, newAngle.y, 0))

    -- Устанавливаем задержку в 1.5 секунды перед следующим использованием
    activator.TeleportCooldown = CurTime() + 1.5
end