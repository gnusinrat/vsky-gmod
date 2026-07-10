-- Это серверное ядро VSKY Base. Оно отвечает за консольные команды и глобальные функции.
print("[VSKY Base] Серверное ядро загружено!")

-- ==========================================
-- RATICAM
-- ==========================================

-- Команда: Удалить все камеры на карте
concommand.Add("vsky_cams_clearcameras", function(ply, cmd, args)
-- Проверка на админа (если команду вызывает игрок, а не консоль сервера)
if IsValid(ply) and not ply:IsAdmin() then
ply:ChatPrint("[VSKY] У вас нет прав для использования этой команды.")
return
end

local count = 0
-- Ищем все энтити камер из твоего кода RatiCam
for _, ent in ipairs(ents.FindByClass("sent_19x3_camera")) do
    if IsValid(ent) then
        ent:Remove()
        count = count + 1
    end
end

local msg = "[VSKY] Удалено камер: " .. count
print(msg)

-- Уведомляем админа
if IsValid(ply) then
    ply:ChatPrint(msg)
    
    -- Очищаем локальные таблицы камер у всех игроков, чтобы оружие не "сломалось"
    for _, p in ipairs(player.GetAll()) do
        p.MyCams = {}
    end
end


end)

-- Команда: Выкинуть всех игроков из режима просмотра камер
concommand.Add("vsky_cams_exitall", function(ply, cmd, args)
if IsValid(ply) and not ply:IsAdmin() then
ply:ChatPrint("[VSKY] У вас нет прав для использования этой команды.")
return
end

local count = 0
for _, p in ipairs(player.GetAll()) do
    -- Если ViewEntity игрока не он сам (значит, он смотрит через камеру)
    if p:GetViewEntity() ~= p then
        p:SetViewEntity(p)
        
        -- Вызываем сетевой хук закрытия UI из RatiCam
        net.Start("CamMonitor_CloseUI")
        net.Send(p)
        
        p:ChatPrint("[VSKY] Администратор принудительно отключил вас от камер.")
        count = count + 1
    end
end

local msg = "[VSKY] Игроков отключено от камер: " .. count
print(msg)
if IsValid(ply) then
    ply:ChatPrint(msg)
end


end)

-- ==========================================
-- DELTA RADIO
-- ==========================================

-- Команда: Остановить музыку на всех радио
concommand.Add("vsky_radio_stopall", function(ply, cmd, args)
if IsValid(ply) and not ply:IsAdmin() then
ply:ChatPrint("[VSKY] У вас нет прав для использования этой команды.")
return
end

local count = 0
for _, ent in ipairs(ents.FindByClass("delta_radio")) do
    if IsValid(ent) and ent:GetIsPlaying() then
        ent:SetIsPlaying(false)
        count = count + 1
    end
end

local msg = "[VSKY] Остановлено радио: " .. count
print(msg)
if IsValid(ply) then
    ply:ChatPrint(msg)
end


end)

-- Команда: Удалить все радио на карте
concommand.Add("vsky_radio_clearall", function(ply, cmd, args)
if IsValid(ply) and not ply:IsAdmin() then
ply:ChatPrint("[VSKY] У вас нет прав для использования этой команды.")
return
end

local count = 0
for _, ent in ipairs(ents.FindByClass("delta_radio")) do
    if IsValid(ent) then
        ent:Remove()
        count = count + 1
    end
end

local msg = "[VSKY] Удалено радио: " .. count
print(msg)
if IsValid(ply) then
    ply:ChatPrint(msg)
end


end)