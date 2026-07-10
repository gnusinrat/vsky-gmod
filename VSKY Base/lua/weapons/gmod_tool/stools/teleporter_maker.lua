TOOL.Tab = "VSKY"
TOOL.Category = "VSKY_Tools"
TOOL.Name = "Создатель Телепортов"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["model"] = "models/props_interiors/VendingMachineSoda01a.mdl"

if CLIENT then
language.Add("tool.teleporter_maker.name", "Создатель Телепортов")
language.Add("tool.teleporter_maker.desc", "Создает связанные телепорты")
language.Add("tool.teleporter_maker.0", "ЛКМ: Создать телепорт. Поставь два, чтобы связать. ПКМ: Сбросить выбор.")
end

function TOOL:LeftClick(trace)
if not trace.HitPos then return false end
if IsValid(trace.Entity) and trace.Entity:IsPlayer() then return false end
if CLIENT then return true end

local ply = self:GetOwner()
local model = self:GetClientInfo("model")

-- Подстраховка модели
if not model or model == "" then
    model = "models/props_interiors/VendingMachineSoda01a.mdl"
end

local ent = ents.Create("ent_vsky_teleporter")
if not IsValid(ent) then 
    ply:ChatPrint("[ОШИБКА] Телепорт не создан! GMod потерял файлы энтити.")
    return false 
end

ent:SetPos(trace.HitPos)

local ang = (ply:GetPos() - trace.HitPos):Angle()
ang.p = 0
ang.r = 0
ent:SetAngles(ang)

ent:SetModel(model)
ent:Spawn()
ent:Activate()

local phys = ent:GetPhysicsObject()
if IsValid(phys) then phys:EnableMotion(false) end

undo.Create("Телепорт")
undo.AddEntity(ent)
undo.SetPlayer(ply)
undo.Finish()

-- Использование GetNWEntity
local firstTeleporter = self:GetWeapon():GetNWEntity("RatbarFirstTeleporter")

if IsValid(firstTeleporter) then
    firstTeleporter:SetLinkedTeleporter(ent)
    ent:SetLinkedTeleporter(firstTeleporter)
    ply:ChatPrint("Телепорты успешно связаны! Нажми 'E' на одном из них.")
    self:GetWeapon():SetNWEntity("RatbarFirstTeleporter", NULL)
else
    self:GetWeapon():SetNWEntity("RatbarFirstTeleporter", ent)
    ply:ChatPrint("Первый телепорт установлен. Поставь второй для связи.")
end

return true


end

function TOOL:RightClick(trace)
if CLIENT then return true end
self:GetWeapon():SetNWEntity("RatbarFirstTeleporter", NULL)
self:GetOwner():ChatPrint("Выбор первого телепорта сброшен.")
return true
end

function TOOL.BuildCPanel(panel)
panel:AddControl("Header", {
Text = "Создатель Телепортов",
Description = "Выбери модель для телепорта и кликни ЛКМ для установки."
})

local list = vgui.Create("DComboBox", panel)
list:Dock(TOP)
list:DockMargin(0, 0, 0, 10)
list:SetValue("Выбери модель...")
list:AddChoice("Торговый автомат", "models/props_interiors/VendingMachineSoda01a.mdl")
list:AddChoice("Унитаз", "models/props_c17/FurnitureToilet001a.mdl")
list:AddChoice("Раковина", "models/props_wasteland/kitchen_sink001a.mdl")
list:AddChoice("Дверь", "models/props_c17/door01_left.mdl")
list:AddChoice("Холодильник", "models/props_c17/FurnitureFridge001a.mdl")
list:AddChoice("Стиральная машина", "models/props_c17/FurnitureWashingmachine001a.mdl")

list.OnSelect = function(self, index, value, data)
    RunConsoleCommand("teleporter_maker_model", data)
end
panel:AddItem(list)


end