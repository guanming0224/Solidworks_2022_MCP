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
