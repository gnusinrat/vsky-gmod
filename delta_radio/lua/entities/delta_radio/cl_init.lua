include("shared.lua")

local stars = {}
for i = 1, 350 do
    table.insert(stars, {
        x = math.random(0, ScrW()),
        y = math.random(0, ScrH()),
        speed = math.random(10, 40) / 100,
        size = math.random(1, 2),
        alpha = math.random(10, 150)
    })
end

local bmFont = { chars = {}, mat = nil, scaleW = 256, scaleH = 256, loaded = false }

local function LoadDeltaruneFont()
    bmFont.mat = Material("vsky/deltarune_font")
    local data = file.Read("materials/vsky/deltarune_font.txt", "GAME")
    if not data then return end
    local common = string.match(data, "common (.-)\n")
    if common then
        bmFont.scaleW = tonumber(string.match(common, "scaleW=(%d+)")) or 256
        bmFont.scaleH = tonumber(string.match(common, "scaleH=(%d+)")) or 256
    end
    for charData in string.gmatch(data, "char (.-)\n") do
        local id = tonumber(string.match(charData, "id=(%d+)"))
        if id then
            bmFont.chars[id] = {
                x = tonumber(string.match(charData, "x=(%d+)")) or 0,
                y = tonumber(string.match(charData, "y=(%d+)")) or 0,
                w = tonumber(string.match(charData, "width=(%d+)")) or 0,
                h = tonumber(string.match(charData, "height=(%d+)")) or 0,
                xoff = tonumber(string.match(charData, "xoffset=(%-?%d+)")) or 0,
                yoff = tonumber(string.match(charData, "yoffset=(%-?%d+)")) or 0,
                xadv = tonumber(string.match(charData, "xadvance=(%d+)")) or 0
            }
        end
    end
    bmFont.loaded = true
end
LoadDeltaruneFont()

local function DrawBMText(text, x, y, col)
    if not bmFont.loaded then return 0 end
    surface.SetMaterial(bmFont.mat)
    surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)
    local cx = x
    for _, code in utf8.codes(text) do
        local ch = bmFont.chars[code]
        if ch then
            local drawX = cx + ch.xoff
            local drawY = y + ch.yoff
            local u0 = ch.x / bmFont.scaleW
            local v0 = ch.y / bmFont.scaleH
            local u1 = (ch.x + ch.w) / bmFont.scaleW
            local v1 = (ch.y + ch.h) / bmFont.scaleH
            surface.DrawTexturedRectUV(drawX, drawY, ch.w, ch.h, u0, v0, u1, v1)
            cx = cx + ch.xadv
        end
    end
    return cx - x
end

local function GetBMTextWidth(text)
    if not bmFont.loaded then return 0 end
    local w = 0
    for _, code in utf8.codes(text) do
        local ch = bmFont.chars[code]
        if ch then w = w + ch.xadv end
    end
    return w
end

function ENT:Initialize()
    self.CurrentLoadedSong = ""
    self.AudioChannel = nil
    self.LastPlayingState = false

    if not file.Exists("deltaradio/songs", "DATA") then
        file.CreateDir("deltaradio/songs")
    end
end

function ENT:Think()
    local targetSong = self:GetSongName()

    if self.CurrentLoadedSong ~= targetSong and targetSong ~= "" then
        self.CurrentLoadedSong = targetSong

        if IsValid(self.AudioChannel) then
            self.AudioChannel:Stop()
            self.AudioChannel = nil
        end

        local loadingSong = targetSong 
        local path = "data/deltaradio/songs/" .. targetSong

        sound.PlayFile(path, "3d noplay", function(station, errCode, errStr)
            if self.CurrentLoadedSong ~= loadingSong then
                if IsValid(station) then station:Stop() end
                return
            end

            if IsValid(station) and IsValid(self) then
                self.AudioChannel = station
                self.AudioChannel:SetPos(self:GetPos())
                self.AudioChannel:SetVolume(self:GetRadioVolume())
                self.AudioChannel:Set3DFadeDistance(200, 1500) 
                
                self.LastPlayingState = self:GetIsPlaying()
                if self.LastPlayingState then
                    self.AudioChannel:Play()
                end
            end
        end)
    end

    if IsValid(self.AudioChannel) then
        self.AudioChannel:SetPos(self:GetPos())
        self.AudioChannel:SetVolume(self:GetRadioVolume())

        local isPlaying = self:GetIsPlaying()
        if self.LastPlayingState ~= isPlaying then
            self.LastPlayingState = isPlaying
            if isPlaying then self.AudioChannel:Play() else self.AudioChannel:Pause() end
        end

        if self:GetLoop() and self:GetIsPlaying() and self.AudioChannel:GetState() == GMOD_CHANNEL_STOPPED then
            self.AudioChannel:SetTime(0)
            self.AudioChannel:Play()
        end
    end

    self:SetNextClientThink(CurTime())
    return true
end

function ENT:OnRemove()
    if IsValid(self.AudioChannel) then
        self.AudioChannel:Stop()
    end
end

net.Receive("DeltaRadio_ClientAction", function()
    local ent = net.ReadEntity()
    local act = net.ReadString()
    local val = net.ReadFloat()

    if IsValid(ent) and ent:GetClass() == "delta_radio" and IsValid(ent.AudioChannel) then
        if act == "seek" then ent.AudioChannel:SetTime(val) end
    end
end)

net.Receive("DeltaRadio_OpenMenu", function()
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end

    local frame = vgui.Create("DFrame")
    frame:SetSize(650, 480)
    frame:SetTitle("Delta Radio - Управление")
    frame:Center()
    frame:MakePopup()

    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(25, 25, 30, 245))
        
        for _, star in ipairs(stars) do
            star.y = star.y - star.speed
            if star.y < 0 then
                star.y = h
                star.x = math.random(0, w)
            end
            surface.SetDrawColor(255, 255, 255, star.alpha)
            surface.DrawRect(star.x, star.y, star.size, star.size)
        end
    end

    local sheet = vgui.Create("DPropertySheet", frame)
    sheet:Dock(FILL)

    local panelPlayer = vgui.Create("DPanel", sheet)
    panelPlayer.Paint = function() end

    local songList = vgui.Create("DListView", panelPlayer)
    songList:Dock(FILL)
    songList:DockMargin(0, 0, 0, 10)
    songList:AddColumn("Название файла")

    local files, _ = file.Find("deltaradio/songs/*", "DATA")
    for _, f in ipairs(files) do
        if string.EndsWith(f, ".mp3") or string.EndsWith(f, ".ogg") or string.EndsWith(f, ".wav") then
            songList:AddLine(f)
        end
    end

    songList.OnRowSelected = function(lst, index, pnl)
        lst.SelectedSongName = pnl:GetColumnText(1)
    end

    songList.OnRowDoubleClicked = function(lst, index, pnl)
        local song = pnl:GetColumnText(1)
        net.Start("DeltaRadio_Command")
        net.WriteEntity(ent)
        net.WriteString("play_song")
        net.WriteString(song)
        net.SendToServer()
    end

    local controlsPnl = vgui.Create("DPanel", panelPlayer)
    controlsPnl:Dock(BOTTOM)
    controlsPnl:SetTall(80)
    controlsPnl.Paint = function() end

    local btnLayout = vgui.Create("DIconLayout", controlsPnl)
    btnLayout:Dock(TOP)
    btnLayout:SetSpaceX(10)
    btnLayout:SetTall(35)

    local btnLoad = btnLayout:Add("DButton")
    btnLoad:SetSize(140, 30)
    btnLoad:SetText("▶ Включить трек")
    btnLoad.DoClick = function()
        if songList.SelectedSongName then
            net.Start("DeltaRadio_Command")
            net.WriteEntity(ent)
            net.WriteString("play_song")
            net.WriteString(songList.SelectedSongName)
            net.SendToServer()
        end
    end

    local btnStart = btnLayout:Add("DButton")
    btnStart:SetSize(80, 30)
    btnStart:SetText("В начало")
    btnStart.DoClick = function()
        net.Start("DeltaRadio_Command")
        net.WriteEntity(ent)
        net.WriteString("seek")
        net.WriteFloat(0)
        net.SendToServer()
    end

    local btnPlay = btnLayout:Add("DButton")
    btnPlay:SetSize(80, 30)
    btnPlay:SetText("Пауза/Пуск")
    btnPlay.DoClick = function()
        net.Start("DeltaRadio_Command")
        net.WriteEntity(ent)
        net.WriteString("toggle_pause")
        net.SendToServer()
    end

    local progressBar = vgui.Create("DPanel", controlsPnl)
    progressBar:Dock(BOTTOM)
    progressBar:SetTall(25)
    progressBar:SetCursor("hand")
    progressBar.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20, 200))
        
        if not IsValid(ent.AudioChannel) then
            local msg = (ent:GetSongName() == "") and "ВЫБЕРИТЕ ТРЕК И НАЖМИТЕ 'ВКЛЮЧИТЬ'" or "ЗАГРУЗКА ТРЕКА..."
            draw.SimpleText(msg, "DermaDefaultBold", w / 2, h / 2, Color(255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end
        
        local cur = ent.AudioChannel:GetTime() or 0
        local len = ent.AudioChannel:GetLength() or 1
        local frac = math.Clamp(cur / len, 0, 1)
        
        draw.RoundedBox(4, 0, 0, w * frac, h, Color(50, 150, 255))
        
        local timeTxt = string.format("%02d:%02d / %02d:%02d", math.floor(cur/60), math.floor(cur%60), math.floor(len/60), math.floor(len%60))
        draw.SimpleText(timeTxt, "DermaDefaultBold", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    progressBar.OnMousePressed = function(self, key)
        if key == MOUSE_LEFT and IsValid(ent.AudioChannel) then
            local x = gui.MouseX() - self:LocalToScreen(0, 0)
            local frac = math.Clamp(x / self:GetWide(), 0, 1)
            local targetTime = frac * ent.AudioChannel:GetLength()
            
            net.Start("DeltaRadio_Command")
            net.WriteEntity(ent)
            net.WriteString("seek")
            net.WriteFloat(targetTime)
            net.SendToServer()
        end
    end

    local panelSettings = vgui.Create("DPanel", sheet)
    panelSettings.Paint = function() end

    local volSlider = vgui.Create("DNumSlider", panelSettings)
    volSlider:Dock(TOP)
    volSlider:DockMargin(10, 10, 10, 0)
    volSlider:SetText("Громкость Радио")
    volSlider:SetMin(0)
    volSlider:SetMax(1)
    volSlider:SetDecimals(2)
    volSlider:SetValue(ent:GetRadioVolume())
    volSlider.OnValueChanged = function(self, value)
        net.Start("DeltaRadio_Command")
        net.WriteEntity(ent)
        net.WriteString("set_volume")
        net.WriteFloat(value)
        net.SendToServer()
    end

    local loopCheck = vgui.Create("DCheckBoxLabel", panelSettings)
    loopCheck:Dock(TOP)
    loopCheck:DockMargin(10, 20, 10, 0)
    loopCheck:SetText("Повтор музыки")
    loopCheck:SetValue(ent:GetLoop())
    loopCheck.OnChange = function(self, val)
        net.Start("DeltaRadio_Command")
        net.WriteEntity(ent)
        net.WriteString("set_loop")
        net.WriteBool(val)
        net.SendToServer()
    end

    sheet:AddSheet("Плеер", panelPlayer, "icon16/music.png")
    sheet:AddSheet("Настройки", panelSettings, "icon16/cog.png")
end)

hook.Add("HUDPaint", "DeltaRadio_SongHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local closestRadio = nil
    local minDist = 400 * 400

    for _, ent in ipairs(ents.FindByClass("delta_radio")) do
        if ent:GetIsPlaying() and ent:GetSongName() ~= "" then
            local dist = ply:GetPos():DistToSqr(ent:GetPos())
            if dist < minDist then
                minDist = dist
                closestRadio = ent
            end
        end
    end

    if IsValid(closestRadio) then
        local songRaw = closestRadio:GetSongName()
        local songName = string.StripExtension(songRaw)
        local text = "♪ ~ " .. songName
        
        if bmFont.loaded then
            local tw = GetBMTextWidth(text)
            local x = ScrW() - tw - 30
            local y = 30
            
            DrawBMText(text, x + 2, y + 2, Color(0, 0, 0, 255))
            DrawBMText(text, x, y, Color(255, 255, 255, 255))
        end
    end
end)