@echo off
setlocal
if not exist "%~dp0analyze_code_config.bat" (
    echo ERROR: analyze_code_config.bat not found.
    echo Copy analyze_code_config.example.bat to analyze_code_config.bat and set CLI_ANALYZER_PATH.
    exit /b 1
)
call "%~dp0analyze_code_config.bat"
pushd "%~dp0.."

set "RESULT=0"
for %%P in (camera camera_android camera_android_camerax camera_platform_interface camera\example camera_android\example camera_android_camerax\example) do (
    echo Analyzing changed files under %%P
    "%CLI_ANALYZER_PATH%\venv\Scripts\python.exe" "%CLI_ANALYZER_PATH%\main.py" --language %LANGUAGE% --path "%%P" --only-changed --verbosity minimal --output "code_analysis_results\%%P" --rules "code_analysis_rules.json"
    if errorlevel 1 set "RESULT=1"
)

popd
endlocal & exit /b %RESULT%
