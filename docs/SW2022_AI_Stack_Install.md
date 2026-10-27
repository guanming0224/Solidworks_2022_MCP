# SolidWorks 2022 AI 建模工具鏈：安裝地圖（給 Claude Code 執行）

> 給 Claude Code 的指示：請依本文件「由上往下」逐階段執行。每一階段結束都要跑「驗收」，通過才進下一階段；任何一步失敗就停下來回報錯誤訊息，不要自行跳過或改用其他 MCP。
>
> 作業環境：Windows 10/11 + SolidWorks 2022 + PowerShell。
> 依據版本：各 repo README，於 2026-10-07 查證。

---

## 0. 架構地圖

```text
                       Claude Code
                            │
                            ▼
        ┌────────────────────────────────────┐
        │ 1. sw-designer        怎麼設計     │  Skill（delancy827）
        └─────────────────┬──────────────────┘
                          ▼
        ┌────────────────────────────────────┐
        │ 2. SW2022 VBA Skill   API 怎麼做   │  Skill（隨 ladla90077）
        └─────────────────┬──────────────────┘
                          ▼
        ┌────────────────────────────────────┐
        │ 3. ladla90077 MCP     唯一執行核心 │  MCP server
        └─────────────────┬──────────────────┘
                          ▼
                  SolidWorks 2022（COM）
                          │
                          ▼
        ┌────────────────────────────────────┐
        │ 4. sw-verification    證明做對     │  自建 Skill
        └─────────────────┬──────────────────┘
               不通過 ←───┘ 回到第 3 步重做
                          ▼
        ┌────────────────────────────────────┐
        │ 5. sw-manufacturing   證明做得出來 │  自建 Skill
        └─────────────────┬──────────────────┘
                          ▼
         SLDPRT / SLDASM / SLDDRW → STEP / DXF / PDF / BOM
```

### 安裝清單

| 階段 | 元件 | 類型 | 來源 | 第一輪是否安裝 |
| --- | --- | --- | --- | --- |
| A | 環境檢查 | — | 本機 | 是 |
| B | ladla90077 SW2022 MCP | MCP | https://github.com/ladla90077-web/solidworks-mcp | 是 |
| C | sw-designer | Skill | https://github.com/delancy827/solidworks-skills | 是 |
| D | sw-verification | Skill（自建） | 本文件第 D 節 | 是 |
| E | sw-manufacturing | Skill（自建骨架） | 本文件第 E 節 | 是（先放骨架） |
| F | 第一階段驗收：底板 | 測試 | 本文件第 F 節 | 是 |
| G | kbedrich/solidworks-agent | 備案外掛 | https://github.com/kbedrich/solidworks-agent | **否**，F 通過後另行評估 |

### 絕對規則

1. **只能有一個 MCP 控制 SolidWorks。** 不要安裝或啟用 aryesil、alisamsam、hjbaard、Sam-Of-The-Arth、haunchen 的 MCP。
2. **不要安裝 delancy827 的 `solidworks-automation` 與 `solidworks-mcp` 資料夾。** 它們以 SW2024 API 為準，參數數量與 2022 不同。只取 `sw-designer`。
3. **API 一律以 SW2022 為準。** 不確定時用 ladla90077 的 `sw_docs_lookup_method` / `sw_docs_lookup_enum` 查，不要猜。
4. **沒有數字證據不得回報「完成」。** 每次建模都要走 sw-verification。
5. 安裝前先列出要執行的指令，等使用者同意再執行。

---

## A. 環境檢查

依序執行，把每項結果列成表格回報：

```powershell
# 1. Python 版本（需 3.10+）
python --version

# 2. Git
git --version

# 3. SolidWorks 是否在執行
Get-Process SLDWORKS -ErrorAction SilentlyContinue | Select-Object Id, ProcessName, Path

# 4. SolidWorks 的 COM 註冊（ProgID）
Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\SldWorks.Application\CurVer" -ErrorAction SilentlyContinue

# 5. Claude Code 版本
claude --version
```

### 手動確認（請使用者在 SolidWorks 內操作）

- [ ] SolidWorks 2022 已啟動，並保持開啟。
- [ ] 「工具 → 選項 → 系統選項 → 預設範本」已設定零件、組合件、工程圖範本。未設定時 ladla90077 的巨集會中止。
- [ ] 回報 SolidWorks 2022 的 Service Pack 版本（說明 → 關於 SOLIDWORKS）。

### 驗收 A

- Python ≥ 3.10、Git 可用、`SLDWORKS` 程序存在、`SldWorks.Application` 有註冊。
- 任一項失敗就停止，回報缺什麼。

---

## B. 安裝 ladla90077 SW2022 MCP（唯一執行核心）

### B1. 下載與安裝

```powershell
# 工作目錄（可依使用者偏好調整）
New-Item -ItemType Directory -Force -Path C:\sw-ai | Out-Null
Set-Location C:\sw-ai

git clone https://github.com/ladla90077-web/solidworks-mcp.git
Set-Location C:\sw-ai\solidworks-mcp

# 建議使用 venv，避免污染系統 Python
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -e .

# API 文件管線需要（一次性）
.\.venv\Scripts\python.exe -m playwright install chromium
```

### B2. 註冊到 Claude Code（user scope）

```powershell
claude mcp add solidworks -s user -- C:\sw-ai\solidworks-mcp\.venv\Scripts\python.exe -m sw_mcp.server
claude mcp list
```

`claude mcp list` 應顯示 `solidworks: ... ✓ Connected`。

### B3. 檢查內建 Skill

ladla90077 說明要搭配 `solidworks-vba` Skill，並內建 12 個 Cosmon Skill。請確認：

```powershell
Get-ChildItem -Recurse C:\sw-ai\solidworks-mcp -Filter SKILL.md | Select-Object FullName
```

- 若找到 `solidworks-vba` 的 SKILL.md：複製到 `%USERPROFILE%\.claude\skills\solidworks-vba\`。
- 若沒找到：重啟 Claude Code 後呼叫 MCP 工具 `sw_list_skills`，確認它是否由伺服器提供。
- 兩者都沒有：回報使用者，**不要自行從其他 repo 找替代品**。

### 驗收 B

在 SolidWorks 開著的情況下，依序呼叫 MCP 工具：

1. `sw_status`：回報 SolidWorks 版本，必須是 2022。
2. `sw_prepare_modeling_context("test plate")`：能選到唯一的 SolidWorks session。
3. `sw_docs_lookup_method("IFeatureManager", "FeatureExtrusion2")`：能回傳 SW2022 的參數說明。

三項都成功才算通過。

---

## C. 安裝 sw-designer（設計決策）

```powershell
Set-Location C:\sw-ai
git clone https://github.com/delancy827/solidworks-skills.git

New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\skills" | Out-Null
Copy-Item -Recurse -Force C:\sw-ai\solidworks-skills\sw-designer "$env:USERPROFILE\.claude\skills\sw-designer"
```

**只複製 `sw-designer`。** 不要複製 `solidworks-automation`、`solidworks-mcp`。

### C1. 加上 2022 版本警語

在 `%USERPROFILE%\.claude\skills\sw-designer\SKILL.md` 的 frontmatter 之後、正文最前面插入：

```markdown
> **SW2022 環境警語**：本 Skill 只用於設計決策（特徵順序、壁厚、圓角、裝配思路、設計審查）。
> 本文件中的 API 呼叫範例以 SolidWorks 2024 為準，**不得直接用於 SW2022**。
> 實際 API 一律依 solidworks-vba Skill 與 ladla90077 MCP 的 `sw_docs_lookup_method` 查詢結果。
```

### 驗收 C

- `%USERPROFILE%\.claude\skills\sw-designer\SKILL.md` 存在，且開頭有上述警語。
- 重啟 Claude Code 後，Skill 清單中出現 `sw-designer`。

---

## D. 建立 sw-verification（驗證層）

建立 `%USERPROFILE%\.claude\skills\sw-verification\SKILL.md`，內容如下：

````markdown
---
name: sw-verification
description: 每次用 SolidWorks 建立或修改零件、組合件、工程圖後必須使用。以數字證據判定 PASS/FAIL，沒有證據不得回報完成。
---

# SolidWorks 驗證層（Evidence Gate）

## 規則
- 沒有數字證據，不得說「完成」。
- 任一項 FAIL：回到 ladla90077 MCP 修正後重跑全部檢查。
- 同一錯誤連續修正 3 次仍失敗：停止，回報使用者。

## 檢查清單

| 階段 | 檢查 | 通過條件 | 工具 |
| --- | --- | --- | --- |
| 重建 | Rebuild 錯誤、錯誤特徵 | 0 錯誤、0 被抑制特徵 | sw_run_and_verify / sw_get_build_errors |
| 幾何 | 實體數量 | 等於預期值 | sw_get_feature_tree 或 sw_run_vba（GetBodies2） |
| 幾何 | 包絡盒 | 每軸誤差 ≤ ±0.1 mm | sw_get_bounding_box |
| 幾何 | 體積／質量 | 與手算值誤差 ≤ 0.5% | sw_get_mass_properties |
| 組合件 | 配合 | 無配合錯誤、無過定義 | sw_get_feature_tree |
| 組合件 | 干涉 | 干涉體積 = 0（刻意干涉除外） | sw_run_vba（干涉檢查巨集） |
| 檔案 | 儲存後重開 | 重開後重建與尺寸檢查仍通過 | sw_save_model → sw_close_model → sw_open_model |
| 檔案 | 輸出 | STEP/DXF/PDF 存在，記錄檔案大小與 SHA-256 | sw_export_file + PowerShell Get-FileHash |
| 目視 | 截圖 | 截圖給使用者確認設計意圖 | sw_capture_screenshot |

## 回報格式

```text
File:            <檔名>
Rebuild Error:   0
Feature Error:   0
Body Count:      <實際> / <預期>
Bounding Box:    <X> × <Y> × <Z> mm（預期 <...>）
Volume:          <實際> mm³（手算 <...>，誤差 <...>%）
Mate Error:      <組合件才填>
Interference:    <組合件才填>
Reopen Check:    PASS / FAIL
Exports:         <檔名 + SHA-256 前 12 碼>
Status:          PASS / FAIL
```

容差為起點值，依零件精度需求可由使用者調整。
````

### 驗收 D

- 檔案存在；重啟 Claude Code 後 Skill 清單出現 `sw-verification`。

---

## E. 建立 sw-manufacturing（製造層骨架）

建立 `%USERPROFILE%\.claude\skills\sw-manufacturing\SKILL.md`：

````markdown
---
name: sw-manufacturing
description: 設計機械零件、鈑金、焊接件、組合件時使用。建模前做 DFM 檢查，建模後做最終製造檢查並輸出 BOM、STEP、DXF、PDF。
---

# 製造可行性（DFM）與輸出

## 使用時機
1. **建模前**：sw-designer 決定結構時，先檢查是否做得出來。
2. **建模後**：通過 sw-verification 之後，做最終檢查並輸出加工檔。

## 檢查項目（數值待使用者依合作加工廠規格補齊）

| 類別 | 要確認的內容 | 規格值 |
| --- | --- | --- |
| 鈑金 | 常用板厚、最小折彎半徑、K-factor、折彎離孔距離 | 待補 |
| 雷切／加工 | 最小孔徑對板厚比、孔邊距、槽寬、公差等級 | 待補 |
| 標準件 | 螺絲通孔／牙孔／沉頭孔對照、軸承座、皮帶輪、鏈輪 | 待補 |
| 結構 | 方管、角鐵規格；Weldment 輪廓；焊接符號 | 待補 |
| 材料 | SS400、SUS304、AL6061 等用途 | 待補 |
| 表面處理 | 烤漆、電鍍、陽極處理 | 待補 |

規格值為「待補」時：用常見工程值提出建議，並明確標示「建議值，需使用者確認」。

## 輸出規則
- 零件：STEP；鈑金零件另出展開 DXF。
- 工程圖：PDF。
- 組合件：BOM（欄位：項次、件號、名稱、材料、數量、加工方式、備註）。
- 檔名：`<專案>_<模組>_<零件>_<版次>`，例如 `RCY_CONV_FRAME_R01.STEP`。
````

### 驗收 E

- 檔案存在；Skill 清單出現 `sw-manufacturing`。
- 回報使用者：規格表需要依加工廠實際規格補齊。

---

## F. 第一階段驗收：底板

所有 Skill 和 MCP 安裝後，**重啟 Claude Code**，然後執行以下任務：

> 建立一個 100 × 80 × 10 mm 的底板，四角各一個 M6 通孔（Ø6.6 mm，孔中心距邊 10 mm），四個垂直邊角 R5 圓角。存成 `C:\sw-ai\test\Plate_100x80.SLDPRT`，匯出 STEP。

執行流程：

1. **sw-designer**：說明特徵順序（草圖 → 拉伸 → 孔 → 圓角）與理由。
2. **solidworks-vba**：產生 SW2022 VBA。
3. **ladla90077 MCP**：`sw_run_and_verify` 執行；失敗就依錯誤修正再跑。
4. **sw-verification**：用固定格式回報。預期值：
   - Body Count = 1
   - Bounding Box = 100 × 80 × 10 mm（±0.1）
   - 體積手算：100 × 80 × 10 − 4 × π × 3.3² × 10 − 4 × (5² − π × 5² / 4) × 10 ≈ 78,416 mm³
   - 儲存 → 關閉 → 重開後再驗一次
5. **sw-manufacturing**：匯出 STEP，記錄 SHA-256。

### 通過條件

全部 PASS，Rebuild Error = 0，重開後仍 PASS。

**通過之後**再依序推進：支架 → 鈑金 → Weldment → 組合件 → 輸送帶模組 → 整台回收機。

---

## G. 備案：kbedrich/solidworks-agent（第一輪不要安裝）

只有在 F 通過之後，且 ladla90077 遇到做不到的功能（例如組合件配合、干涉、工程圖）時，才由使用者決定是否評估。

評估方式：

1. 先在 Claude Code 中移除或停用 `solidworks` MCP（`claude mcp remove solidworks -s user`），**確保同時只有一個執行層**。
2. 安裝：

```powershell
claude plugin marketplace add kbedrich/solidworks-agent
claude plugin install solidworks@solidworks-agent
```

3. 關閉 SolidWorks 內所有文件，依它的 `skills/solidworks/qualification/README.md` 跑實機驗證套件。
4. 回報哪些階段在 SW2022 通過、哪些失敗。它在 SW2025 型別庫上驗證，2022 未經測試；Hole Wizard 與肋特徵未實作。

---

## 完成後回報給使用者

用表格回報各階段（A–F）狀態：PASS / FAIL / 跳過，以及：

- SolidWorks 2022 Service Pack 版本
- `solidworks-vba` Skill 實際來源（B3 的結果）
- 底板驗收的完整 Verification 回報
- 遇到的錯誤與處理方式
