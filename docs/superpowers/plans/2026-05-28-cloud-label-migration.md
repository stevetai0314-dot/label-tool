# 標籤系統雲端化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 將本地 HTML 標籤工具遷移至 GitHub Pages，規格表改由 Google Sheets 提供，掃描結果同時輸出本地與 Google Sheets。

**Architecture:** HTML 靜態部署於 GitHub Pages，透過 GAS Web App 作為 Sheets 的讀寫介面。規格表在頁面載入時 GET 取得，掃描完成產出時以 no-cors POST 寫入對照表，本地 PDF / Excel 下載行為不變。

**Tech Stack:** 純 HTML/JS、Google Apps Script、Google Sheets、GitHub Pages。無 npm、無 build step。

---

## 檔案結構

| 動作 | 路徑 | 說明 |
|------|------|------|
| 建立 | `Code.gs` | GAS 腳本（本地存檔備查，實際貼到 GAS 編輯器） |
| 重新命名 + 修改 | `index.html`（原 `0403-QLOOP-穩定 1按鈕PDFx2+EXCEL.html`） | 主工具頁面 |

---

## Task 1：建立 Google Sheets 結構

**目標：** 建好兩個 Tab 和正確欄位，後續 GAS 才能讀寫。

**Files:**
- 無本地檔案，全部在 Google Sheets 操作

- [ ] **Step 1: 建立 Google Sheets 檔案**

  前往 https://sheets.google.com → 建立空白試算表 → 命名為「標籤系統」。

- [ ] **Step 2: 建立「規格表」Tab**

  將預設的 Sheet1 重新命名為 `規格表`，在第 1 列填入以下標題（每格一欄）：

  ```
  A1: SpecName
  B1: LayoutJSON
  C1: Row1_Text
  D1: Row2_Text
  E1: Row3_Text
  F1: Row4_Text
  ```

- [ ] **Step 3: 填入現有規格資料**

  將原本 `Specs.xlsx` 的每一列規格，照相同欄位順序複製貼上到「規格表」Tab。
  LayoutJSON 欄位貼上原始 JSON 字串即可，Sheets 不會解析它。

- [ ] **Step 4: 建立「對照表」Tab**

  點擊底部 `+` 新增 Tab，命名為 `對照表`，在第 1 列填入：

  ```
  A1: 序號
  B1: 規格
  C1: 原始條碼 (A)
  D1: 新條碼 (B)
  E1: 生產日期
  F1: 回數
  G1: 寫入時間
  ```

- [ ] **Step 5: 複製 Sheets ID**

  從瀏覽器網址列取得 Sheets ID，格式如下，複製 `{ID}` 部分備用：
  ```
  https://docs.google.com/spreadsheets/d/{ID}/edit
  ```

---

## Task 2：建立並部署 GAS Web App

**目標：** 建立 doGet（讀規格）和 doPost（寫對照表）兩個端點，取得部署 URL。

**Files:**
- 建立：`Code.gs`（本地備查用，實際在 GAS 編輯器操作）

- [ ] **Step 1: 建立本地備查檔**

  建立 `Code.gs`，內容如下：

  ```javascript
  const SHEET_ID = 'PASTE_YOUR_SHEET_ID_HERE';
  const SPEC_TAB = '規格表';
  const LOG_TAB = '對照表';

  function doGet(e) {
    const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SPEC_TAB);
    const data = sheet.getDataRange().getValues();
    const headers = data[0];
    const rows = data.slice(1)
      .filter(row => row[0])
      .map(row => {
        const obj = {};
        headers.forEach((h, i) => { obj[h] = row[i]; });
        return obj;
      });
    return ContentService
      .createTextOutput(JSON.stringify(rows))
      .setMimeType(ContentService.MimeType.JSON);
  }

  function doPost(e) {
    const items = JSON.parse(e.postData.contents);
    const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(LOG_TAB);
    items.forEach(item => {
      sheet.appendRow([
        item.seq,
        item.specName,
        item.firstA,
        item.codeB,
        item.date,
        item.hui,
        new Date()
      ]);
    });
    return ContentService.createTextOutput('OK');
  }
  ```

- [ ] **Step 2: 前往 GAS 編輯器**

  開啟 Google Sheets → 上方選單「擴充功能」→「Apps Script」。

- [ ] **Step 3: 貼上程式碼**

  將 `Code.gs` 全部內容貼到 GAS 編輯器，把第 1 行的 `PASTE_YOUR_SHEET_ID_HERE` 換成 Task 1 Step 5 複製的 Sheets ID。儲存（Ctrl+S）。

- [ ] **Step 4: 部署為 Web App**

  右上角「部署」→「新增部署作業」→ 類型選「網頁應用程式」：
  - 執行身分：**我（自己的帳號）**
  - 存取權：**所有人**

  點「部署」→ 複製產生的 **Web App URL** 備用（格式：`https://script.google.com/macros/s/.../exec`）。

- [ ] **Step 5: 驗證 doGet**

  在瀏覽器直接開啟 Web App URL，應看到規格表的 JSON 陣列回應，例如：
  ```json
  [{"SpecName":"K100-白","LayoutJSON":"{...}","Row1_Text":"..."}]
  ```
  如果回傳空陣列 `[]` 表示 Sheets 沒有資料列，回去檢查 Task 1 Step 3。

---

## Task 3：HTML — 移除 Excel 上傳，加入 GAS 規格載入

**目標：** 拿掉 Excel 上傳框，頁面載入時自動從 GAS 讀取規格。

**Files:**
- 重新命名：`0403-QLOOP-穩定 1按鈕PDFx2+EXCEL.html` → `index.html`
- 修改：`index.html`

- [ ] **Step 1: 重新命名檔案**

  將 `0403-QLOOP-穩定 1按鈕PDFx2+EXCEL.html` 改名為 `index.html`。

- [ ] **Step 2: 在 `<script>` 最頂部加入 GAS_URL 常數**

  找到 `<script>` 標籤後第一行的 `const { jsPDF } = window.jspdf;`，在它**上方**插入：

  ```javascript
  const GAS_URL = 'PASTE_YOUR_WEB_APP_URL_HERE'; // Task 2 Step 4 的 URL
  ```

- [ ] **Step 3: 移除 setup-zone 裡的 Excel 上傳欄位**

  找到並刪除這整個 div：
  ```html
  <div class="config-item"><label>匯入規格 / Nhập Excel</label><input type="file" id="excelUpload" accept=".xlsx" onchange="handleExcel(this)"></div>
  ```

- [ ] **Step 4: 更新 setup-zone 的欄位數**

  找到 `.setup-zone` 的 CSS：
  ```css
  grid-template-columns: 1.5fr 1.5fr 2.5fr 0.8fr;
  ```
  改為三欄（因為 Excel 上傳欄位已移除）：
  ```css
  grid-template-columns: 2fr 3fr 1fr;
  ```

- [ ] **Step 5: 加入 `loadSpecsFromGAS()` 函式**

  在 `handleExcel` 函式前面插入新函式：

  ```javascript
  async function loadSpecsFromGAS() {
    document.getElementById('status').innerText = '規格載入中 / Đang tải...';
    try {
      const res = await fetch(GAS_URL);
      const arr = await res.json();
      specsData = {};
      arr.forEach(row => { specsData[row.SpecName] = row; });
      updateSpecSelector();
    } catch (err) {
      document.getElementById('status').innerText = '⚠️ 規格載入失敗，請檢查網路';
    }
  }
  ```

- [ ] **Step 6: 移除 `handleExcel()` 和 `loadSavedData()` 函式**

  找到並刪除這兩個完整的函式（從 `function handleExcel` 到其結尾的 `}`，以及從 `function loadSavedData` 到其結尾的 `}`）。

  注意：`localStorage.setItem` 在 `handleExcel` 裡，連同整個函式一起刪掉即可，`updateSpecSelector()` 不需要另外修改。

- [ ] **Step 7: 更新 `window.onload`**

  找到：
  ```javascript
  window.onload = () => { initTime(); loadSavedData(); };
  ```
  改為：
  ```javascript
  window.onload = () => { initTime(); loadSpecsFromGAS(); };
  ```

- [ ] **Step 8: 在瀏覽器開啟 index.html 測試**

  直接用瀏覽器開啟本地 `index.html`（file:// 或 Live Server 均可）。  
  預期行為：
  - 頁面載入時 status 顯示「規格載入中」
  - 約 1-2 秒後下拉選單出現規格項目
  - 若 GAS_URL 填錯，status 顯示「⚠️ 規格載入失敗」

- [ ] **Step 9: Commit**

  ```bash
  git add index.html Code.gs
  git commit -m "feat: load specs from GAS, remove Excel upload"
  ```

---

## Task 4：HTML — 加入 K-Code 格式驗證

**目標：** 掃到不是 K 開頭的條碼時擋住並提示，防止掃錯種。

**Files:**
- 修改：`index.html`

- [ ] **Step 1: 在 scanner 事件裡加入 K 前綴驗證**

  找到掃描器事件裡的重複碼檢查：
  ```javascript
  const firstA = rawA.split(';')[0];
  if (scannedData.some(i => i.firstA === firstA)) { alert("重複！"); e.target.value = ''; return; }
  ```
  在 `const firstA = ...` 這行**後面**、重複碼檢查**前面**，插入：

  ```javascript
  if (!firstA.startsWith('K')) {
    alert('⚠️ 格式不對，請確認掃到 K-Code');
    e.target.value = '';
    return;
  }
  ```

- [ ] **Step 2: 在瀏覽器測試驗證**

  開啟 `index.html`，規格載入後：
  - 在掃描框輸入 `ABC123` 按 Enter → 應出現「格式不對」alert
  - 在掃描框輸入 `K64271912;38Q;600M` 按 Enter → 應正常新增預覽卡片

- [ ] **Step 3: Commit**

  ```bash
  git add index.html
  git commit -m "feat: validate K-code prefix on scan"
  ```

---

## Task 5：HTML — 產出時同步寫入 Google Sheets

**目標：** 按下產出按鈕後，在下載本地檔案的同時，將 scannedData 以 no-cors POST 寫入對照表。

**Files:**
- 修改：`index.html`

- [ ] **Step 1: 加入 `postToGAS()` 函式**

  在 `startExportProcess()` 函式**前面**插入：

  ```javascript
  function postToGAS(data) {
    fetch(GAS_URL, {
      method: 'POST',
      mode: 'no-cors',
      body: JSON.stringify(data)
    });
  }
  ```

- [ ] **Step 2: 在 `startExportProcess()` 裡呼叫 `postToGAS`**

  找到：
  ```javascript
  async function startExportProcess() {
    const btn = document.getElementById('btnExport');
    const specName = scannedData[0].specName;
    const dateStr = scannedData[0].date;
    const huiStr = `第${scannedData[0].hui}回`;

    // 1. 下載 Excel (維持 30 列)
    exportExcel(specName, dateStr, huiStr);
  ```
  在 `exportExcel(...)` 這行**後面**插入：

  ```javascript
    // 3. 同步寫入 Google Sheets（fire-and-forget）
    postToGAS(scannedData);
  ```

- [ ] **Step 3: 驗證寫入 Google Sheets**

  開啟 `index.html`，載入規格 → 選規格 → 選日期 → 選回數 → 掃描至少 1 筆 K-Code → 按「產出」按鈕。  
  
  產出完成後，前往 Google Sheets「對照表」Tab，應看到剛才掃描的資料列（約 1-5 秒內出現）。

  確認欄位：序號、規格名、A 碼、B 碼、日期、回數、寫入時間均正確。

- [ ] **Step 4: Commit**

  ```bash
  git add index.html
  git commit -m "feat: post scan data to Google Sheets on export"
  ```

---

## Task 6：部署到 GitHub Pages

**目標：** 建立 GitHub repo，推上程式碼，開啟 GitHub Pages，取得公開 URL。

**Files:**
- 確認 `index.html` 在根目錄
- 確認 `Code.gs` 在根目錄（備查用）

- [ ] **Step 1: 初始化 git repo（若尚未初始化）**

  在專案資料夾執行：
  ```bash
  git init
  git add index.html Code.gs docs/
  git commit -m "init: cloud label tool"
  ```

- [ ] **Step 2: 在 GitHub 建立新 repo**

  前往 https://github.com/new → 建立新 repo（名稱建議：`label-tool` 或類似），**不要**勾選 Initialize with README。

- [ ] **Step 3: 推上 GitHub**

  ```bash
  git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
  git branch -M main
  git push -u origin main
  ```

- [ ] **Step 4: 開啟 GitHub Pages**

  GitHub repo → Settings → Pages → Source 選「Deploy from a branch」→ Branch 選 `main`，資料夾選 `/ (root)` → Save。

- [ ] **Step 5: 確認 URL 可以開啟**

  等約 30 秒到 1 分鐘，前往：
  ```
  https://YOUR_USERNAME.github.io/YOUR_REPO/
  ```
  應看到工具頁面，且規格自動載入。若出現 404，等多一分鐘再重整。

- [ ] **Step 6: 全流程整合測試**

  用 GitHub Pages URL 測試完整流程：
  1. 開啟 URL → 規格下拉出現 ✓
  2. 選規格、選日期、選回數
  3. 掃描 K-Code（至少 2 筆）→ 預覽卡片出現 ✓
  4. 故意輸入非 K 開頭條碼 → 出現格式錯誤提示 ✓
  5. 按「產出」→ PDF 下載 ✓、Excel 下載 ✓
  6. 前往 Google Sheets 對照表 → 資料列出現 ✓

---

## 完成標準

- [ ] 任何電腦開啟 GitHub Pages URL 即可使用，不需要本地檔案
- [ ] 規格下拉由 Google Sheets 驅動，修改 Sheets 即時生效
- [ ] 掃描非 K 開頭條碼會被擋住
- [ ] 按產出後對照表 Tab 自動新增資料
- [ ] 本地 PDF 60 張、Excel 30 列下載行為不變
