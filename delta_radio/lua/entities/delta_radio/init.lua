AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("DeltaRadio_OpenMenu")
util.AddNetworkString("DeltaRadio_Command")
util.AddNetworkString("DeltaRadio_ClientAction")

function ENT:Initialize()
    self:SetModel("models/props_lab/citizenradio.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    self:SetSongName("")
    self:SetIsPlaying(false)
    self:SetRadioVolume(1.0)
    self:SetLoop(false)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:Use(activator, caller)
    if IsValid(activator) and activator:IsPlayer() then
        net.Start("DeltaRadio_OpenMenu")
        net.WriteEntity(self)
        net.Send(activator)
    end
end

net.Receive("DeltaRadio_Command", function(len, ply)
    local ent = net.ReadEntity()
    local cmd = net.ReadString()

    if not IsValid(ent) or ent:GetClass() ~= "delta_radio" then return end

    if cmd == "play_song" then
        local song = net.ReadString()
        ent:SetSongName(song)
        ent:SetIsPlaying(true)
    elseif cmd == "toggle_pause" then
        ent:SetIsPlaying(not ent:GetIsPlaying())
    elseif cmd == "set_volume" then
        local vol = net.ReadFloat()
        ent:SetRadioVolume(vol)
    elseif cmd == "set_loop" then
        local loop = net.ReadBool()
        ent:SetLoop(loop)
    elseif cmd == "seek" then
        local time = net.ReadFloat()
        net.Start("DeltaRadio_ClientAction")
        net.WriteEntity(ent)
        net.WriteString("seek")
        net.WriteFloat(time)
        net.Broadcast()
    end
end)