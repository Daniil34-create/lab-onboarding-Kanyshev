@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

REM =================================================================
REM Тема: инструментальные средства ревьюирования, проверки на стороне клиента.
REM Выполнил: Фамилия И.О.
REM Дата доработки: 02.11.2026 (Часть 2)
REM Ветка: feature/client-check-audit
REM =================================================================

set "REPORT_FILE=%~dp0pc_report.txt"
set "TEMP_RAW=%temp%\apps_raw.txt"
set "TEMP_APPS=%temp%\apps_list.txt"

REM Очистка старых отчетов и временных файлов
if exist "%REPORT_FILE%" del "%REPORT_FILE%"
if exist "%TEMP_RAW%" del "%TEMP_RAW%"
if exist "%TEMP_APPS%" del "%TEMP_APPS%"

REM Шаг 7: Получение текущей даты и времени для заголовка отчета
for /f "tokens=1-3 delims=. " %%a in ('date /t') do set "current_date=%%a.%%b.%%c"
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set "current_time=%%a:%%b"

call :log "====================================================================="
call :log "                      ДИАГНОСТИКА И АУДИТ КОМПЬЮТЕРА"
call :log "                  Дата проверки: %current_date% в %current_time%"
call :log "====================================================================="
call :log ""

REM -----------------------------------------------------------------
REM БЛОК 3: Сведения об операционной системе
REM -----------------------------------------------------------------
call :log "[Операционная sistema]"

set "os_caption="
set "os_version="
for /f "tokens=2 delims==" %%i in ('wmic os get Caption /value 2^>nul') do set "os_caption=%%i"
for /f "tokens=2 delims==" %%i in ('wmic os get Version /value 2^>nul') do set "os_version=%%i"

if not defined os_caption (call :log "Название: [ОШИБКА] Данные получить не удалось") else (call :log "Название: !os_caption!")
if not defined os_version (call :log "Версия: [ОШИБКА] Данные получить не удалось") else (call :log "Версия: !os_version!")
call :log ""

REM -----------------------------------------------------------------
REM БЛОК 4: Сведения об обработчике (процессоре)
REM -----------------------------------------------------------------
call :log "[Процессор]"

set "cpu_name="
for /f "tokens=2 delims==" %%i in ('wmic cpu get Name /value 2^>nul') do set "cpu_name=%%i"

if not defined cpu_name (call :log "Модель: [ОШИБКА] Данные получить не удалось") else (call :log "Модель: !cpu_name!")
call :log ""

REM -----------------------------------------------------------------
REM БЛОК 5: Сведения об оперативной памяти
REM -----------------------------------------------------------------
call :log "[Оперативная память]"

set "total_mem="
set "free_mem="
for /f "tokens=2 delims==" %%i in ('wmic os get TotalVisibleMemorySize /value 2^>nul') do set "total_mem=%%i"
for /f "tokens=2 delims==" %%i in ('wmic os get FreePhysicalMemory /value 2^>nul') do set "free_mem=%%i"

if not defined total_mem (
    call :log "Всего памяти: [ОШИБКА] Данные получить не удалось"
) else (
    set /a total_mem_gb=!total_mem! / 1048576
    call :log "Всего памяти: !total_mem_gb! ГБ"
)

if not defined free_mem (
    call :log "Свободно памяти: [ОШИБКА] Данные получить не удалось"
) else (
    set /a free_mem_gb=!free_mem! / 1048576
    call :log "Свободно памяти: !free_mem_gb! ГБ"
)
call :log ""

REM -----------------------------------------------------------------
REM БЛОК 6: Свободное место на диске
REM -----------------------------------------------------------------
call :log "[Диск C]"

set "disk_size="
set "disk_free="
for /f "tokens=2 delims==" %%i in ('wmic logicaldisk where DeviceID^="C:" get Size /value 2^>nul') do set "disk_size=%%i"
for /f "tokens=2 delims==" %%i in ('wmic logicaldisk where DeviceID^="C:" get FreeSpace /value 2^>nul') do set "disk_free=%%i"

REM Шаг 3: Защита от переполнения разрядности CMD при расчете больших дисков через PowerShell
if not defined disk_size (
    call :log "Общий размер: [ОШИБКА] Данные получить не удалось"
) else (
    for /f %%x in ('powershell -NoProfile -Command "[math]::round([int64]!disk_size! / 1GB)" 2^>nul') do set "disk_size_gb=%%x"
    call :log "Общий размер: !disk_size_gb! ГБ"
)

if not defined disk_free (
    call :log "Свободное место: [ОШИБКА] Данные получить не удалось"
) else (
    for /f %%x in ('powershell -NoProfile -Command "[math]::round([int64]!disk_free! / 1GB)" 2^>nul') do set "disk_free_gb=%%x"
    call :log "Свободное место: !disk_free_gb! ГБ"
)
call :log ""

REM -----------------------------------------------------------------
REM БЛОК 7: Список установленных программ (через Реестр)
REM -----------------------------------------------------------------
echo [ИНФО] Идет сбор и фильтрация данных из реестра...

reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s /f DisplayName 2^>nul | findstr "DisplayName" > "%TEMP_RAW%"
reg query "HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s /f DisplayName 2^>nul | findstr "DisplayName" >> "%TEMP_RAW%"

for /f "tokens=2*" %%a in ('type "%TEMP_RAW%" 2^>nul') do (
    set "app_name=%%b"
    if defined app_name echo !app_name!>> "%TEMP_APPS%"
)

call :log "[Установленные программы]"
for /f "tokens=*" %%g in ('sort "%TEMP_APPS%" 2^>nul') do (
    if not "%%g"=="!last_app!" (
        call :log " - %%g"
        set "last_app=%%g"
    )
)
call :log ""

REM -----------------------------------------------------------------
REM АНАЛИТИЧЕСКИЙ БЛОК: АНАЛИЗ И РЕКОМЕНДАЦИИ
REM -----------------------------------------------------------------
call :log "====================================================================="
call :log "                      АНАЛИТИЧЕСКИЙ РЕЗУЛЬТАТ АУДИТА"
call :log "====================================================================="
call :log ""

set /a base_checked=0
set /a recommendations_count=0

REM Шаг 5: Анализ базового офисного ПО
call :log "--- АНАЛИЗ БАЗОВОГО ОФИСНОГО ПО ---"

REM Категория 1: Офисный пакет
set /a base_checked+=1
findstr /i "Office LibreOffice OpenOffice МойОфис" "%TEMP_APPS%" >nul
if %errorlevel% equ 0 (
    call :log "[ОК] Офисный пакет: Обнаружен."
) else (
    call :log "[РЕКОМЕНДАЦИЯ] Офисный пакет: Не обнаружен! Рекомендуется установить LibreOffice или МойОфис."
    set /a recommendations_count+=1
)

REM Категория 2: Архиватор
set /a base_checked+=1
findstr /i "7-Zip WinRAR WinZip" "%TEMP_APPS%" >nul
if %errorlevel% equ 0 (
    call :log "[ОК] Архиватор: Обнаружен."
) else (
    call :log "[РЕКОМЕНДАЦИЯ] Архиватор: Не обнаружен! Рекомендуется установить 7-Zip или WinRAR."
    set /a recommendations_count+=1
)

REM Категория 3: Программа чтения PDF
set /a base_checked+=1
findstr /i "Acrobat Foxit SumatraPDF" "%TEMP_APPS%" >nul
if %errorlevel% equ 0 (
    call :log "[ОК] Программа чтения PDF: Обнаружена."
) else (
    call :log "[РЕКОМЕНДАЦИЯ] Программа чтения PDF: Не обнаружена! Рекомендуется установить Foxit Reader или SumatraPDF."
    set /a recommendations_count+=1
)

REM Категория 4: Браузер
set /a base_checked+=1
findstr /i "Chrome Firefox Yandex" "%TEMP_APPS%" >nul
if %errorlevel% equ 0 (
    call :log "[ОК] Сторонний рабочий браузер: Обнаружен."
) else (
    call :log "[КОМПОНЕНТ СИСТЕМЫ] Сторонние браузеры не найдены. Используется встроенный Microsoft Edge."
)

REM Категория 5: Антивирусная защита
set /a base_checked+=1
findstr /i "Defender Kaspersky ESET Dr.Web" "%TEMP_APPS%" >nul
if %errorlevel% equ 0 (
    call :log "[ОК] Корпоративная антивирусная защита: Обнаружена."
) else (
    call :log "[РЕКОМЕНДАЦИЯ] Антивирус: Не найден! Убедитесь, что встроенный Защитник активен, либо разверните Dr.Web/Kaspersky."
    set /a recommendations_count+=1
)
call :log ""

REM Шаг 6: Анализ нерекомендуемого ПО
call :log "--- АНАЛИЗ НЕОБЯЗАТЕЛЬНОГО / НЕОФИСНОГО ПО ---"
call :log "* Примечание: Вывод является рекомендацией к проверке, а не обязательным указанием к удалению софта. *"

REM Группа 1: Игровой софт
call :log "[Группа: Игры и игровые платформы]"
set "games_found=0"
for %%g in (Steam "Epic Games" GOG Origin "Ubisoft Connect" Battle.net Riot game gaming) do (
    findstr /i "%%g" "%TEMP_APPS%" >nul
    if !errorlevel! equ 0 (
        call :log "  -> Требует проверки игровой маркер: %%g"
        set "games_found=1"
        set /a recommendations_count+=1
    )
)
if "!games_found!"=="0" call :log "  [ОК] Нецелевое игровое ПО в системе не обнаружено."

REM Группа 2: Файлообменники
call :log "[Группа: Торрент-клиенты]"
set "torrent_found=0"
for %%t in (torrent uTorrent BitTorrent qBittorrent Vuze) do (
    findstr /i "%%t" "%TEMP_APPS%" >nul
    if !errorlevel! equ 0 (
        call :log "  -> Обнаружено потенциально опасное ПО: %%t"
        set "torrent_found=1"
        set /a recommendations_count+=1
    )
)
if "!torrent_found!"=="0" call :log "  [ОК] Сетевые торрент-клиенты не обнаружены."

REM Группа 3: Нестандартные мессенджеры
call :log "[Группа: Средства коммуникации (Личные)]"
set "chat_found=0"
for %%c in (Discord Telegram WhatsApp Viber Skype) do (
    findstr /i "%%c" "%TEMP_APPS%" >nul
    if !errorlevel! equ 0 (
        call :log "  -> Обнаружен сторонний мессенджер: %%c (Требуется верификация ИТ-отдела)"
        set "chat_found=1"
    )
)
if "!chat_found!"=="0" call :log "  [ОК] Сторонние мессенджеры для личного общения не найдены."

REM Группа 4: Специализированный софт, разработка и развлечения
call :log "[Группа: Мультимедиа, разработка и специализированный софт]"
set "media_found=0"
for %%m in ("Wallpaper Engine" OBS Soundpad Unity Git draw.io WinDirStat Python) do (
    findstr /i "%%m" "%TEMP_APPS%" >nul
    if !errorlevel! equ 0 (
        call :log "  -> Требует внимания специализированный софт: %%m"
        set "media_found=1"
        set /a recommendations_count+=1
    )
)
if "!media_found!"=="0" call :log "  [ОК] Специализированные или лишние инструменты не обнаружены."
call :log ""

REM -----------------------------------------------------------------
REM БЛОК 8: Завершение работы и очистка мусора
REM -----------------------------------------------------------------
if exist "%TEMP_RAW%" del "%TEMP_RAW%"
if exist "%TEMP_APPS%" del "%TEMP_APPS%"
echo.
echo =====================================================================
echo ИТОГИ ПРОВЕРКИ:
echo Категорий базового ПО исследовано: %base_checked%
echo Выдано замечаний и рекомендаций для сисадмина: %recommendations_count%
echo.
echo Полный структурированный отчет сохранен по пути:
echo %REPORT_FILE%
echo =====================================================================
echo.
pause
exit /b
REM -----------------------------------------------------------------
REM Шаг 2: Подпрограмма логирования (Устранение дублирования кода)
REM -----------------------------------------------------------------
:log
if "%~1" == "" (
echo(
echo( >> "%REPORT_FILE%"
exit /b
)
echo %~1
echo %~1 >> "%REPORT_FILE%"
exit /b
