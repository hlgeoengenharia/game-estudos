@echo off
title Deploy - Game de Estudos
chcp 65001 > nul
echo ======================================================
echo 🚀 Iniciando Processo de Deploy - Game de Estudos
echo ======================================================
echo.

echo Verificando alterações locais...
git status
echo.

set /p PROCEED="Deseja realizar o deploy dessas alterações? (S/N): "
if /i "%PROCEED%" neq "S" (
    echo.
    echo Deploy cancelado pelo usuário.
    goto end
)

echo.
set /p COMMIT_MSG="Digite a mensagem do commit (ou pressione ENTER para usar a padrão): "

if "%COMMIT_MSG%"=="" (
    set COMMIT_MSG=Atualização automática - %date% %time%
)

echo.
echo Adicionando arquivos ao Git...
git add .

echo.
echo Criando o commit: "%COMMIT_MSG%"...
git commit -m "%COMMIT_MSG%"

echo.
echo Enviando para o GitHub (branch main)...
git push origin main

if %ERRORLEVEL% equ 0 (
    echo.
    echo ======================================================
    echo 🎉 Deploy concluído com sucesso no GitHub!
    echo A Vercel deve iniciar a publicação automaticamente em instantes.
    echo ======================================================
) else (
    echo.
    echo ❌ Ocorreu um erro ao enviar as alterações para o GitHub.
    echo Verifique sua conexão e credenciais do Git.
)

:end
echo.
pause
