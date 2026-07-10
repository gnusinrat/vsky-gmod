ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Телепорт"
ENT.Author = "ratbar1999"
ENT.Spawnable = false

function ENT:SetupDataTables()
    -- Синхронизируем связанный телепорт между сервером и клиентом
    self:NetworkVar("Entity", 0, "LinkedTeleporter")
end