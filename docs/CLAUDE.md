# SWxRACE：SolidWorks 2022 AI 建模專案

## 專案目的
用 Claude Code 搭配 MCP 與 Skill 控制 SolidWorks 2022 建模、驗證並輸出加工檔。

## 必讀文件
- `SW2022_AI_Stack_Install.md`：安裝與驗收的唯一依據。依 A → F 階段由上往下執行，每階段驗收通過才進下一階段。失敗就停下來回報，不要自行跳過或改用其他 MCP。

## 目錄與安裝位置
| 項目 | 位置 |
| --- | --- |
| 專案層級 Skill | `.claude/skills/`（sw-designer、sw-verification、sw-manufacturing；`solidworks-vba` 無來源，未安裝） |
| MCP 程式碼與 venv | `C:\sw-ai\solidworks-mcp` |
| 輸出檔案（匯出、另存、截圖） | `%USERPROFILE%\Desktop\Solidworks_MCP_output\`（MCP 強制，只保留檔名） |

安裝文件中原本寫 `%USERPROFILE%\.claude\skills\` 的地方，一律改裝到本專案的 `.claude/skills/`。

## 環境
- Windows 11、SolidWorks 2022、PowerShell
- 必須在本資料夾啟動 Claude Code，專案層級 Skill 才會載入

## 絕對規則
1. 只能有一個 MCP 控制 SolidWorks：`solidworks`（ladla90077）。不要安裝或啟用其他 SolidWorks MCP。
2. 只取 delancy827 的 `sw-designer`，不要安裝它的 `solidworks-automation` 與 `solidworks-mcp`（以 SW2024 API 為準，與 2022 不符）。
3. API 一律以 SW2022 為準。不確定時用 MCP 的 `sw_docs_lookup_method` / `sw_docs_lookup_enum` 查，不要猜。
4. 沒有數字證據不得回報完成；每次建模都要走 `sw-verification`。
5. 安裝或執行指令前先列出，等使用者同意再執行。
6. 不要自行從其他 repo 找替代 Skill 或 MCP。

## 工作流程
sw-designer（設計決策）→ MCP `docs_lookup_*` + `sw_validate_vba`（SW2022 API，取代缺少的 solidworks-vba）→ solidworks MCP（執行）→ sw-verification（驗證，不通過回到執行）→ sw-manufacturing（DFM 與輸出）

## 安裝注意事項
- MCP 以 `-s project` 註冊，設定在本資料夾的 `.mcp.json`；首次啟動 Claude Code 需核准。
- 系統層級 `C:\ProgramData\pip\pip.ini` 含無法解析的 `pypi.ngc.nvidia.com` 額外索引，pip 會卡住。在 venv 內安裝時，用 `PIP_CONFIG_FILE` 指向空檔案繞過，不要改動該系統檔。
- venv 內 `mcp` 必須釘在 `<2`（目前 1.30.0）。repo 只寫 `mcp[cli]>=1.2.0`，pip 預設會裝 2.x，導致 `mcp.server.fastmcp` 匯入失敗。

## 目前進度
- A：PASS（SolidWorks 2022 SP3.1，檔案版本 30.3.1.0002）
- B1、B2：完成；B3：`solidworks-vba` 不在 repo 內，MCP `sw_list_skills` 也只有 12 個 bundled Skill，缺口已獲使用者同意，暫以 MCP `docs_lookup_*` 與 `sw_validate_vba` 取代。
- B 驗收：PASS（`sw_status` 2022、`sw_prepare_modeling_context` 單一 session、`sw_docs_lookup_method` 回傳 SW2022 簽章）。B3 缺 solidworks-vba。
- C：PASS（`sw-designer` 已裝入 `.claude/skills/` 並加 SW2022 警語，Skill 清單可見）
- D：檔案已建立於 `.claude/skills/sw-verification/SKILL.md`，Skill 清單可見
- E：檔案已建立於 `.claude/skills/sw-manufacturing/SKILL.md`（規格值皆「待補」，需依加工廠補齊）；待重啟確認 Skill 清單出現。`sw-designer` 警語已改為指向 `docs_lookup_*` + `sw_validate_vba`，並註明不得切換到 `solidworks-automation`
- F（底板驗收）：PASS。`C:\sw-ai\test\Plate_100x80.SLDPRT`，Body Count 1、體積 78,416.9 mm³、Bounding Box 100 × 10 × 80 mm、Rebuild Error 0，重開後仍 PASS；STEP 已匯出（SHA-256 `A3FB3800B4254599777BEF9DB471B9AD8E20652DC851FE37BDF972BED6996993`）。階段 G（kbedrich/solidworks-agent）第一輪不安裝。
- 支架（L 型，60 × 40 × 40 mm）：PASS。`C:\sw-ai\test\Bracket_L_60x40.SLDPRT`，Body Count 1、體積 26,024.93 mm³（手算 26,024.9）、Rebuild Error 0，重開後仍 PASS；STEP 已匯出（SHA-256 `1CC44B18C16FFE1C0A013EF26BA4783C388C70DCFC66A355B192EC61CCF967A9`）。下一步：鈑金。
- `FeatureCut4`：`Flip` 是切輪廓外側，反向用 `Dir`；方向錯時 `sw_run_and_verify` 仍回報 success、特徵不產生，必須用體積核對。
