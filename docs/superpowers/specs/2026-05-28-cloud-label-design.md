# 標籤生產系統雲端化設計 spec

**日期:** 2026-05-28  
**專案:** QLOOP 染整印標籤 — 地端 → 雲端遷移  

---

## 背景與目標

現有工具為單一 HTML 檔案，規格表透過上傳 Excel 載入、掃描結果只輸出到本地。跨部門需要拿到對照表時必須另外傳檔案，流程不順。

**目標：**
- HTML 掛在 GitHub Pages，有網址即可使用，不需找本地檔案
- 規格表統一存在 Google Sheets，改版即時生效
- 每次產出自動同步對照表到 Google Sheets，跨部門直接查看

---

## 架構總覽

```
[瀏覽器 — GitHub Pages]
    │
    ├─ 開啟時 GET ──────→ [GAS Web App]
    │                          │
    │   ←── 規格 JSON ─────────┤ doGet() 讀 Google Sheets 規格表 Tab
    │
    │  [使用者掃描 K-Code、生成標籤預覽]
    │
    ├─ 產出按鈕
    │   ├─ 本地下載 PDF（60 張）         ← 不變
    │   ├─ 本地下載 Excel（30 列）        ← 不變
    │   └─ POST (no-cors) ────→ [GAS Web App]
    │                                │
    │                                └─ doPost() append → 對照表 Tab
```

---

## Google Sheets 結構

**單一 Sheets 檔案，兩個 Tab。**

### Tab 1：規格表

| 欄位 | 說明 |
|------|------|
| SpecName | 規格名稱，作為下拉選單選項 |
| LayoutJSON | 標籤版面配置 JSON |
| Row1_Text | 標籤文字第 1 行 |
| Row2_Text | 標籤文字第 2 行 |
| Row3_Text | 標籤文字第 3 行 |
| Row4_Text | 標籤文字第 4 行 |

### Tab 2：對照表

| 欄位 | 說明 |
|------|------|
| 序號 | 掃描順序 01–30 |
| 規格 | 當次選用的規格名稱 |
| 原始條碼 (A) | K-Code 第一段（分號前） |
| 新條碼 (B) | 系統產生的 B 碼 |
| 生產日期 | YYYY-MM-DD |
| 回數 | 1–10 |
| 寫入時間 | GAS append 當下的時間戳記 |

---

## GAS Web App

部署設定：**Execute as: Me / Anyone can access (even anonymous)**

### doGet()
- 讀取「規格表」Tab 全部資料
- 回傳格式：JSON array，每個物件對應一列規格
- 前端用 `fetch(GAS_URL)` 正常呼叫（GET 無 CORS 問題）

### doPost()
- 接收 `e.postData.contents`（JSON 字串，scannedData 陣列）
- 解析後逐筆 `appendRow` 到「對照表」Tab
- 附加欄位：`new Date()`（寫入時間）
- 前端用 `fetch(GAS_URL, { method: 'POST', mode: 'no-cors', body: JSON.stringify(data) })`

---

## HTML 修改項目

### 移除
- 「匯入規格 / Nhập Excel」上傳框（`<input type="file">`）
- `handleExcel()` 函式
- `loadSavedData()` 從 localStorage 讀規格的邏輯

### 新增
- 頁面頂部加一個 `GAS_URL` 常數（部署後填入）
- `loadSpecsFromGAS()` — 頁面載入時 fetch GAS，成功後呼叫 `updateSpecSelector()`
- 載入中狀態提示（「載入規格中…」）
- 載入失敗提示（「規格載入失敗，請檢查網路」）

### 修改
- `window.onload`：改呼叫 `loadSpecsFromGAS()` 取代原本的 `loadSavedData()`
- `startExportProcess()`：PDF + Excel 下載完成後，加一次 `postToGAS(scannedData)` fire-and-forget

### 掃描驗證（新增）
在現有驗證之後加入格式檢查：
```
const firstA = rawA.split(';')[0];
if (!firstA.startsWith('K')) {
    alert("⚠️ 格式不對，請確認掃到 K-Code");
    e.target.value = '';
    return;
}
```

---

## CORS 處理策略

| 方向 | 方法 | 說明 |
|------|------|------|
| 讀規格（GET） | 正常 `fetch(url)` | GAS GET 回應允許跨域，無需特殊處理 |
| 寫對照表（POST） | `fetch(url, { mode: 'no-cors', body: JSON.stringify(data) })` | 跳過 preflight，GAS 照收，前端看不到回應（fire-and-forget） |

POST 寫入結果不在前端顯示，使用者從 Google Sheets 確認資料是否寫入。

---

## 部署步驟（實作完成後）

1. 建立 Google Sheets，建好兩個 Tab 並填入規格資料
2. 建立 GAS 專案，貼上 doGet / doPost 程式碼，部署為 Web App，取得 URL
3. 將 GAS_URL 填入 HTML
4. 推上 GitHub，開啟 GitHub Pages
5. 測試：開啟 GitHub Pages URL → 規格應自動載入 → 掃描 → 產出 → 確認 Sheets 對照表有新增資料

---

## 不在本次範圍內

- 使用者登入 / 權限控制
- 對照表查詢介面
- 寫入失敗的重試機制
- 多語言支援調整
