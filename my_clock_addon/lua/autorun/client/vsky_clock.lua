/* STREAMING_CHUNK: Создаем шрифты с поддержкой кириллицы (extended = true) и огромными размерами */
surface.CreateFont("VSKY_Clock_Title", {
font = "Arial",
size = 28,
weight = 800,
antialias = true,
extended = true -- Чтобы русские буквы не ломались в квадраты
})

surface.CreateFont("VSKY_Clock_Time", {
font = "Arial",
size = 56,
weight = 700,
antialias = true,
extended = true
})

local showClock = false
local clockAlpha = 0
local clockEndTime = 0
local lastHourCheck = -1
local clockSoundChannel = nil -- Канал воспроизведения музыки

-- Безопасное чтение ConVars (если База еще не создала их)
local function GetCVFloat(name, default)
local cv = GetConVar(name)
return cv and cv:GetFloat() or default
end

local function GetCVInt(name, default)
local cv = GetConVar(name)
return cv and cv:GetInt() or default
end

local function GetCVBool(name, default)
local cv = GetConVar(name)
return cv and cv:GetBool() or default
end

/* STREAMING_CHUNK: Функция для остановки звукового сопровождения */
local function StopClockSound()
if IsValid(clockSoundChannel) then
clockSoundChannel:Stop()
clockSoundChannel = nil
end
end

/* STREAMING_CHUNK: Функция для воспроизведения музыки с точным контролем */
local function PlayClockSound(path)
StopClockSound() -- На всякий случай гасим прошлый запущенный звук

-- Проигрываем файл через звуковой движок с возможностью остановки
sound.PlayFile("sound/" .. path, "noplay", function(station, errCode, errStr)
    if IsValid(station) then
        clockSoundChannel = station
        clockSoundChannel:Play()
    else
        -- Запасной вариант на случай сбоя
        surface.PlaySound(path)
    end
end)


end

/* STREAMING_CHUNK: Отрисовка HUD часов */
hook.Add("HUDPaint", "VSKY_Clock_HUD", function()
if not GetCVBool("vsky_clock_enable", true) then return end
if not showClock and clockAlpha == 0 then return end

local curTime = CurTime()
if showClock and curTime > clockEndTime then
    showClock = false
    StopClockSound() -- ОТКЛЮЧАЕМ ФОНК, как только время показа вышло!
end

-- Плавное появление и исчезновение
if showClock then
    clockAlpha = Lerp(RealFrameTime() * 10, clockAlpha, 255)
else
    clockAlpha = Lerp(RealFrameTime() * 10, clockAlpha, 0)
end

if clockAlpha < 1 then return end

/* STREAMING_CHUNK: Рассчитываем позицию HUD на экране */
local posType = GetCVInt("vsky_clock_pos", 5)
local xPct, yPct = 85, 15

if posType == 1 then -- Сверху слева
    xPct = 5
    yPct = 5
elseif posType == 2 then -- Сверху справа
    xPct = 95
    yPct = 5
elseif posType == 3 then -- Снизу слева
    xPct = 5
    yPct = 95
elseif posType == 4 then -- Снизу справа
    xPct = 95
    yPct = 95
else -- Своя позиция (5)
    xPct = GetCVFloat("vsky_clock_x", 85)
    yPct = GetCVFloat("vsky_clock_y", 15)
end

xPct = xPct / 100
yPct = yPct / 100

-- Цвета из палитры Базы
local r = GetCVInt("vsky_clock_color_r", 147)
local g = GetCVInt("vsky_clock_color_g", 0)
local b = GetCVInt("vsky_clock_color_b", 255)
local accentColor = Color(r, g, b, clockAlpha)

-- Размеры плашки (увеличены под жирный шрифт)
local w, h = 420, 135
local x = ScrW() * xPct - (w * xPct)
local y = ScrH() * yPct - (h * yPct)

-- Задний фон
draw.RoundedBox(12, x, y, w, h, Color(35, 43, 53, clockAlpha * 0.95))

-- Левая неоновая полоса
draw.RoundedBoxEx(12, x, y, 10, h, accentColor, true, false, true, false)

-- Текст "Новый час наступил" (Arial, 28px)
draw.SimpleText("НОВЫЙ ЧАС НАСТУПИЛ!", "VSKY_Clock_Title", x + 30, y + 20, accentColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

-- Время (Arial, 56px)
local timeStr = os.date("%H:%M:%S")
draw.SimpleText(timeStr, "VSKY_Clock_Time", x + 30, y + 55, Color(255, 255, 255, clockAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)


end)

/* STREAMING_CHUNK: Функция срабатывания часов */
local function TriggerClockNotification()
if not GetCVBool("vsky_clock_enable", true) then return end

showClock = true
clockEndTime = CurTime() + GetCVInt("vsky_clock_time", 7)

-- Если включен звук в настройках
if GetCVBool("vsky_clock_sound", true) then
    if GetCVBool("vsky_clock_tikitiki", false) then
        -- Проигрываем файл из sound/vsky/tikitiki.mp3 с возможностью остановки
        PlayClockSound("vsky/tikitiki.mp3")
    else
        -- Дефолтный колокольчик
        PlayClockSound("ambient/alarms/warningbell1.wav")
    end
end


end

-- Проверка времени раз в секунду
timer.Create("VSKY_Clock_Check", 1, 0, function()
local t = os.date("*t")
if t.min == 0 and t.sec == 0 then
if lastHourCheck ~= t.hour then
lastHourCheck = t.hour
TriggerClockNotification()
end
end
end)

-- Тестовая консольная команда
concommand.Add("vsky_clock_test", function()
TriggerClockNotification()
end)

-- Глушим звук при выходе или перезагрузке
hook.Add("ShutDown", "VSKY_Clock_Shutdown_Sound", StopClockSound)