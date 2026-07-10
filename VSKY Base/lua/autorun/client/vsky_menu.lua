/* STREAMING_CHUNK: Регистрируем переводы и вкладки спавнменю VSKY */
language.Add("spawnmenu.category.VSKY_Tools", "Инструменты")
language.Add("spawnmenu.category.VSKY_Settings", "Настройки")

-- Создаем главную вкладку VSKY
hook.Add("AddToolMenuTabs", "VSKY_CreateTab", function()
spawnmenu.AddToolTab("VSKY", "VSKY", "icon16/star.png")
end)

/* STREAMING_CHUNK: Создаем необходимые консольные переменные для цвета и настроек */
CreateClientConVar("vsky_clock_enable", "1", true, false, "Включить HUD часов")
CreateClientConVar("vsky_clock_sound", "1", true, false, "Включить звуковое оповещение")
CreateClientConVar("vsky_clock_tikitiki", "0", true, false, "Режим Тики-Тики")
CreateClientConVar("vsky_clock_time", "7", true, false, "Время показа часов")
CreateClientConVar("vsky_clock_pos", "5", true, false, "Позиция часов")
CreateClientConVar("vsky_clock_x", "85", true, false, "Позиция X")
CreateClientConVar("vsky_clock_y", "15", true, false, "Позиция Y")

CreateClientConVar("vsky_clock_color_r", "147", true, false, "Цвет часов R")
CreateClientConVar("vsky_clock_color_g", "0", true, false, "Цвет часов G")
CreateClientConVar("vsky_clock_color_b", "255", true, false, "Цвет часов B")

/* STREAMING_CHUNK: Наполняем настройки и подразделы меню VSKY */
hook.Add("PopulateToolMenu", "VSKY_CreateSettings", function()

-- ПОДРАЗДЕЛ: О аддоне (Базовая информация и админ-команды)
spawnmenu.AddToolMenuOption("VSKY", "VSKY_Settings", "VSKY_About", "О аддоне", "", "", function(panel)
    panel:ClearControls()
    
    local title = panel:Help("VSKY Base - 2026")
    title:SetFont("DermaLarge")
    
    local authorPanel = vgui.Create("DPanel", panel)
    authorPanel:Dock(TOP)
    authorPanel:SetTall(30)
    authorPanel:SetPaintBackground(false) 

    local lbl1 = vgui.Create("DLabel", authorPanel)
    lbl1:SetText("Создано ")
    lbl1:SetFont("DermaDefault")
    lbl1:SetDark(true)
    lbl1:SizeToContents()
    lbl1:Dock(LEFT)

    local lbl2 = vgui.Create("DLabel", authorPanel)
    lbl2:SetText("ratbar1999")
    lbl2:SetFont("DermaDefaultBold")
    lbl2:SetTextColor(Color(150, 0, 255)) -- Фирменный фиолетовый VSKY
    lbl2:SizeToContents()
    lbl2:Dock(LEFT)

    /* STREAMING_CHUNK: Сканируем файлы для динамического отображения информации */
    local installedTools = {"\nСписок активных инструментов:"}
    if file.Exists("weapons/gmod_tool/stools/teleporter_maker.lua", "LUA") then
        table.insert(installedTools, "• Создатель Телепортов (VSKY)")
    end
    if file.Exists("weapons/gmod_tool/stools/dissolver.lua", "LUA") then
        table.insert(installedTools, "• Диссолвер (VSKY)")
    end
    if #installedTools == 1 then
        table.insert(installedTools, "• Нет активных инструментов (проверьте файлы)")
    end

    local list = panel:Help(table.concat(installedTools, "\n"))
    list:SetFont("DermaDefault")

    /* STREAMING_CHUNK: Проверяем наличие сторонних модулей (Камеры/Радио) */
    local commandsText = {"\nКонсольные команды (Для админов):"}
    local hasCams = (scripted_ents.GetStored("sent_vsky_camera") ~= nil or weapons.GetStored("weapon_cam_monitor") ~= nil)
    local hasRadio = (scripted_ents.GetStored("delta_radio") ~= nil)

    if hasCams then
        table.insert(commandsText, "\n[Камеры RatiCam]")
        table.insert(commandsText, "• vsky_cams_clearcameras - удалить все камеры")
        table.insert(commandsText, "• vsky_cams_exitall - выкинуть всех из просмотра")
    end

    if hasRadio then
        table.insert(commandsText, "\n[Радио Delta Radio]")
        table.insert(commandsText, "• vsky_radio_stopall - поставить на паузу все радио")
        table.insert(commandsText, "• vsky_radio_clearall - удалить все радио")
    end

    if not hasCams and not hasRadio then
        table.insert(commandsText, "\n• Дополнительные модули (Камеры/Радио) не обнаружены.")
    end

    local commands = panel:Help(table.concat(commandsText, "\n"))
    commands:SetFont("DermaDefault")
end)

/* STREAMING_CHUNK: Раздел настроек круглосуточных уведомлений (vClock) */
spawnmenu.AddToolMenuOption("VSKY", "VSKY_Settings", "VSKY_ClockSettings", "Часы (Уведомления)", "", "", function(panel)
    panel:ClearControls()
    
    -- Выводим предупреждение на случай отсутствия скрипта
    local warningLabel = vgui.Create("DLabel", panel)
    warningLabel:SetText("ВНИМАНИЕ: Эти настройки не будут ничего делать если у вас не установлен модуль vClock!")
    warningLabel:SetTextColor(Color(255, 50, 50))
    warningLabel:SetFont("DermaDefaultBold")
    warningLabel:SetWrap(true)
    warningLabel:SetAutoStretchVertical(true)
    panel:AddItem(warningLabel)

    local infoLabel = vgui.Create("DLabel", panel)
    infoLabel:SetText("\nЗдесь вы можете настроить HUD красивых часов, которые появляются в круглое время (например, в 12:00, 13:00 и т.д.)")
    infoLabel:SetWrap(true)
    infoLabel:SetAutoStretchVertical(true)
    infoLabel:SetDark(true)
    panel:AddItem(infoLabel)

    -- Чекбоксы включения и звуков
    panel:CheckBox("Включить HUD часов", "vsky_clock_enable")
    panel:CheckBox("Звуковое оповещение", "vsky_clock_sound")
    panel:CheckBox("Режим 'Тики Тики' (Фонк)", "vsky_clock_tikitiki") -- Тот самый чекбокс фонка!
    panel:NumSlider("Время показа (сек)", "vsky_clock_time", 5, 60, 0)

    /* STREAMING_CHUNK: Выбор позиции часов */
    local comboLabel = vgui.Create("DLabel", panel)
    comboLabel:SetText("\nПозиция на экране:")
    comboLabel:SetDark(true)
    panel:AddItem(comboLabel)

    local choice = vgui.Create("DComboBox", panel)
    choice:AddChoice("Сверху слева", "1")
    choice:AddChoice("Сверху справа", "2")
    choice:AddChoice("Снизу слева", "3")
    choice:AddChoice("Снизу справа", "4")
    choice:AddChoice("Своя позиция (из ползунков ниже)", "5")
    
    local currentPos = GetConVar("vsky_clock_pos"):GetString()
    if currentPos == "1" then choice:SetValue("Сверху слева")
    elseif currentPos == "2" then choice:SetValue("Сверху справа")
    elseif currentPos == "3" then choice:SetValue("Снизу слева")
    elseif currentPos == "4" then choice:SetValue("Снизу справа")
    elseif currentPos == "5" then choice:SetValue("Своя позиция (из ползунков ниже)")
    end

    choice.OnSelect = function(self, index, value, data)
        RunConsoleCommand("vsky_clock_pos", data)
    end
    panel:AddItem(choice)

    panel:NumSlider("Своя позиция X (%)", "vsky_clock_x", 0, 100, 0)
    panel:NumSlider("Своя позиция Y (%)", "vsky_clock_y", 0, 100, 0)

    /* STREAMING_CHUNK: Добавление палитры выбора цвета для VSKY */
    local colorLabel = vgui.Create("DLabel", panel)
    colorLabel:SetText("\nЦвет неоновых элементов VSKY:")
    colorLabel:SetFont("DermaDefaultBold")
    colorLabel:SetDark(true)
    panel:AddItem(colorLabel)

    local colorMixer = vgui.Create("DColorMixer", panel)
    colorMixer:SetPalette(true)
    colorMixer:SetAlphaBar(false) -- Альфа канал не нужен
    colorMixer:SetWangs(true)
    
    -- Задаем текущие сохраненные цвета
    local r = GetConVar("vsky_clock_color_r"):GetInt()
    local g = GetConVar("vsky_clock_color_g"):GetInt()
    local b = GetConVar("vsky_clock_color_b"):GetInt()
    colorMixer:SetColor(Color(r, g, b))

    -- Обработка изменения цвета игроком на палитре
    colorMixer.ValueChanged = function(self, col)
        RunConsoleCommand("vsky_clock_color_r", tostring(col.r))
        RunConsoleCommand("vsky_clock_color_g", tostring(col.g))
        RunConsoleCommand("vsky_clock_color_b", tostring(col.b))
    end
    panel:AddItem(colorMixer)

    -- Кнопка "Тест"
    local spacer = vgui.Create("DPanel", panel)
    spacer:SetTall(15)
    spacer:SetPaintBackground(false)
    panel:AddItem(spacer)

    local btnTest = vgui.Create("DButton", panel)
    btnTest:SetText("Проверить часы (Тест)")
    btnTest:SetTall(30)
    btnTest.DoClick = function()
        RunConsoleCommand("vsky_clock_test")
    end
    panel:AddItem(btnTest)
end)


end)