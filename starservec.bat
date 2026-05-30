@echo off
title Servidor Local - Game de Estudos
chcp 65001 > nul
echo ======================================================
echo 🚀 Iniciando Servidor Local - Game de Estudos
echo ======================================================
echo.

:: Verifica se o arquivo .env já existe
if exist .env (
    echo [OK] Configurações automáticas encontradas (.env).
    goto start_server
)

:: Se não existir .env e nem a variável de ambiente do sistema, solicita a chave
if "%GEMINI_API_KEY%"=="" (
    echo [AVISO] Chave GEMINI_API_KEY não configurada.
    echo Para utilizar a Inteligência Artificial localmente, digite sua chave uma única vez:
    set /p KEY_INPUT="Cole sua API Key do Gemini aqui e aperte ENTER (ou dê ENTER em branco para simular): "
)

if not "%KEY_INPUT%"=="" (
    echo GEMINI_API_KEY=%KEY_INPUT% > .env
    echo [OK] Chave gravada no arquivo .env local! nas próximas inicializações isso será automático.
)

:start_server
echo.
echo Iniciando o servidor na porta 3000...
node server.js
pause

