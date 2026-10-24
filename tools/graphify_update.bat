@echo off
setlocal enabledelayedexpansion
REM ===========================================================================
REM graphify_update.bat  --  Flutter camera package graph refresh
REM
REM Manual, no-AI live-graph refresh + smoke test. Run it after code changes
REM or to check graphify works.
REM
REM What it does (no LLM, no API key, no token cost):
REM   [1/2] Code-only AST refresh of the LIVE root graphify-out\graph.json via
REM         `graphify update` once per package. GRAPHIFY_OUT is pointed at the
REM         root folder and each package is passed absolute -- both required,
REM         otherwise the CLI writes stray package graphs or re-anchors node ids.
REM         Directed flag + community labels are kept.
REM         Docs are not re-extracted; a FIRST build is the skill flow
REM              /graphify camera/ camera_android/ camera_android_camerax/ camera_platform_interface/ --directed
REM         inside Claude -- never delete graph.json before running this bat.
REM   [2/2] Smoke test -- confirm the live root graph exists, is directed, and
REM         answers a query. This is the "does graphify actually work here" check.
REM ===========================================================================

REM ---- package folders included in the merged graph ----------------------------
set "CODE_DIRS=camera camera_android camera_android_camerax camera_platform_interface"
REM -----------------------------------------------------------------------------

REM This bat lives in tools\ ; run everything from the repo root so graphify
REM resolves the live graph at .\graphify-out\ (relative to cwd).
pushd "%~dp0.."

REM Resolve the graphify launcher: prefer PATH, else derive from the interpreter
REM the last build saved (graphify.exe sits next to that python.exe).
set "GRAPHIFY=graphify"
where graphify >nul 2>nul
if errorlevel 1 (
  if exist "graphify-out\.graphify_python" (
    set /p GPY=<graphify-out\.graphify_python
    set "GRAPHIFY=!GPY:python.exe=graphify.exe!"
  ) else (
    echo ERROR: graphify not on PATH and no graphify-out\.graphify_python found.
    echo Build the graph once in Claude:  /graphify camera/ camera_android/ camera_android_camerax/ camera_platform_interface/ --directed
    popd
    endlocal
    exit /b 1
  )
)

echo === [1/2] live-graph AST refresh (no LLM) ===
set "GRAPHIFY_OUT=%CD%\graphify-out"
for %%D in (%CODE_DIRS%) do (
  echo Refreshing %%D
  "%GRAPHIFY%" update "%CD%\%%D"
  if errorlevel 1 (
    echo ERROR: graphify update failed for %%D.
    popd
    endlocal
    exit /b 1
  )
)
echo.

echo === [2/2] smoke test: live root graph ===
if not exist "graphify-out\graph.json" (
  echo ERROR: graphify-out\graph.json not found.
  echo Build it in Claude:  /graphify camera/ camera_android/ camera_android_camerax/ camera_platform_interface/ --directed
  popd
  endlocal
  exit /b 1
)
REM Report directed flag + node count of the LIVE root graph (should be directed:True).
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; try { $graph=Get-Content 'graphify-out/graph.json' -Raw | ConvertFrom-Json; Write-Output ('directed: {0}  nodes: {1}' -f $graph.directed,$graph.nodes.Count); if ($graph.directed -isnot [bool] -or -not $graph.directed) { exit 1 } } catch { Write-Error $_; exit 1 }"
if errorlevel 1 (
  echo ERROR: graphify smoke test failed.
  popd
  endlocal
  exit /b 1
)
echo.
echo --- god nodes (top 5) ---
"%GRAPHIFY%" god-nodes --top 5
if errorlevel 1 (
  echo ERROR: graphify god-nodes failed.
  popd
  endlocal
  exit /b 1
)
echo.
echo --- sample query ---
"%GRAPHIFY%" query "What are the main modules and how do they connect?"
set "RESULT=%ERRORLEVEL%"

popd
endlocal & exit /b %RESULT%
