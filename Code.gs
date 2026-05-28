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
