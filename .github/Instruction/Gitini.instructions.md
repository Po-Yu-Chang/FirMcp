#!/bin/bash

# 檢查遠端儲存庫是否存在
REPO_EXISTS=$(curl -s -o /dev/null -w "%{http_code}" https://api.github.com/repos/Po-Yu-Chang/FirMcp)

if [ "$REPO_EXISTS" == "200" ]; then
    echo "儲存庫已存在，進行複製"
    git clone https://github.com/Po-Yu-Chang/FirMcp.git
    cd FirMcp
else
    echo "儲存庫不存在，建立新儲存庫"
    
    # 選項1: 使用 GitHub CLI 自動建立儲存庫 (需要先安裝 gh CLI 並登入)
    # gh repo create Po-Yu-Chang/FirMcp --public
    
    # 選項2: 手動在 GitHub 上建立儲存庫後繼續
    echo "請先在 GitHub 上手動建立儲存庫，然後按任意鍵繼續"
    read -n 1
    
    # 在本地初始化 Git 函式庫
    git init
    
    # 添加所有檔案到暫存區
    git add .
    
    # 進行第一次提交
    git commit -m "初始化提交"
    
    # 連接到你的遠端儲存庫
    git remote add origin https://github.com/Po-Yu-Chang/FirMcp.git
    
    # 推送資料到 GitHub (會提示輸入使用者名稱和密碼或個人存取權杖)
    git push -u origin main
fi

echo "設定完成！"