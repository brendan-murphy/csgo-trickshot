@echo off
cd "C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\csgo\addons\sourcemod\scripting"
del "scripting\trickshot.sp"
copy "C:\csgo-trickshot\scripting\trickshot.sp" "trickshot.sp"

PAUSE
REM

compile

PAUSE
REM

del "..\plugins\trickshot.smx"
copy "compiled\trickshot.smx" "..\plugins\trickshot.smx"

ECHO Launch CS:GO server?
PAUSE
REM
"C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\serverRun.bat"