SolidWorks 2022 MCP 安裝包
============================
讓 Claude Code 直接操作你電腦上開著的 SolidWorks 2022：建立零件、量測、匯出 STEP 等。
所有工具名稱都以 sw_ 開頭（例如 sw_status、sw_create_extrusion、sw_export_file）。


一、安裝前先確認（缺一不可）
--------------------------------
1. Windows 10/11
2. 已安裝 SolidWorks 2022
3. 已安裝 Python 3.10 以上（python.org 下載，安裝時勾選 Add Python to PATH）
4. 已安裝 Claude Code
5. 電腦可以上網（安裝時要下載套件）


二、安裝（約 5 到 10 分鐘）
--------------------------------
1. 把整個資料夾複製到電腦上，放在「路徑短」的位置，例如：
       C:\SolidWorks_MCP
   路徑建議在 40 個字元以內，太長會讓部分檔案無法建立。
2. 最簡單：在檔案總管雙擊資料夾裡的 install.bat（會自動執行 setup.ps1，結束時顯示成功或失敗）。
   或開啟 PowerShell，進入該資料夾，執行：
       .\setup.ps1
   如果出現「無法載入，因為這個系統已停用指令碼執行」，改用 install.bat，或：
       powershell -ExecutionPolicy Bypass -File .\setup.ps1
3. 看到下面兩行就代表成功：
       import OK
       Install complete.
   過程中出現黃色的 WARNING: Retrying 可以忽略，只要最後有 import OK 就是成功。

安裝後，這個資料夾本身就是專案資料夾，會多出：
   runtime\            MCP 本體與 Python 環境（不要手動搬動或複製到別台電腦）
   .mcp.json           讓 Claude Code 找到 MCP
   .claude\skills\     3 個 skill
   CLAUDE.md           給 Claude 的工作規則


三、第一次使用
--------------------------------
1. 開啟 SolidWorks 2022。
2. 在這個資料夾啟動 Claude Code（PowerShell 進入資料夾後輸入 claude）。
3. 第一次啟動時，核准 .mcp.json 裡的 solidworks MCP。
4. 對 Claude 說：「執行 sw_status」，回傳 year 為 2022、connected 為 true 就代表連上了。
5. 之後直接用自然語言描述零件即可，例如：
       建立一個 40 x 30 x 10 mm 的方塊，並匯出 STEP。

重要：每次都要在「這個資料夾」啟動 Claude Code，MCP 才會載入。


四、輸出檔案放在哪裡
--------------------------------
匯出（STEP、PDF 等）、另存新檔、截圖，一律存到：
       桌面\Solidworks_MCP_output
資料夾不存在會自動建立。即使指定了別的路徑，也只會保留檔名並存到這裡。
同名檔案會被覆蓋。


五、已驗證與未驗證
--------------------------------
已驗證：
- 連上 SolidWorks 2022（sw_status）
- 建立簡單零件（方塊）、量測體積與尺寸、匯出 STEP
- 在 Windows PowerShell 5.1 下，不帶參數執行 setup.ps1 可完整安裝

未充分驗證（請自行檢查結果，不要直接拿去加工）：
- 複雜零件、鈑金、焊接件
- 組合件（內建的組合件配合測試目前會失敗）
- 設計尺寸與公差是否合理，需由人判斷


六、常見問題
--------------------------------
Q: 找不到 Python
A: 安裝 Python 3.10 以上，並勾選 Add Python to PATH，然後重開 PowerShell 再執行。

Q: 安裝中途失敗，或網路不穩
A: 重新執行 .\setup.ps1 即可，已完成的部分會重用。

Q: sw_status 說找不到 SolidWorks
A: 先開啟 SolidWorks 2022，等它完全開好再試。

Q: Claude Code 裡看不到 solidworks 的工具
A: 確認是在安裝的那個資料夾啟動 Claude Code，並已核准 .mcp.json。

Q: 安裝時出現 mcp 版本相關錯誤
A: 不要升級 mcp。requirements-lock.txt 釘在 mcp==1.30.0，2.x 會匯入失敗。


七、移除
--------------------------------
    雙擊 uninstall.bat，或在 PowerShell 執行 .\uninstall.ps1
會先列出要刪除的項目，輸入 YES 才會執行（加 -Force 可略過確認）。
不會動 Python 與 SolidWorks。桌面的 Solidworks_MCP_output 不會被刪。


八、資料夾內容
--------------------------------
    install.bat             雙擊安裝（呼叫 setup.ps1）
    setup.ps1               安裝腳本
    uninstall.bat           雙擊移除（呼叫 uninstall.ps1）
    uninstall.ps1           移除腳本
    requirements-lock.txt   釘住的套件版本
    solidworks-mcp\         MCP 原始碼與 API 文件庫
    skills\                 sw-designer / sw-verification / sw-manufacturing
    docs\                   CLAUDE.md、SW2022_AI_Stack_Install.md
    test\                   驗收用的 SLDPRT / STEP 範例檔
