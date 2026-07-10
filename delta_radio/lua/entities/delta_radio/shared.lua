ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Радио"
ENT.Author = "ratbar1999"
ENT.Category = "Radios"
ENT.Spawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "SongName")
    self:NetworkVar("Bool", 0, "IsPlaying")
    self:NetworkVar("Float", 0, "RadioVolume")
    self:NetworkVar("Bool", 1, "Loop")
end