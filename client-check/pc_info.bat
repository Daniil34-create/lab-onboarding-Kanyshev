@echo off
chcp 65001 > nul

REM =================================================================
REM Тема: инструментальные средства ревьюирования, проверки на стороне клиента.
REM Выполнил: Фамилия И.О.
REM Дата: 26.10.2026
REM =================================================================

REM Определение пути к файлу отчета в той же папке
set "REPORT_FILE=%~dp0pc_report.txt"

REM Очистка старого отчета, если он существовал
echo Диагностика компьютера > "%REPORT_FILE%"
echo ==================================== >> "%REPORT_FILE%"

REM Вывод заголовка на экран
echo Диагностика компьютера
echo ====================================

REM -----------------------------------------------------------------
REM БЛОК 3: Сведения об операционной системе
REM -----------------------------------------------------------------
echo.
echo [Операционная система]
echo. >> "%REPORT_FILE%"
echo [Операционная система] >> "%REPORT_FILE%"

for /f "tokens=2 delims==" %%i in ('wmic os get Caption /value 2^>nul') do (
    if not "%%i" == "" (
        echo Название: %%i
        echo Название: %%i >> "%REPORT_FILE%"
    )
)
for /f "tokens=2 delims==" %%i in ('wmic os get Version /value 2^>nul') do (
    if not "%%i" == "" (
        echo Версия: %%i
        echo Версия: %%i >> "%REPORT_FILE%"
    )
)

REM -----------------------------------------------------------------
REM БЛОК 4: Сведения об обработчике (процессоре)
REM -----------------------------------------------------------------
echo.
echo [Процессор]
echo. >> "%REPORT_FILE%"
echo [Процессор] >> "%REPORT_FILE%"

for /f "tokens=2 delims==" %%i in ('wmic cpu get Name /value 2^>nul') do (
    if not "%%i" == "" (
        echo Модель: %%i
        echo Модель: %%i >> "%REPORT_FILE%"
    )
)

REM -----------------------------------------------------------------
REM БЛОК 5: Сведения об оперативной памяти
REM -----------------------------------------------------------------
echo.
echo [Оперативная память]
echo. >> "%REPORT_FILE%"
echo [Оперативная память] >> "%REPORT_FILE%"

for /f "tokens=2 delims==" %%i in ('wmic os get TotalVisibleMemorySize /value 2^>nul') do set "total_mem=%%i"
for /f "tokens=2 delims==" %%i in ('wmic os get FreePhysicalMemory /value 2^>nul') do set "free_mem=%%i"

REM Перевод из КБ в ГБ (деление на 1048576)
set /a total_mem_gb=%total_mem% / 1048576
set /a free_mem_gb=%free_mem% / 1048576

echo Всего памяти: %total_mem_gb% ГБ
echo Свободно памяти: %free_mem_gb% ГБ
echo Всего памяти: %total_mem_gb% ГБ >> "%REPORT_FILE%"
echo Свободно памяти: %free_mem_gb% ГБ >> "%REPORT_FILE%"

REM -----------------------------------------------------------------
REM БЛОК 6: Свободное место на диске
REM -----------------------------------------------------------------
echo.
echo [Диск C]
echo. >> "%REPORT_FILE%"
echo [Диск C] >> "%REPORT_FILE%"

for /f "tokens=2 delims==" %%i in ('wmic logicaldisk where DeviceID^="C:" get Size /value 2^>nul') do set "disk_size=%%i"
for /f "tokens=2 delims==" %%i in ('wmic logicaldisk where DeviceID^="C:" get FreeSpace /value 2^>nul') do set "disk_free=%%i"

REM Перевод из Байт в ГБ (деление на 1073741824). 
REM Чтобы избежать переполнения 32-битных чисел в BAT, сначала делим на 1024, потом на 1048576
set /a disk_size_kb=%disk_size:~0,-3% / 1048576
set /a disk_free_kb=%disk_free:~0,-3% / 1048576

echo Общий размер: %disk_size_kb% ГБ
echo Свободное место: %disk_free_kb% ГБ
echo Общий размер: %disk_size_kb% ГБ >> "%REPORT_FILE%"
echo Свободное место: %disk_free_kb% ГБ >> "%REPORT_FILE%"

REM -----------------------------------------------------------------
REM БЛОК 7: Список установленных программ (через Реестр)
REM -----------------------------------------------------------------
echo.
echo [Установленные программы]
echo Идет сбор данных из реестра...
echo. >> "%REPORT_FILE%"
echo [Установленные программы] >> "%REPORT_FILE%"

REM Сбор из 64-бит и 32-бит веток реестра, фильтрация DisplayName и очистка мусора
for /f "tokens=2*" %%a in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s /f DisplayName 2^>nul ^| findstr "DisplayName"') do (
    echo %%b
    echo %%b >> "%REPORT_FILE%"
)
for /f "tokens=2*" %%a in ('reg query "HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s /f DisplayName 2^>nul ^| findstr "DisplayName"') do (
    echo %%b
    echo %%b >> "%REPORT_FILE%"
)

REM -----------------------------------------------------------------
REM БЛОК 8: Завершение работы
REM -----------------------------------------------------------------
echo.
echo ====================================
echo Отчёт успешно сохранён в файл pc_report.txt
echo ====================================
echo.

pause
