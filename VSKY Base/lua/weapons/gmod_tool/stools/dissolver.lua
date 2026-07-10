TOOL.Tab = "VSKY"
TOOL.Category = "VSKY_Tools"
TOOL.Name = "Диссолвер"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
language.Add("tool.dissolver.name", "Диссолвер")
language.Add("tool.dissolver.desc", "Расщепляет объекты на атомы")
language.Add("tool.dissolver.0", "ЛКМ: Испепелить объект")
end

function TOOL:LeftClick(trace)
if not IsValid(trace.Entity) then return false end
if trace.Entity:IsWorld() or trace.Entity:IsPlayer() then return false end
if CLIENT then return true end

local ent = trace.Entity
local targetName = "dissolve_target_" .. ent:EntIndex() .. "_" .. math.random(1, 9999)
ent:SetName(targetName)

local dissolver = ents.Create("env_entity_dissolver")
if not IsValid(dissolver) then return false end

dissolver:SetPos(ent:GetPos())
dissolver:SetKeyValue("target", targetName)
dissolver:SetKeyValue("dissolvetype", "0")
dissolver:SetKeyValue("magnitude", "100")
dissolver:Spawn()
dissolver:Activate()

dissolver:Fire("Dissolve", targetName, 0)
dissolver:Fire("Kill", "", 0.1)

self:GetWeapon():EmitSound("Weapon_AR2.Single")
return true


end

function TOOL.BuildCPanel(panel)
panel:AddControl("Header", { Text = "Диссолвер", Description = "Испепеляет" })
end