@echo off
setlocal enabledelayedexpansion

:: auto-commit.bat - Script para gerar mensagens de commit automaticamente
:: Uso: auto-commit.bat [tipo] [escopo]
:: Exemplo: auto-commit.bat feat compilador

:: Configurações
set "DEFAULT_TYPE=feat"
set "MAX_SUBJECT_LENGTH=50"

:: Cores para output (Windows 10+ com VT suporte)
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

:: Função para mostrar ajuda
if "%1"=="/?" goto show_help
if "%1"=="-h" goto show_help
if "%1"=="--help" goto show_help

:: Verificar se estamos em um repositório git
git rev-parse --git-dir > nul 2>&1
if errorlevel 1 (
    echo %RED%Erro: Este diretório n%%C3%%A3o é um reposit%%C3%%B3rio git!%NC%
    exit /b 1
)

:: Verificar se há mudanças para commit
git diff --cached --quiet
if not errorlevel 1 (
    echo %YELLOW%Nenhuma mudan%%C3%%A7a staged para commit.%NC%
    echo Execute 'git add' primeiro ou use 'git add -A ^&^& auto-commit.bat'
    exit /b 1
)

:: Parâmetros
set "COMMIT_TYPE=%1"
if "%COMMIT_TYPE%"=="" set "COMMIT_TYPE=%DEFAULT_TYPE%"
set "SCOPE=%2"

:: Validar tipo de commit
set "VALID_TYPE=0"
for %%t in (feat fix docs style refactor test chore perf ci build) do (
    if "%COMMIT_TYPE%"=="%%t" set "VALID_TYPE=1"
)

if "%VALID_TYPE%"=="0" (
    echo %RED%Tipo de commit inv%%C3%%A1lido: %COMMIT_TYPE%%NC%
    call :show_help
    exit /b 1
)

:: Analisar mudanças
echo %BLUE%Analisando mudan%%C3%%A7as...%NC%

:: Obter estatísticas (usando PowerShell para processamento)
for /f "tokens=*" %%a in ('git diff --cached --stat') do set "STATS=%%a"
for /f "tokens=*" %%a in ('git diff --cached --name-only') do set "FILES_CHANGED=%%a"

:: Usar PowerShell para calcular adições e deleções
for /f %%a in ('powershell -Command "git diff --cached --numstat | ForEach-Object { $sum=0; $_.Split(\"`t\")[0] -as [int] } | Measure-Object -Sum | Select-Object -ExpandProperty Sum"') do set "ADDITIONS=%%a"
if "%ADDITIONS%"=="" set "ADDITIONS=0"

for /f %%a in ('powershell -Command "git diff --cached --numstat | ForEach-Object { $sum=0; $_.Split(\"`t\")[1] -as [int] } | Measure-Object -Sum | Select-Object -ExpandProperty Sum"') do set "DELETIONS=%%a"
if "%DELETIONS%"=="" set "DELETIONS=0"

:: Gerar descrição automática
call :generate_message "%FILES_CHANGED%"

:: Construir mensagem de commit
set "COMMIT_MSG="
if not "%SCOPE%"=="" (
    set "COMMIT_MSG=%COMMIT_TYPE%(%SCOPE%): %DESCRIPTION%"
) else (
    set "COMMIT_MSG=%COMMIT_TYPE%: %DESCRIPTION%"
)

:: Truncar se muito longo
set "MSG_LEN=0"
for /l %%i in (0,1,100) do if not "!COMMIT_MSG:~%%i,1!"=="" set /a MSG_LEN+=1

if %MSG_LEN% gtr %MAX_SUBJECT_LENGTH% (
    set "COMMIT_MSG=!COMMIT_MSG:~0,%MAX_SUBJECT_LENGTH%!..."
)

:: Mostrar informações
echo %GREEN%Resumo das mudan%%C3%%A7as:%NC%
echo %STATS%
echo.
echo %GREEN%Arquivos modificados:%NC%
echo %FILES_CHANGED%
echo.
echo %YELLOW%Linhas: +%ADDITIONS% -%DELETIONS%%NC%
echo.
echo %GREEN%Mensagem de commit gerada:%NC%
echo %BLUE%!COMMIT_MSG!%NC%
echo.

:: Confirmar commit
set /p "confirm=Confirmar commit? (y/N): "
if /i "!confirm!"=="y" (
    git commit -m "!COMMIT_MSG!"
    if errorlevel 1 (
        echo %RED%Erro ao realizar commit!%NC%
        exit /b 1
    )
    echo %GREEN%Commit realizado com sucesso!%NC%
) else (
    echo %YELLOW%Commit cancelado.%NC%
    exit /b 1
)

exit /b 0

:show_help
echo %BLUE%Uso: auto-commit.bat [tipo] [escopo]%NC%
echo.
echo Tipos dispon%%C3%%ADveis:
echo   feat     - Nova funcionalidade
echo   fix      - Corre%%C3%%A7%%C3%%A3o de bug
echo   docs     - Documenta%%C3%%A7%%C3%%A3o
echo   style    - Formata%%C3%%A7%%C3%%A3o, lint
echo   refactor - Refatora%%C3%%A7%%C3%%A3o de c%%C3%%B3digo
echo   test     - Adi%%C3%%A7%%C3%%A3o/corre%%C3%%A7%%C3%%A3o de testes
echo   chore    - Tarefas de manuten%%C3%%A7%%C3%%A3o
echo.
echo Exemplos:
echo   auto-commit.bat feat compilador
echo   auto-commit.bat fix parser
echo   auto-commit.bat docs readme
exit /b 0

:generate_message
set "files_list=%~1"
set "message="

:: Análise de arquivos modificados
echo %files_list% | findstr /i "\.py$" > nul
if not errorlevel 1 (
    echo %files_list% | findstr /i "test" > nul
    if not errorlevel 1 (
        set "message=adiciona/atualiza testes Python"
    ) else (
        set "message=implementa funcionalidades Python"
    )
) else (
    echo %files_list% | findstr /i "README readme" > nul
    if not errorlevel 1 (
        set "message=atualiza documenta%%C3%%A7%%C3%%A3o"
    ) else (
        echo %files_list% | findstr /i "\.md$" > nul
        if not errorlevel 1 (
            set "message=atualiza documenta%%C3%%A7%%C3%%A3o Markdown"
        ) else (
            echo %files_list% | findstr /i "requirements setup Dockerfile" > nul
            if not errorlevel 1 (
                set "message=atualiza configura%%C3%%A7%%C3%%B5es do projeto"
            ) else (
                echo %files_list% | findstr /i "\.json$ \.yaml$ \.yml$ \.toml$" > nul
                if not errorlevel 1 (
                    set "message=atualiza arquivos de configura%%C3%%A7%%C3%%A3o"
                ) else (
                    echo %files_list% | findstr /i "\.bat$ \.ps1$ \.cmd$" > nul
                    if not errorlevel 1 (
                        set "message=atualiza scripts Windows"
                    ) else (
                        :: Análise baseada em estatísticas
                        if %ADDITIONS% gtr %DELETIONS% (
                            if %ADDITIONS% gtr 100 (
                                set "message=implementa nova funcionalidade"
                            ) else (
                                set "message=adiciona melhorias"
                            )
                        ) else if %DELETIONS% gtr %ADDITIONS% (
                            set "message=remove c%%C3%%B3digo desnecess%%C3%%A1rio"
                        ) else (
                            set "message=refatora c%%C3%%B3digo existente"
                        )
                    )
                )
            )
        )
    )
)

if "%message%"=="" set "message=atualiza c%%C3%%B3digo"
set "DESCRIPTION=%message%"
exit /b 0