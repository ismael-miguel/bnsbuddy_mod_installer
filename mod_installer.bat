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
	powershell -NoProfile -Noninteractive -NoLogo Start-Process ""%0"" -Verb runas >nul 2>&1
	IF ERRORLEVEL 1 (
		call :kill 1 "You need to execute as administrator"
	) ELSE (
		exit /b 0
	)
)

REM tries to load the settings.ini file and get the custom mod path
IF EXIST "%~dp0/Settings.ini" (
	for /f "usebackq tokens=1* delims==" %%a in ("%~dp0/Settings.ini") do (
		for /f "tokens=* delims= " %%b in ("%%b") do set "value=%%b"
		set "key=%%a"
		
		IF "!key!" EQU "modfolder " (
			REM set "MODFOLDER=!value: =!"
			set "MODFOLDER=!value!"
		) ELSE IF "!key!" EQU "customgamepath " (
			REM set "GAMEFOLDER=!value: =!"
			set "GAMEFOLDER=!value!"
			set "GAMEMODFOLDER=!GAMEFOLDER!\contents\Local\NCWEST\ENGLISH\CookedPC\mod"
		) ELSE IF "!key!" EQU "default " (
			IF NOT "!value!" EQU "" (
				REM set "GAMEFOLDER=!value: =!"
				set "GAMEFOLDER=!value!"
				set "GAMEMODFOLDER=!GAMEFOLDER!\contents\Local\NCWEST\ENGLISH\CookedPC\mod"
			)
		)
	)
)

REM tries to get the game path from the registry
set "REGFOLDER="
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
	call :colorecho "Registry key !REGKEY! not found, mod installation disabled" red black
) ELSE (
	REM fetches the data in the registry
	for /f "tokens=2*" %%a in ('REG QUERY !REGKEY! /v BaseDir') do set "REGFOLDER=%%~b"

	IF NOT EXIST "!REGFOLDER!" (
		call :colorecho "!MODFOLDER! does not exist or is empty" red black
	)
)

REM sets the default path if it wasnt possible to read from settings.ini
IF "!MODFOLDER!" EQU "" (
	IF "!REGFOLDER!" EQU "" (
		call :colorecho "Mod folder could not be determinated automatically" red black
		call :pause "Press any key to select the BnSBuddy Mod folder"
		call :getfolder "Select the BnSBuddy Mod folder"
		
		IF [!getfolder!] EQU [] (
			call :kill 1 "Folder selection canceled"
		)
		set "MODFOLDER=!getfolder!\"
	) ELSE (
		set "MODFOLDER=!REGFOLDER!\contents\Local\NCWEST\ENGLISH\CookedPC_Mod\"
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
IF NOT "!REGFOLDER!" EQU "" (
	echo Game folder: !REGFOLDER!
)
IF NOT "!GAMEMODFOLDER!" EQU "" (
	echo Game Mod folder: !GAMEMODFOLDER!
)
echo Mod folder: !MODFOLDER!
call :line

:choice
echo What to do next?
choice /c:qibg /n /m "[Q]uit | [I]nstall Mod | [B]nSBuddy Mod folder | [G]ame Mod folder"

IF ERRORLEVEL 4 (
	REM [G]ame folder
	
	call :getfolder "Select Game Mod folder"
	
	IF [!getfolder!] EQU [] (
		call :colorecho "Folder selection canceled" darkyellow black
		goto choice
	) ELSE (
		set "GAMEMODFOLDER=!getfolder!\"
		goto start
	)
	
) ELSE IF ERRORLEVEL 3 (
	REM [B]nSBuddy Mod folder
	
	call :getfolder "Select BnSBuddy Mob folder"
	
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
	
	FOR %%e IN (".upk" ".umap" ".zip" ".rar" ".7z") DO (
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
	set "name=!modname:~0,30!"
	set /P "name=Type a name for the mod (default: !name!, max 30 chars): "
	
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
	REM checks the string length
	REM https://ss64.com/nt/syntax-strlen.html
	IF NOT "!name:~31,1!" EQU "" (
		call :colorecho "The !name! is too long" darkred black
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
		echo Mod !modname! contains !filename!, created with Mod Creator > "!MODFOLDER!!modname!\description.txt"
		
		call :colorecho "Mod !modname! installed successfully" darkgreen black
	) ELSE (
		echo Extracting !ext! mod into "!modname!"
		
		call :extractfile "!filepath!!filename!" "!MODFOLDER!!modname!\"
		IF ERRORLEVEL 4 (
			call :colorecho "Unknown error" darkred black
		) ELSE IF ERRORLEVEL 3 (
			call :colorecho "No suitable extraction program found" darkred black
		) ELSE IF ERRORLEVEL 2 (
			call :colorecho "File extraction failed" darkred black
		) ELSE IF ERRORLEVEL 1 (
			call :colorecho "!ext! file not found" darkred black
		) ELSE (
			echo Mod "!modname!" extracted successfully, moving all files out of subfolders
			call :flattenfolder "!MODFOLDER!!modname!\"
			REM creates the description file, if none is provided
			IF NOT EXIST "!MODFOLDER!!modname!\description.txt" (
				echo Creating description.txt
				echo Mod !modname! created with Mod Creator > "!MODFOLDER!!modname!\description.txt"
			)
			
			call :colorecho "Mod !modname! installed successfully" darkgreen black
			
			REM shoves the entire file into stdout
			IF EXIST "!MODFOLDER!!modname!\readme.txt" (
				echo.
				call :colorecho "== README ==" black gray
				type "!MODFOLDER!!modname!\readme.txt"
				REM empty echo for newline :/
				echo.
				call :colorecho "== README END ==" black gray
				echo.
			)
			
			IF NOT "!GAMEMODFOLDER!" EQU "" (
				call :line
				echo|set /p="Install mod to the game? "
				choice /c:ny /n /m "[Y]es | [N]o "
				IF ERRORLEVEL 2 (
					call :colorecho "Applying mod !modname!" darkyellow black
					call :modgame "!modname!" "!GAMEMODFOLDER!" "!MODFOLDER!"
				)
			)
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

powershell -NoProfile -Noninteractive -NoLogo Write-Host ""%1"" -ForegroundColor %2 -BackgroundColor %3 %4

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
set cmd=powershell -NoProfile -Noninteractive -NoLogo -command "&{[System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms')|Out-Null; $F = New-Object System.Windows.Forms.OpenFileDialog; $F.ShowHelp = $true; $F.filter = 'ZIP Archive (*.zip)| *.zip|Rar Archive (*.rar)| *.rar|7z Archive (*.7z)| *.7z|UPK File (*.upk)| *.upk|UMAP File (*.umap)| *.rar|All files| *.*'; $F.ShowDialog()|Out-Null; $F.FileName}"

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

:extractfile
REM extracts the file with whichever program is available
REM %1 = file to extract, %2 = optional target for extraction
REM exit: 0 = extracted, 1 = not found, 2 = failed, 3 = no program
set "extractfile="
setlocal EnableDelayedExpansion
set "folder=%~dp1"
set "file=%~nx1"
set "filename=%~n1"

IF NOT EXIST "!folder!!file!" (
	exit /b 1
)

set "target=%~dp2\"
IF "!target!" EQU "\" (
	SET "target=!folder!!filename!\"
)

IF EXIST "%ProgramFiles%\7-Zip\7z.exe" (
	REM https://stackoverflow.com/q/14122732
	"%ProgramFiles%\7-Zip\7z.exe" x "!folder!!file!" -bd -y -o"!target!\" >nul 2>&1
) ELSE IF EXIST "%ProgramFiles%\WinRAR\winrar.exe" (
	REM https://stackoverflow.com/a/19337595
	"%ProgramFiles%\WinRAR\winrar.exe" x -ibck "!folder!!file!" *.* "!target!\" >nul 2>&1
) ELSE IF EXIST "%ProgramFiles%\winzip\wzzip.exe" (
	REM http://kb.winzip.com/kb/entry/125/ - WZCLINE.CHM
	"%ProgramFiles%\winzip\wzzip.exe" -d "!folder!!file!" "!target!\" >nul 2>&1
) ELSE (
	exit /b 3
)

IF ERRORLEVEL 1 (
	exit /b 2
)

endlocal & set "extractfile=!target!\"
goto :eof


:flattenfolder
REM puts all files in the same folders and deletes empty folders
REM %1 = folder to flatten
REM exit: 0 = done, 1 = not found
setlocal EnableDelayedExpansion

set "folder=%1"
set "folder=!folder:"=!\"

IF NOT EXIST "!folder!" (
	exit /b 1
)

REM https://superuser.com/a/746636
REM moves all files to the same folder
cd "!folder!"
FOR /r %%f IN (*.*) DO (
	move /Y "%%f" "!folder!" >nul 2>&1
	IF ERRORLEVEL 1 (
		echo Could not move the file %%f
	)
)

REM https://superuser.com/a/39679
REM removes empty folders
FOR /f "delims=" %%d IN ('dir /s /b /ad "!folder!"^| sort /r') DO (
	rd "%%d" >nul 2>&1
	IF ERRORLEVEL 1 (
		echo Could not remove the folder %%d
	)
)

goto :eof


:modgame
REM installs the mod into the game folder
REM %1 = game folder, %2 = mod folder
REM exit: 0 = done, 1 = error
setlocal EnableDelayedExpansion

set "mod=%1"
set "mod=!mod:"=!"

set "gamedrive=%~d2"
set "gamefolder=%2"
set "gamefolder=!gamefolder:"=!\"

set "moddrive=%~d3"
set "modfolder=%3"
set "modfolder=!modfolder:"=!\"

mkdir "!gamefolder!!mod!"
IF ERRORLEVEL 1 (
	call :colorecho "Could not create the folder !mod! in !gamefolder!" darkred black
	exit /b 1
)
IF NOT EXIST "!gamefolder!!mod!" (
	call :colorecho "Folder !mod! not found in !gamefolder!" darkred black
	exit /b 1
)

IF "!gamedrive!" EQU "!moddrive!" (
	REM if the drive isnt ntfs, it will give an error
	fsutil fsinfo ntfsinfo !gamedrive! >nul 2>&1
	IF NOT ERRORLEVEL 1 (
		set "optimize=1"
	)
)
	
IF "!optimize!" EQU "1" (
	IF EXIST "!modfolder!!mod!\*.upk" (
		FOR /f "tokens=*" %%F in ('dir /b "!modfolder!!mod!\*.upk"') do (
			mklink /h "!gamefolder!!mod!\%%F" "!modfolder!!mod!\%%F" >nul 2>&1
		)
	)
	IF EXIST "!modfolder!!mod!\*.umap" (
		FOR /f "tokens=*" %%F in ('dir /b "!modfolder!!mod!\*.umap"') do (
			mklink /h "!gamefolder!!mod!\%%F" "!modfolder!!mod!\%%F" >nul 2>&1
		)
	)
) ELSE (
	call :colorecho "To save space, make sure that BnS and the BnSBuddy folder are in the same drive" darkyellow black

	IF EXIST "!modfolder!!mod!\*.upk" (
		xcopy "!modfolder!!mod!\*.upk" "!gamefolder!!mod!\" /i /s /q /y >nul 2>&1
	)
	IF EXIST "!modfolder!!mod!\*.umap" (
		xcopy "!modfolder!!mod!\*.umap" "!gamefolder!!mod!\" /i /s /q /y >nul 2>&1
	)
)

move "!modfolder!!mod!" "!modfolder!!mod! (Installed)" >nul 2>&1
IF ERRORLEVEL 1 (
	call :colorecho "Could not mark the !mod! as installed" darkred black
	
)

goto :eof
