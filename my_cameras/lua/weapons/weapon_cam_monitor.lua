AddCSLuaFile()

if SERVER then
util.AddNetworkString("CamMonitor_OpenUI")
util.AddNetworkString("CamMonitor_CloseUI")
util.AddNetworkString("CamMonitor_SwitchCam")
util.AddNetworkString("CamMonitor_DeleteCam")
util.AddNetworkString("CamMonitor_ExitCam")

net.Receive("CamMonitor_SwitchCam", function(len, ply)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep:GetClass() == "weapon_cam_monitor" then
        wep:SwitchCamera(ply, net.ReadInt(8))
    end
end)

net.Receive("CamMonitor_DeleteCam", function(len, ply)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep:GetClass() == "weapon_cam_monitor" then
        wep:DeleteCurrentCamera(ply)
    end
end)

net.Receive("CamMonitor_ExitCam", function(len, ply)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep:GetClass() == "weapon_cam_monitor" then
        wep:ExitCamera(ply)
    end
end)


end

SWEP.PrintName = "Монитор камер"
SWEP.Author = "ratbar1999"
SWEP.Instructions = "ЛКМ: Установка/Снятие\nПКМ: Просмотр\nВ камере: WASD - полет, Пробел/Ctrl - вверх/вниз"
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
SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"

function SWEP:UpdateValidCams(ply)
ply.MyCams = ply.MyCams or {}
local validCams = {}
for _, cam in ipairs(ply.MyCams) do
if IsValid(cam) then
table.insert(validCams, cam)
end
end
ply.MyCams = validCams
return validCams
end

function SWEP:PrimaryAttack()
self:SetNextPrimaryFire(CurTime() + 0.5)
self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

local ply = self:GetOwner()
if IsValid(ply) then ply:SetAnimation(PLAYER_ATTACK1) end

if CLIENT then return end
if not IsValid(ply) then return end

if ply:GetViewEntity() ~= ply then
    ply:ChatPrint("Выйди из просмотра камер для установки!")
    return
end

local tr = util.TraceLine({
    start = ply:GetShootPos(),
    endpos = ply:GetShootPos() + ply:GetAimVector() * 150,
    filter = ply
})

if IsValid(tr.Entity) and tr.Entity:GetClass() == "sent_vsky_camera" then
    if tr.Entity:GetOwner() == ply then
        tr.Entity:Remove()
        ply:ChatPrint("Камера снята руками.")
        self:EmitSound("weapons/physcannon/physcannon_drop.wav")
    end
    return
end

if tr.Hit and not tr.HitSky then
    local cam = ents.Create("sent_vsky_camera")
    if not IsValid(cam) then return end

    cam:SetPos(tr.HitPos + tr.HitNormal * 20)
    cam:SetAngles(ply:EyeAngles()) 
    cam:SetOwner(ply)
    cam:Spawn()

    self:UpdateValidCams(ply)
    table.insert(ply.MyCams, cam)

    ply:ChatPrint("Дрон установлен! (Всего: " .. #ply.MyCams .. ")")
    self:EmitSound("weapons/pistol/pistol_empty.wav")
end


end

function SWEP:SecondaryAttack()
self:SetNextSecondaryFire(CurTime() + 0.5)
self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

if CLIENT then return end

local ply = self:GetOwner()
if not IsValid(ply) then return end
if ply:GetViewEntity() ~= ply then return end

local validCams = self:UpdateValidCams(ply)
if #validCams == 0 then
    ply:ChatPrint("У тебя нет активных камер!")
    return
end

ply.CamIndex = 1
ply:SetViewEntity(validCams[ply.CamIndex])

net.Start("CamMonitor_OpenUI")
net.Send(ply)


end

function SWEP:SwitchCamera(ply, dir)
local validCams = self:UpdateValidCams(ply)
if #validCams == 0 then self:ExitCamera(ply) return end

ply.CamIndex = (ply.CamIndex or 1) + dir
if ply.CamIndex > #validCams then ply.CamIndex = 1 end
if ply.CamIndex < 1 then ply.CamIndex = #validCams end

ply:SetViewEntity(validCams[ply.CamIndex])


end

function SWEP:DeleteCurrentCamera(ply)
local validCams = self:UpdateValidCams(ply)
if #validCams == 0 then self:ExitCamera(ply) return end

local activeCam = validCams[ply.CamIndex or 1]

ply:SetViewEntity(ply)

if IsValid(activeCam) then
    activeCam:Remove()
    ply:ChatPrint("Камера уничтожена дистанционно!")
end

table.remove(ply.MyCams, ply.CamIndex or 1)
local remaining = self:UpdateValidCams(ply)

if #remaining == 0 then
    self:ExitCamera(ply)
else
    if ply.CamIndex > #remaining then ply.CamIndex = 1 end
    ply:SetViewEntity(remaining[ply.CamIndex])
end


end

function SWEP:ExitCamera(ply)
if not IsValid(ply) then return end
if ply:GetViewEntity() ~= ply then ply:SetViewEntity(ply) end
net.Start("CamMonitor_CloseUI")
net.Send(ply)
end

function SWEP:Reload()
if CLIENT then return end
local ply = self:GetOwner()
if IsValid(ply) and ply:GetViewEntity() ~= ply then self:ExitCamera(ply) end
end

function SWEP:Holster()
if SERVER then
local ply = self:GetOwner()
if IsValid(ply) and ply:GetViewEntity() ~= ply then self:ExitCamera(ply) end
end
return true
end

function SWEP:OnRemove()
if SERVER then
local ply = self:GetOwner()
if IsValid(ply) and ply:GetViewEntity() ~= ply then self:ExitCamera(ply) end
end
end

hook.Add("StartCommand", "CamMonitor_DroneMovement", function(ply, cmd)
local viewEnt = ply:GetViewEntity()

if IsValid(viewEnt) and viewEnt:GetClass() == "sent_vsky_camera" then
    local ang = cmd:GetViewAngles()
    local forward = ang:Forward()
    local right = ang:Right()
    local up = Vector(0, 0, 1)
    
    local speed = cmd:KeyDown(IN_SPEED) and 15 or 5 
    local dir = Vector(0,0,0)
    
    if cmd:KeyDown(IN_FORWARD) then dir:Add(forward) end
    if cmd:KeyDown(IN_BACK) then dir:Sub(forward) end
    if cmd:KeyDown(IN_MOVERIGHT) then dir:Add(right) end
    if cmd:KeyDown(IN_MOVELEFT) then dir:Sub(right) end
    if cmd:KeyDown(IN_JUMP) then dir:Add(up) end
    if cmd:KeyDown(IN_DUCK) then dir:Sub(up) end
    
    if dir:LengthSqr() > 0 then
        dir:Normalize()
        viewEnt:SetPos(viewEnt:GetPos() + dir * speed)
    end
    
    viewEnt:SetAngles(ang)
    
    cmd:ClearMovement()
    cmd:RemoveKey(IN_JUMP)
    cmd:RemoveKey(IN_DUCK)
end


end)

if CLIENT then
local CamUI = nil

net.Receive("CamMonitor_OpenUI", function()
    if IsValid(CamUI) then CamUI:Remove() end

    CamUI = vgui.Create("DFrame")
    CamUI:SetSize(ScrW(), ScrH())
    CamUI:SetPos(0, 0)
    CamUI:SetTitle("")
    CamUI:ShowCloseButton(false)
    CamUI:SetDraggable(false)
    CamUI:MakePopup()
    CamUI:SetKeyboardInputEnabled(false)

    CamUI.Paint = function(self, w, h) end

    CamUI.Think = function(self)
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() or not IsValid(ply:GetActiveWeapon()) or ply:GetActiveWeapon():GetClass() ~= "weapon_cam_monitor" then
            self:Remove()
            return
        end
        
        if input.IsMouseDown(MOUSE_RIGHT) then
            if self:IsMouseInputEnabled() then self:SetMouseInputEnabled(false) end
        else
            if not self:IsMouseInputEnabled() then self:SetMouseInputEnabled(true) end
        end
    end

    local topLabel = vgui.Create("DLabel", CamUI)
    topLabel:SetText("● REC - УДЕРЖИВАЙ ПКМ ДЛЯ ПОВОРОТА КАМЕРЫ")
    topLabel:SetFont("DermaLarge")
    topLabel:SetTextColor(Color(255, 50, 50))
    topLabel:SizeToContents()
    topLabel:SetPos(ScrW() / 2 - topLabel:GetWide() / 2, 50)

    local btnPrev = vgui.Create("DButton", CamUI)
    btnPrev:SetSize(180, 50)
    btnPrev:SetPos(ScrW() / 2 - 190, ScrH() - 150)
    btnPrev:SetText("<- Пред. камера")
    btnPrev:SetTextColor(Color(255, 255, 255))
    btnPrev:SetFont("Trebuchet24")
    btnPrev.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30)) end
    btnPrev.DoClick = function()
        net.Start("CamMonitor_SwitchCam")
        net.WriteInt(-1, 8)
        net.SendToServer()
    end

    local btnNext = vgui.Create("DButton", CamUI)
    btnNext:SetSize(180, 50)
    btnNext:SetPos(ScrW() / 2 + 10, ScrH() - 150)
    btnNext:SetText("След. камера ->")
    btnNext:SetTextColor(Color(255, 255, 255))
    btnNext:SetFont("Trebuchet24")
    btnNext.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30)) end
    btnNext.DoClick = function()
        net.Start("CamMonitor_SwitchCam")
        net.WriteInt(1, 8)
        net.SendToServer()
    end

    local btnDel = vgui.Create("DButton", CamUI)
    btnDel:SetSize(380, 40)
    btnDel:SetPos(ScrW() / 2 - 190, ScrH() - 200)
    btnDel:SetText("Удалить текущую камеру")
    btnDel:SetTextColor(Color(255, 100, 100))
    btnDel:SetFont("Trebuchet24")
    btnDel.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30)) end
    btnDel.DoClick = function()
        net.Start("CamMonitor_DeleteCam")
        net.SendToServer()
    end

    local btnExit = vgui.Create("DButton", CamUI)
    btnExit:SetSize(380, 40)
    btnExit:SetPos(ScrW() / 2 - 190, ScrH() - 90)
    btnExit:SetText("Выйти из системы (или R)")
    btnExit:SetTextColor(Color(255, 255, 255))
    btnExit:SetFont("Trebuchet24")
    btnExit.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30)) end
    btnExit.DoClick = function()
        net.Start("CamMonitor_ExitCam")
        net.SendToServer()
    end
end)

net.Receive("CamMonitor_CloseUI", function()
    if IsValid(CamUI) then
        CamUI:Remove()
        CamUI = nil
    end
end)


end