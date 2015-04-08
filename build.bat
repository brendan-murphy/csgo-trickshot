@echo off
del "C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\csgo\addons\sourcemod\scripting\trickshot.sp"
copy "D:\csgo-trickshot\scripting\trickshot.sp" "C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\csgo\addons\sourcemod\scripting\trickshot.sp"

PAUSE
REM
C:
cd "C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\csgo\addons\sourcemod\scripting"
compile

PAUSE
REM

del "..\plugins\trickshot.smx"
copy "compiled\trickshot.smx" "..\plugins\trickshot.smx"

ECHO Launch CS:GO server?
PAUSE
REM
"C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\runServer.bat"
