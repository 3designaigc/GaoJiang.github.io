# deploy_to_github_pages.ps1
# 自動同步 FAMM 本地開發檔案至 GitHub Pages 本地儲存庫並推送至 GitHub

$SrcDir = "f:\Resilio\agent\GitWeb\public\FAMM"
$DestDir = "F:\Github\GaoJiang.github.io"

Write-Host "====== 開始同步 FAMM 3D 組立可視化檔案 ======" -ForegroundColor Cyan

if (!(Test-Path $DestDir)) {
    Write-Error "找不到目標 GitHub 儲存庫路徑: $DestDir"
    exit
}

# 1. 複製 HTML 檔案
Write-Host "正在複製 HTML 網頁檔案..." -ForegroundColor Yellow
Copy-Item -Path "$SrcDir\*.html" -Destination $DestDir -Force

# 2. 複製 GLB 3D 模型資料夾（只複製更新或新增的檔案）
Write-Host "正在同步 glb 3D 模型資源..." -ForegroundColor Yellow
if (Test-Path "$SrcDir\glb") {
    if (!(Test-Path "$DestDir\glb")) {
        New-Item -ItemType Directory -Path "$DestDir\glb" | Out-Null
    }
    # 使用 robocopy 進行高效資料夾差異同步 (只複製有變更的檔案)
    robocopy "$SrcDir\glb" "$DestDir\glb" /E /XO /NJH /NJS /NDL /NC /NS | Out-Null
}

Write-Host "複製完成！準備提交至 GitHub..." -ForegroundColor Green

# 3. 執行 Git 提交與推送
Push-Location $DestDir
try {
    Write-Host "目前 Git 狀態：" -ForegroundColor Cyan
    git status -s

    Write-Host "正在將變更加入 Git 暫存區..." -ForegroundColor Yellow
    git add -A

    # 執行 git diff-index 檢查是否有已暫存的變更
    git diff-index --quiet HEAD --
    if ($LASTEXITCODE -eq 0) {
        Write-Host "沒有偵測到任何新增變更，儲存庫已是最新狀態。" -ForegroundColor Green
    } else {
        $CommitMsg = "Update GaoJiang visualizer premium features - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Write-Host "正在提交變更: $CommitMsg" -ForegroundColor Yellow
        git commit -m $CommitMsg
        
        # 取得目前的 remote 分支名稱並推送
        $Branch = git branch --show-current
        Write-Host "正在推送至 GitHub 遠端分支 ($Branch)..." -ForegroundColor Yellow
        git push origin $Branch
        
        Write-Host "====== 同步並部署完成！ ======" -ForegroundColor Green
        Write-Host "網頁已發布！約 1~2 分鐘後即可在線上查看最新效果。" -ForegroundColor Cyan
    }
}
catch {
    Write-Error "Git 同步過程中發生錯誤！"
}
finally {
    Pop-Location
}
