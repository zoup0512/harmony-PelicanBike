@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion
REM HarmonyOS Project One-Click Push To GitHub
REM 鸿蒙项目一键上传GitHub脚本

REM ====================== 必填配置项 ======================
set GITHUB_USERNAME=zoup0512
REM 仓库公开false / 私有true
set PRIVATE_REPO=false
REM =========================================================

REM 从系统环境变量读取GitHub Token（不硬编码到文件中，避免泄露）
if "%GITHUB_TOKEN%"=="" (
    echo [x] 未检测到环境变量 GITHUB_TOKEN，请先设置！
    echo     设置方法：set GITHUB_TOKEN=ghp_你的token
    pause
    exit /b 1
)

REM 获取当前目录名作为项目名称
for %%F in ("%CD%") do set REPO_NAME=%%~nF

echo =============================================
echo   HarmonyOS 鸿蒙项目一键上传GitHub工具
echo   项目名称: %REPO_NAME%
echo   仓库隐私: %PRIVATE_REPO%
echo =============================================

REM 1. 初始化本地Git仓库
if not exist .git (
    echo [1/6] 初始化本地Git仓库...
    git init
    if errorlevel 1 (
        echo [x] Git初始化失败！
        pause
        exit /b 1
    )
) else (
    echo [1/6] 本地Git仓库已存在，跳过初始化
)

REM 2. 生成鸿蒙专属标准.gitignore
echo [2/6] 生成HarmonyOS工程专属 .gitignore 文件...
(echo # HarmonyOS .gitignore) > .gitignore
(echo .idea/) >> .gitignore
(echo .ohos/) >> .gitignore
(echo .hvigor/) >> .gitignore
(echo *.iml) >> .gitignore
(echo *.iws) >> .gitignore
(echo *.ipr) >> .gitignore
(echo modules.xml) >> .gitignore
(echo compiler.xml) >> .gitignore
(echo navigation.xml) >> .gitignore
(echo build/) >> .gitignore
(echo out/) >> .gitignore
(echo cache/) >> .gitignore
(echo generated/) >> .gitignore
(echo hvigor-build/) >> .gitignore
(echo oh-build/) >> .gitignore
(echo entry/build/) >> .gitignore
(echo feature/build/) >> .gitignore
(echo */build/) >> .gitignore
(echo */oh-build/) >> .gitignore
(echo oh_modules/) >> .gitignore
(echo node_modules/) >> .gitignore
(echo local.properties) >> .gitignore
(echo signing.properties) >> .gitignore
(echo *.p12) >> .gitignore
(echo *.jks) >> .gitignore
(echo *.keystore) >> .gitignore
(echo secret.key) >> .gitignore
(echo *.log) >> .gitignore
(echo *.tmp) >> .gitignore
(echo *.dump) >> .gitignore
(echo lint-report*) >> .gitignore
(echo build-log*) >> .gitignore
(echo package-lock.json) >> .gitignore
(echo yarn.lock) >> .gitignore
(echo .DS_Store) >> .gitignore
(echo Thumbs.db) >> .gitignore
(echo *.swp) >> .gitignore
(echo *.swo) >> .gitignore

REM 3. 全局Git用户配置补全
git config --get user.name >nul 2>&1
if errorlevel 1 (
    git config user.name "%GITHUB_USERNAME%"
)
git config --get user.email >nul 2>&1
if errorlevel 1 (
    git config user.email "%GITHUB_USERNAME%@users.noreply.github.com"
)

REM 4. 提交全部代码
echo [3/6] 暂存并提交全部鸿蒙项目代码...
git add .
git commit -m "Initial commit: HarmonyOS project init"
if errorlevel 1 (
    echo [!] 提交可能无变更或失败，继续执行...
)

REM 5. API创建GitHub远程仓库
echo [4/6] 正在GitHub创建远程仓库...
curl -s -X POST -H "Authorization: token %GITHUB_TOKEN%" -H "Accept: application/vnd.github.v3+json" https://api.github.com/user/repos -d "{\"name\":\"%REPO_NAME%\",\"private\":%PRIVATE_REPO%,\"description\":\"HarmonyOS APP Project\",\"auto_init\":false}" > "%TEMP%\gh_create_result.json"

REM 校验创建结果
findstr /C:"\"id\"" "%TEMP%\gh_create_result.json" >nul 2>&1
if errorlevel 1 (
    echo [x] 远程仓库创建失败！
    echo ---------- 返回信息 ----------
    type "%TEMP%\gh_create_result.json"
    echo ------------------------------
    pause
    exit /b 1
) else (
    echo [v] 远程仓库创建成功！
)

REM 6. 关联远程并推送代码
echo [5/6] 关联远程仓库并推送代码...
set REMOTE_URL=https://%GITHUB_TOKEN%@github.com/%GITHUB_USERNAME%/%REPO_NAME%.git

git remote remove origin >nul 2>&1
git remote add origin %REMOTE_URL%

git branch -M main
git push -u origin main
if errorlevel 1 (
    echo [x] 推送代码失败！
    pause
    exit /b 1
)

REM 完成提示
echo [6/6] 全部任务完成！
echo.
echo 鸿蒙项目地址：https://github.com/%GITHUB_USERNAME%/%REPO_NAME%
echo.
pause
