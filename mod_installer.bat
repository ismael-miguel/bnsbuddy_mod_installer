@echo off
setlocal EnableDelayedExpansion

REM set the title - https://stackoverflow.com/a/39329524
title BnS Mod installer
color 07

REM checks if the game is running - https://stackoverflow.com/a/1329790
tasklist /FI "WINDOWTITLE eq Blade & Soul" 2>nul | find /I /N "Client.exe" >nul
IF %ERRORLEVEL% EQU 0 (
	call :kill 1 "Close the game before installing Mods"
)

REM needs administrator rights - https://stackoverflow.com/a/21295806
REM we run fsutil to check the error code. 0 = admin
fsutil dirty query %SystemDrive% >nul 2>&1
IF NOT %ERRORLEVEL% EQU 0 (
	call :kill 1 "You need to execute as administrator"
)

REM tries to load the settings.ini file and get the custom mod path
IF EXIST "%~dp0/Settings.ini" (
	for /f "usebackq tokens=1* delims==" %%a in ("%~dp0/Settings.ini") do (
		if "%%a" EQU "modfolder " (
			set "MODFOLDER=%%b"
			set "MODFOLDER=!MODFOLDER: =!"
		)
	)
)

REM tries to get the default path if it wasnt possible to read from settings.ini
IF "!MODFOLDER!" EQU "" (
	REM detect the bitness - https://superuser.com/a/268384
	echo %PROCESSOR_ARCHITECTURE% | find /i "x86" >nul
	IF ERRORLEVEL 1 (
		set WIN_BITS=64
		set REGKEY="HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\NCWest\BnS"
	) ELSE (
		set WIN_BITS=32
		set REGKEY="HKEY_LOCAL_MACHINE\SOFTWARE\NCWest\BnS"
	)

	REM this key is required - https://stackoverflow.com/a/445323
	REM we check if it exists before trying to run the code
	REG QUERY !REGKEY! >nul 2>&1
	IF ERRORLEVEL 1 (
		call :colorecho "Registry key !REGKEY! not found" red black
		call :pause "Press any key to select the Mod folder"
		call :getfolder "Select the Mod folder"
		
		IF [!getfolder!] EQU [] (
			call :kill 1 "Folder selection canceled"
		)
		set "MODFOLDER=!getfolder!\"
	) ELSE (
		REM fetches the data in the registry
		for /f "tokens=2*" %%a in ('REG QUERY !REGKEY! /v BaseDir') do set "MODFOLDER=%%~b\contents\Local\NCWEST\ENGLISH\CookedPC_Mod\"

		IF NOT EXIST "!MODFOLDER!" (
			call :colorecho "!MODFOLDER! does not exist or is empty" red black
			call :pause "Press any key to select the Mod folder"
			call :getfolder "Select the Mod folder"
			
			IF [!getfolder!] EQU [] (
				call :kill 1 "Folder selection canceled"
			)
			set "MODFOLDER=!getfolder!\"
		)
	)
)

set WIDTH=80
for /f "tokens=1*" %%a in ('mode con') do (
	IF "%%a" EQU "Columns:" (
		set "WIDTH=%%b"
	)
)

:start
REM ready to create the mod
cls
call :colorecho "BnS Mod installer" black gray
echo Installs mods into BnSBuddy Mod folder
call :line
echo Mod folder: !MODFOLDER!
call :line

:choice
echo What to do next?
choice /c:qim /n /m "[Q]uit | [I]nstall Mod | [M]od folder"

IF ERRORLEVEL 3 (
	REM [M]od folder
	
	call :getfolder "Select Mob folder"
	
	IF [!getfolder!] EQU [] (
		call :colorecho "Folder selection canceled" darkyellow black
		goto choice
	) ELSE (
		set "MODFOLDER=!getfolder!\"
		goto start
	)
	
) ELSE IF ERRORLEVEL 2 (
	REM [I]nstall Mod
	
	call :getfile
	IF ERRORLEVEL 1 (
		call :colorecho "File selection canceled" darkyellow black
		goto choice
	)
	
	FOR %%f IN ("!getfile!") DO (
		set "modname=%%~nf"
		set "ext=%%~xf"
		set "filename=!modname!!ext!"
		set "filepath=%%~dpf"
	)
	
	FOR %%e IN (".upk" ".umap" ".zip" ".7z" ".rar") DO (
		IF /I %%e EQU "!ext!" (
			set "ext=%%e"
			set "ext=!ext:"=!"
			goto validext
		)
	)
	
	REM if it gets here, it means the extention isnt in the list
	call :colorecho "Invalid file type !ext!" darkred black
	goto choice
	
	:validext
	set "name=!modname!"
	set /P "name=Type a name for the mod (default: !modname!): "
	
	REM checks if there's the mod
	IF EXIST "!MODFOLDER!!name!\" (
		call :colorecho "Mod !name! already exists" darkred black
		goto validext
	)
	REM checks if there's the mod, but installed
	IF EXIST "!MODFOLDER!!name! (Installed)\" (
		call :colorecho "Mod !name! already exists" darkred black
		goto validext
	)
	
	REM create the mod, and does some bad validation
	md "!MODFOLDER!!name!" >nul 2>&1
	IF ERRORLEVEL 1 (
		call :colorecho "Invalid mod name" darkred black
		goto validext
	)
	
	set "modname=!name!"
	echo Creating Mod "!modname!"
	
	REM fugly way to detect where to run
	SET "upk=0"
	IF "!ext!" EQU ".upk" SET "upk=1"
	IF "!ext!" EQU ".umap" SET "upk=1"
	
	IF "!upk!" EQU "1" (
		echo Copying !ext! file into "!modname!"
		copy "!filepath!!filename!" "!MODFOLDER!!modname!\!filename!" /b /y >nul 2>&1
		
		echo Creating description.txt
		echo Mod !modname! contains !filename!, created with Mod Installer > "!MODFOLDER!!modname!\description.txt"
		
		call :colorecho "Mod !modname! installed successfully" darkgreen black
	) ELSE (
		echo Extracting !ext! mod into "!modname!"
		
		call :extactfile "!filepath!!filename!" "!MODFOLDER!!modname!\"
		IF ERRORLEVEL 3 (
			call :colorecho "No suitable extraction program found" darkred black
		) ELSE IF ERRORLEVEL 2 (
			call :colorecho "File extraction failed" darkred black
		) ELSE IF ERRORLEVEL 1 (
			call :colorecho "!ext! file not fount" darkred black
		) ELSE (
			REM creates the description file, if none is provided
			IF NOT EXIST "!MODFOLDER!!modname!\description.txt" (
				echo Creating description.txt
				echo Mod !modname! created with Mod Installer > "!MODFOLDER!!modname!\description.txt"
			)
			
			call :colorecho "Mod !modname! installed successfully" darkgreen black
		)
	)
	
	call :line
	goto choice
) ELSE (
	REM [Q]uit
	call :line
	call :colorecho "You decided to quit the installer" darkyellow black
)

call :kill 0 "More in http://bnsbuddy.com/ and https://www.reddit.com/r/BladeAndSoulMods/"

REM =====================
REM FUNCTION DECLARATION!
REM =====================

:line
REM draws a line width the width of the console
call :repeat _ !WIDTH!
echo %repeat%
goto :eof

:repeat
REM https://rosettacode.org/wiki/Repeat_a_string#Batch_File
REM repeats a char n times
REM %1 = char, %2 = times
REM exit: 1 = times missing
setlocal EnableDelayedExpansion

IF [%2] EQU [] (
	REM closest thing to a return
	REM explained below
	endlocal & set "repeat="
	exit /b 1
)
set char=%1
for /l %%i in (1,1,%2) do set res=!res!%char%

REM since %res% is expanded on compilation time
REM 	it will have the correct value before endlocal
REM 	has any effect, working as a "return"
endlocal & set "repeat=%res%"
goto :eof

:colorecho
REM prints a message with specific colors
REM %1 = message, %2 = text color, %3 = background color, %4 = extra arguments (like -NoNewline)
REM https://www.petri.com/change-powershell-console-font-and-background-colors
setlocal EnableDelayedExpansion

powershell -NoProfile -Noninteractive -NoLogo Write-Host %1 -ForegroundColor %2 -BackgroundColor %3 %4

goto :eof


:pause
REM handles the pausing
REM %1 = message
setlocal EnableDelayedExpansion

set a=%1
echo !a:"=!

pause >nul

goto :eof

:kill
REM creates the exit messages
REM %1 = exit code, %2 = message
setlocal EnableDelayedExpansion

IF NOT [%2] EQU [] (
	IF %1 EQU 0 (
		set a=%2
		echo !a:"=!
	) ELSE (
		call :colorecho %2 red black
	)
)

call :pause "Press any key to exit."
exit %1

goto :eof

:installupk
REM creates a mod based in an upk or umap file
REM %1 = filename, %2 = mod name
setlocal EnableDelayedExpansion

set "target=!MODFOLDER!%2\"

md "!target!"
echo "Mod created with the Mod installer script" > "!target!description.txt"

copy "!target!" "!target!%~nx1" /b /y >nul 2>&1

goto :eof


:getfile
REM selects a file
REM exit: 1 = cancelled
setlocal EnableDelayedExpansion

REM https://stackoverflow.com/a/50115044
REM fix for dialog not showing: https://stackoverflow.com/q/216710
set cmd=powershell -NoProfile -Noninteractive -NoLogo -command "&{[System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms')|Out-Null; $F = New-Object System.Windows.Forms.OpenFileDialog; $F.ShowHelp = $true; $F.filter = 'ZIP Archive (*.zip)| *.zip|7-Zip Archive (*.7z)| *.7z|Rar Archive (*.rar)| *.rar|UPK File (*.upk)| *.upk|UMAP File (*.umap)| *.rar|All files| *.*'; $F.ShowDialog()|Out-Null; $F.FileName}"

for /f "delims=" %%i in ('!cmd!') do (
	set "file=%%i"
)

IF "!file!" EQU "" (
	endlocal & set "getfile="
	exit /b 1
)

endlocal & set "getfile=%file%"
goto :eof

:getfolder
REM fetches a folder path
REM %1 = title
REM exit: 1 = cancelled
setlocal EnableDelayedExpansion

set txt="Please choose a folder."
IF NOT [%1] EQU [] (
	set txt=%1
	set txt=!txt:"=!
)

REM executes the folder dialog - https://stackoverflow.com/a/15885133
set "cmd="(new-object -COM 'Shell.Application').BrowseForFolder(0,'%txt%',0,0).self.path""
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Noninteractive -NoLogo %cmd%`) do (
	set "folder=%%I"
)

IF "!folder!" EQU "" (
	endlocal & set "getfolder="
	exit /b 1
)

endlocal & set "getfolder=%folder%"
goto :eof

:extactfile
REM extracts the file with 7-zip or winrar, whichever is available
REM %1 = file to extract, %2 = optional target for extraction
REM exit: 0 = extracted, 1 = not found, 2 = failed, 3 = no program
setlocal EnableDelayedExpansion

IF NOT EXIST %1 (
	exit /b 1
)

set "folder=%~dp1"
set "file=%~nx1"
set "filename=%~n1"

set "target=%~dp2\"
IF "!target!" EQU "" (
	SET "target=!folder!!filename!\"
)

IF EXIST "%ProgramFiles%\7-Zip\7z.exe" (
	REM https://stackoverflow.com/q/14122732
	"%ProgramFiles%\7-Zip\7z.exe" e "!folder!!file!" -bd -y -o"!target!\" >nul 2>&1
	IF ERRORLEVEL 1 (
		exit /b 2
	) ELSE (
		exit /b 0
	)
) ELSE IF EXIST "%ProgramFiles%\WinRAR\winrar.exe" (
	REM https://stackoverflow.com/a/19337595
	"%ProgramFiles%\WinRAR\winrar.exe" x -ibck "!folder!!file!" *.* "!target!\" >nul 2>&1
	IF ERRORLEVEL 1 (
		exit /b 2
	) ELSE (
		exit /b 0
	)
)

exit /b 3
