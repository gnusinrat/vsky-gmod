if SERVER then
    util.AddNetworkString("vsky_gaben_menu")
    util.AddNetworkString("vsky_gaben_lasercolor")
    util.AddNetworkString("vsky_gaben_ability")
    util.AddNetworkString("vsky_gaben_warp")
    util.AddNetworkString("vsky_gaben_camlock")
end

SWEP.PrintName = "Кулаки Габена"
SWEP.Author = "ratbar1999"
SWEP.Category = "ratbar1999"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = ""
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.HoldType = "fist"
SWEP.UseHands = true

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:SetupDataTables()
    self:NetworkVar("Float", 0, "ChargeTime")
    self:NetworkVar("Bool", 0, "IsCharging")
    self:NetworkVar("Bool", 1, "IsFiringLaser")
    self:NetworkVar("Vector", 0, "LaserColor")
    self:NetworkVar("Entity", 0, "CamTarget")
end

function SWEP:Deploy()
    if SERVER then
        self:GetOwner():SetMaxHealth(5000000)
        self:GetOwner():SetHealth(5000000)
        if self:GetLaserColor() == Vector(0,0,0) then
            self:SetLaserColor(Vector(1, 0, 0))
        end
    end
    return true
end

function SWEP:PrimaryAttack()
    if not self:GetIsCharging() then
        self:SetIsCharging(true)
        self:SetChargeTime(CurTime())
    end
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
    if SERVER then
        if not self.NextMenu then self.NextMenu = 0 end
        if CurTime() < self.NextMenu then return end
        self.NextMenu = CurTime() + 1
        net.Start("vsky_gaben_menu")
        net.Send(self:GetOwner())
    end
end

function SWEP:Think()
    local ply = self:GetOwner()
    
    if self:GetIsCharging() and not ply:KeyDown(IN_ATTACK) then
        self:SetIsCharging(false)
        local charge = math.Clamp(CurTime() - self:GetChargeTime(), 0, 5)
        local dmg = 100 + (charge * 500)
        
        ply:SetAnimation(PLAYER_ATTACK1)
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        ply:EmitSound("physics/body/body_medium_break2.wav", 100, math.random(80, 120))
        
        if SERVER then
            local tr = util.TraceHull({
                start = ply:GetShootPos(),
                endpos = ply:GetShootPos() + ply:GetAimVector() * 100,
                filter = ply,
                mins = Vector(-20, -20, -20),
                maxs = Vector(20, 20, 20)
            })
            
            if tr.Hit and IsValid(tr.Entity) then
                local d = DamageInfo()
                d:SetDamage(dmg)
                d:SetAttacker(ply)
                d:SetInflictor(self)
                d:SetDamageType(DMG_CLUB)
                tr.Entity:TakeDamageInfo(d)
                
                local push = ply:GetAimVector() * (500 + charge * 2000)
                if tr.Entity:IsPlayer() or tr.Entity:IsNPC() or tr.Entity:IsNextBot() then
                    tr.Entity:SetVelocity(push)
                else
                    local phys = tr.Entity:GetPhysicsObject()
                    if IsValid(phys) then
                        phys:ApplyForceCenter(push * phys:GetMass())
                    end
                end
            end
        end
    end

    if ply:KeyDown(IN_ATTACK2) then
        self:SetIsFiringLaser(true)
        if SERVER then
            local tr = util.TraceLine({
                start = ply:GetShootPos(),
                endpos = ply:GetShootPos() + ply:GetAimVector() * 10000,
                filter = ply
            })
            if tr.Hit then
                local eff = EffectData()
                eff:SetOrigin(tr.HitPos)
                util.Effect("StunstickImpact", eff)
                
                if IsValid(tr.Entity) then
                    tr.Entity:Ignite(5)
                end
            end
        end
    else
        self:SetIsFiringLaser(false)
    end
end

hook.Add("KeyPress", "vsky_gaben_flight", function(ply, key)
    if key == IN_JUMP then
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "swep_vsky_gabenfists" then
            if not ply.vsky_lastjump then ply.vsky_lastjump = 0 end
            if CurTime() - ply.vsky_lastjump < 0.3 then
                ply.vsky_isflying = not ply.vsky_isflying
                if ply.vsky_isflying then
                    ply:SetMoveType(MOVETYPE_FLY)
                else
                    ply:SetMoveType(MOVETYPE_WALK)
                end
            end
            ply.vsky_lastjump = CurTime()
        end
    end
    
    if key == IN_SPEED then
        if not ply.vsky_lastshift then ply.vsky_lastshift = 0 end
        if CurTime() - ply.vsky_lastshift < 0.3 then
            ply.vsky_supershift = true
        else
            ply.vsky_supershift = false
        end
        ply.vsky_lastshift = CurTime()
    end
end)

hook.Add("Move", "vsky_gaben_flightmove", function(ply, mv)
    if ply.vsky_isflying then
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "swep_vsky_gabenfists" then
            ply.vsky_isflying = false
            ply:SetMoveType(MOVETYPE_WALK)
            return
        end
        
        local speed = 1000
        local vel = Vector(0,0,0)
        
        if ply:KeyDown(IN_SPEED) and ply.vsky_supershift then
            speed = 10000
            if ply:KeyDown(IN_FORWARD) then vel = ply:GetAimVector() * speed end
        else
            if ply:KeyDown(IN_SPEED) then speed = 3000 end
            if ply:KeyDown(IN_FORWARD) then vel = vel + ply:GetAimVector() * speed end
            if ply:KeyDown(IN_BACK) then vel = vel - ply:GetAimVector() * speed end
            if ply:KeyDown(IN_MOVERIGHT) then vel = vel + ply:GetRight() * speed end
            if ply:KeyDown(IN_MOVELEFT) then vel = vel - ply:GetRight() * speed end
            
            if vel:LengthSqr() > 0 then vel = vel:GetNormalized() * speed end
            if ply:KeyDown(IN_JUMP) then vel.z = vel.z + speed end
        end
        
        local dt = FrameTime()
        if dt > 0 then
            local origin = mv:GetOrigin()
            local tr = util.TraceHull({
                start = origin,
                endpos = origin + vel * dt,
                mins = ply:OBBMins(),
                maxs = ply:OBBMaxs(),
                filter = ply
            })
            
            if tr.Hit then
                local dot = vel:Dot(tr.HitNormal)
                if dot < 0 then vel = vel - tr.HitNormal * dot end
                
                if SERVER and speed >= 3000 and IsValid(tr.Entity) then
                    ply.vsky_next_ram = ply.vsky_next_ram or 0
                    if CurTime() > ply.vsky_next_ram then
                        ply.vsky_next_ram = CurTime() + 0.3
                        local dmg = DamageInfo()
                        dmg:SetAttacker(ply)
                        dmg:SetInflictor(wep)
                        dmg:SetDamage(speed > 3000 and 1500 or 400)
                        dmg:SetDamageType(DMG_CRUSH)
                        tr.Entity:TakeDamageInfo(dmg)
                        ply:EmitSound("physics/body/body_medium_break2.wav", 120, math.random(80, 100))
                        
                        local push = vel:GetNormalized() * (speed * 1.5)
                        if tr.Entity:IsPlayer() or tr.Entity:IsNPC() or tr.Entity:IsNextBot() then
                            tr.Entity:SetVelocity(push)
                        else
                            local phys = tr.Entity:GetPhysicsObject()
                            if IsValid(phys) then phys:ApplyForceCenter(push * phys:GetMass()) end
                        end
                    end
                end
                
                local tr2 = util.TraceHull({
                    start = tr.HitPos,
                    endpos = tr.HitPos + vel * (dt * (1 - tr.Fraction)),
                    mins = ply:OBBMins(),
                    maxs = ply:OBBMaxs(),
                    filter = ply
                })
                mv:SetOrigin(tr2.HitPos)
            else
                mv:SetOrigin(tr.HitPos)
            end
        end
        
        mv:SetVelocity(vel)
        ply:SetGroundEntity(NULL)
        return true
    end
end)

if SERVER then
    net.Receive("vsky_gaben_lasercolor", function(len, ply)
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "swep_vsky_gabenfists" then
            wep:SetLaserColor(net.ReadVector())
        end
    end)
    
    net.Receive("vsky_gaben_warp", function(len, ply)
        local ent = net.ReadEntity()
        if IsValid(ent) then
            ply:SetPos(ent:GetPos() + Vector(0, 0, 50))
            local wep = ply:GetActiveWeapon()
            if IsValid(wep) and wep:GetClass() == "swep_vsky_gabenfists" then
                wep:SetCamTarget(ent)
            end
        end
    end)

    net.Receive("vsky_gaben_camlock", function(len, ply)
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "swep_vsky_gabenfists" then
            local tr = ply:GetEyeTrace()
            if IsValid(wep:GetCamTarget()) then
                wep:SetCamTarget(NULL)
            elseif IsValid(tr.Entity) then
                wep:SetCamTarget(tr.Entity)
            end
        end
    end)
    
    net.Receive("vsky_gaben_ability", function(len, ply)
        if not ply:IsAdmin() then return end
        local act = net.ReadString()
        
        if act == "killall" then
            for _, e in pairs(ents.GetAll()) do
                if not IsValid(e) or e == ply or e == game.GetWorld() then continue end
                if e:IsPlayer() then
                    e:Kill()
                elseif e:IsNPC() or e:IsNextBot() then
                    local d = DamageInfo()
                    d:SetDamage(999999)
                    d:SetAttacker(ply)
                    d:SetInflictor(ply)
                    e:TakeDamageInfo(d)
                end
            end
        elseif act == "explodeall" then
            for _, e in pairs(ents.GetAll()) do
                if not IsValid(e) or e == ply or e == game.GetWorld() then continue end
                local cls = e:GetClass() or ""
                if e:IsPlayer() or e:IsNPC() or e:IsNextBot() or string.match(cls, "prop_") then
                    local exp = ents.Create("env_explosion")
                    exp:SetPos(e:GetPos())
                    exp:SetOwner(ply)
                    exp:Spawn()
                    exp:SetKeyValue("iMagnitude", "100")
                    exp:Fire("Explode", 0, 0)
                end
            end
        elseif act == "igniteall" then
            for _, e in pairs(ents.GetAll()) do
                if not IsValid(e) or e == ply or e == game.GetWorld() then continue end
                local cls = e:GetClass() or ""
                if e:IsPlayer() or e:IsNPC() or e:IsNextBot() or string.match(cls, "prop_") then
                    e:Ignite(10)
                end
            end
        elseif act == "freezeall" then
            for _, e in pairs(ents.GetAll()) do
                if not IsValid(e) or e == ply or e == game.GetWorld() then continue end
                local cls = e:GetClass() or ""
                if e:IsPlayer() then
                    e:Freeze(true)
                elseif e:IsNPC() or e:IsNextBot() or string.match(cls, "prop_") then
                    local phys = e:GetPhysicsObject()
                    if IsValid(phys) then phys:EnableMotion(false) end
                end
            end
        elseif act == "unfreezeall" then
            for _, e in pairs(ents.GetAll()) do
                if not IsValid(e) or e == ply or e == game.GetWorld() then continue end
                local cls = e:GetClass() or ""
                if e:IsPlayer() then
                    e:Freeze(false)
                elseif e:IsNPC() or e:IsNextBot() or string.match(cls, "prop_") then
                    local phys = e:GetPhysicsObject()
                    if IsValid(phys) then phys:EnableMotion(true) phys:Wake() end
                end
            end
        elseif act == "cleanup" then
            game.CleanUpMap()
        elseif act == "removeents" then
            for _, e in pairs(ents.GetAll()) do
                if not IsValid(e) then continue end
                local cls = e:GetClass() or ""
                if string.match(cls, "prop_physics") or cls == "prop_ragdoll" or (e:IsWeapon() and not IsValid(e:GetOwner())) then
                    e:Remove()
                end
            end
        elseif act == "quake" then
            util.ScreenShake(Vector(0,0,0), 50, 50, 5, 0)
        elseif act == "giveweapons" then
            local weps = {"weapon_physgun", "gmod_tool", "gmod_camera", "weapon_crowbar", "weapon_stunstick", "weapon_pistol", "weapon_357", "weapon_smg1", "weapon_ar2", "weapon_shotgun", "weapon_crossbow", "weapon_frag", "weapon_rpg"}
            for _, w in pairs(weps) do ply:Give(w) end
        elseif act == "zerogravity" then
            RunConsoleCommand("sv_gravity", "0")
        elseif act == "normalgravity" then
            RunConsoleCommand("sv_gravity", "600")
        elseif act == "night" then
            if StormFox2 then StormFox2.Time.Set(0) else RunConsoleCommand("sv_skyname", "painted") end
        elseif act == "day" then
            if StormFox2 then StormFox2.Time.Set(720) else RunConsoleCommand("sv_skyname", "sky_day01_01") end
        elseif act == "spawnallies" then
            for i=1, 5 do
                local e = ents.Create("npc_citizen")
                e:SetPos(ply:GetPos() + Vector(math.random(-100,100), math.random(-100,100), 10))
                e:Spawn()
            end
        elseif act == "killallies" then
            for _, e in pairs(ents.FindByClass("npc_citizen")) do
                if IsValid(e) then 
                    local d = DamageInfo()
                    d:SetDamage(999999)
                    d:SetAttacker(ply)
                    d:SetInflictor(ply)
                    e:TakeDamageInfo(d)
                end
            end
        elseif act == "launchall" then
            for _, e in pairs(ents.GetAll()) do
                if not IsValid(e) or e == ply or e == game.GetWorld() then continue end
                local cls = e:GetClass() or ""
                if e:IsPlayer() or e:IsNPC() or e:IsNextBot() or string.match(cls, "prop_") then
                    if e:IsPlayer() then
                        e:SetPos(e:GetPos() + Vector(0,0,10))
                        e:SetVelocity(Vector(0,0,5000))
                    else
                        local phys = e:GetPhysicsObject()
                        if IsValid(phys) then
                            phys:EnableMotion(true)
                            phys:Wake()
                            phys:SetVelocity(Vector(0,0,5000))
                        end
                        if e.SetVelocity then
                            e:SetVelocity(Vector(0,0,5000))
                        end
                    end
                end
            end
        end
    end)
end

if CLIENT then
    local function PaintDeltaruneGrid(w, h)
        local t = CurTime()
        
        surface.SetDrawColor(40, 0, 40, 255)
        surface.DrawRect(0, 0, w, h)
        
        surface.SetDrawColor(150, 0, 150, 50)
        local off1_x = (t * -20) % 60
        local off1_y = (t * -20) % 60
        for x = off1_x, w, 60 do surface.DrawLine(x, 0, x, h) end
        for y = off1_y, h, 60 do surface.DrawLine(0, y, w, y) end
        
        surface.SetDrawColor(200, 0, 200, 100)
        local off2_x = (t * 40) % 60
        local off2_y = (t * 40) % 60
        for x = off2_x, w, 60 do surface.DrawLine(x, 0, x, h) end
        for y = off2_y, h, 60 do surface.DrawLine(0, y, w, y) end
    end

    net.Receive("vsky_gaben_menu", function()
        local frame = vgui.Create("DFrame")
        frame:SetSize(800, 600)
        frame:Center()
        frame:SetTitle("СВЕРХСПОСОБНОСТИ ГАБЕНА")
        frame:MakePopup()
        
        frame.Paint = function(s, w, h)
            PaintDeltaruneGrid(w, h)
            surface.SetDrawColor(0, 0, 0, 150)
            surface.DrawRect(0, 0, w, 24)
        end
        
        local sheet = vgui.Create("DPropertySheet", frame)
        sheet:Dock(FILL)
        
        local panel_powers = vgui.Create("DPanel", sheet)
        panel_powers.Paint = function() end
        sheet:AddSheet("Способности", panel_powers, "icon16/lightning.png")
        
        local scroll = vgui.Create("DScrollPanel", panel_powers)
        scroll:Dock(FILL)
        
        local layout = vgui.Create("DIconLayout", scroll)
        layout:Dock(FILL)
        layout:SetSpaceY(10)
        layout:SetSpaceX(10)
        
        local abilities = {
            {"Убить всех", "killall"},
            {"Взорвать карту", "explodeall"},
            {"Поджечь всех", "igniteall"},
            {"Заморозить всех", "freezeall"},
            {"Разморозить всех", "unfreezeall"},
            {"Очистить карту", "cleanup"},
            {"Удалить энтити", "removeents"},
            {"Землетрясение", "quake"},
            {"Выдать всё оружие", "giveweapons"},
            {"Убрать гравитацию", "zerogravity"},
            {"Вернуть гравитацию", "normalgravity"},
            {"Сделать ночь", "night"},
            {"Сделать день", "day"},
            {"Заспавнить союзников", "spawnallies"},
            {"Убить союзников", "killallies"},
            {"Запустить всех в космос", "launchall"}
        }
        
        for _, ab in ipairs(abilities) do
            local btn = layout:Add("DButton")
            btn:SetSize(180, 40)
            btn:SetText(ab[1])
            btn:SetTextColor(Color(255,255,255))
            btn.Paint = function(s, w, h)
                draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and Color(80,0,80,200) or Color(40,0,40,200))
                surface.SetDrawColor(255,0,255,100)
                surface.DrawOutlinedRect(0,0,w,h)
            end
            btn.DoClick = function()
                net.Start("vsky_gaben_ability")
                net.WriteString(ab[2])
                net.SendToServer()
            end
        end
        
        local panel_laser = vgui.Create("DPanel", sheet)
        panel_laser.Paint = function() end
        sheet:AddSheet("Цвет лазера", panel_laser, "icon16/color_wheel.png")
        
        local color_mixer = vgui.Create("DColorMixer", panel_laser)
        color_mixer:Dock(FILL)
        color_mixer:SetPalette(true)
        color_mixer:SetAlphaBar(false)
        color_mixer:SetWangs(true)
        
        local ply = LocalPlayer()
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "swep_vsky_gabenfists" then
            local c = wep:GetLaserColor()
            color_mixer:SetColor(Color(c.x * 255, c.y * 255, c.z * 255))
        end
        
        color_mixer.ValueChanged = function(s, col)
            net.Start("vsky_gaben_lasercolor")
            net.WriteVector(Vector(col.r / 255, col.g / 255, col.b / 255))
            net.SendToServer()
        end
        
        local panel_warp = vgui.Create("DPanel", sheet)
        panel_warp.Paint = function() end
        sheet:AddSheet("Варп", panel_warp, "icon16/world_go.png")
        
        local warp_sheet = vgui.Create("DPropertySheet", panel_warp)
        warp_sheet:Dock(FILL)
        
        local function PopulateWarpList(list, filter)
            list:Clear()
            for _, ent in pairs(ents.GetAll()) do
                if filter(ent) then
                    local line = list:AddLine(ent:EntIndex(), ent:GetClass(), ent:IsPlayer() and ent:Nick() or "")
                    line.ent = ent
                end
            end
        end
        
        local function CreateWarpTab(name, filter)
            local p = vgui.Create("DPanel", warp_sheet)
            p.Paint = function() end
            warp_sheet:AddSheet(name, p)
            
            local list = vgui.Create("DListView", p)
            list:Dock(FILL)
            list:AddColumn("ID"):SetMaxWidth(50)
            list:AddColumn("Класс")
            list:AddColumn("Имя")
            
            list.DoDoubleClick = function(s, lineID, line)
                if IsValid(line.ent) then
                    net.Start("vsky_gaben_warp")
                    net.WriteEntity(line.ent)
                    net.SendToServer()
                    frame:Close()
                end
            end
            
            PopulateWarpList(list, filter)
        end
        
        CreateWarpTab("Игроки", function(e) return e:IsPlayer() and e != LocalPlayer() end)
        CreateWarpTab("НИПы", function(e) return e:IsNPC() and not string.match(e:GetClass(), "^npc_vj_") end)
        CreateWarpTab("VJ Base", function(e) return e:IsNPC() and string.match(e:GetClass(), "^npc_vj_") end)
        CreateWarpTab("DrGBase", function(e) return e:IsNextBot() and string.match(e:GetClass(), "^npc_drg_") end)
        CreateWarpTab("Энтити", function(e) return not e:IsPlayer() and not e:IsNPC() and not e:IsNextBot() and not e:IsWeapon() end)
    end)

    hook.Add("PlayerBindPress", "vsky_gaben_binds", function(ply, bind, pressed)
        if pressed and bind == "impulse 100" then
            local wep = ply:GetActiveWeapon()
            if IsValid(wep) and wep:GetClass() == "swep_vsky_gabenfists" then
                net.Start("vsky_gaben_camlock")
                net.SendToServer()
                return true
            end
        end
    end)

    hook.Add("CalcView", "vsky_gaben_cam", function(ply, pos, ang, fov)
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "swep_vsky_gabenfists" then
            local target = wep:GetCamTarget()
            if IsValid(target) then
                local tpos = target:GetPos() + Vector(0, 0, 50)
                return {
                    origin = pos,
                    angles = (tpos - pos):Angle(),
                    fov = fov,
                    drawviewer = false
                }
            end
        end
    end)
    
    local matBeam = Material("sprites/physbeam")
    local matGlow = Material("sprites/light_glow02_add")
    
    hook.Add("PostDrawOpaqueRenderables", "vsky_gaben_lasers", function()
        for _, ply in pairs(player.GetAll()) do
            local wep = ply:GetActiveWeapon()
            if IsValid(wep) and wep:GetClass() == "swep_vsky_gabenfists" and wep:GetIsFiringLaser() then
                local bone1 = ply:LookupBone("ValveBiped.Bip01_Head1")
                if bone1 then
                    local m = ply:GetBoneMatrix(bone1)
                    if m then
                        local headPos = m:GetTranslation()
                        local headAng = m:GetAngles()
                        
                        local eyeL = headPos + headAng:Forward() * 4 + headAng:Right() * -3 + headAng:Up() * 3
                        local eyeR = headPos + headAng:Forward() * 4 + headAng:Right() * 3 + headAng:Up() * 3
                        
                        local tr = util.TraceLine({
                            start = ply:GetShootPos(),
                            endpos = ply:GetShootPos() + ply:GetAimVector() * 10000,
                            filter = ply
                        })
                        
                        local c = wep:GetLaserColor()
                        local col = Color(c.x * 255, c.y * 255, c.z * 255)
                        
                        render.SetMaterial(matBeam)
                        render.DrawBeam(eyeL, tr.HitPos, 5, 0, 1, col)
                        render.DrawBeam(eyeR, tr.HitPos, 5, 0, 1, col)
                        
                        render.SetMaterial(matGlow)
                        render.DrawSprite(eyeL, 10, 10, col)
                        render.DrawSprite(eyeR, 10, 10, col)
                        render.DrawSprite(tr.HitPos, 30, 30, col)
                    end
                end
            end
        end
    end)
end