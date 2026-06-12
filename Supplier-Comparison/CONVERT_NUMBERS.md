# Converting Apple Numbers to CSV/Excel

## Your Numbers File
- **Current file:** `ASTPSO Master Product List.numbers`
- **Needs to be:** `products.csv` or `products.xlsx`

---

## Option 1: Export to CSV (Recommended) ⭐

### Steps:
1. **Double-click** `ASTPSO Master Product List.numbers` to open in Numbers
2. Click **File** menu → **Export To** → **CSV...**
3. In the dialog:
   - **File name:** Enter `products.csv`
   - **Text Encoding:** Choose `UTF-8` (recommended)
4. Click **Next**
5. **Save location:** Save in the same folder as the scraper
   - `/Users/brentlichtenberg/VisualStudio/Supplier-Comparison/`
6. Click **Export**

✅ Done! Your file is ready.

---

## Option 2: Export to Excel

### Steps:
1. **Double-click** `ASTPSO Master Product List.numbers` to open in Numbers
2. Click **File** menu → **Export To** → **Excel...**
3. In the dialog:
   - **File name:** Enter `products.xlsx`
   - **Format:** Choose `.xlsx` (recommended)
4. Click **Next**
5. **Save location:** Save in the same folder as the scraper
   - `/Users/brentlichtenberg/VisualStudio/Supplier-Comparison/`
6. Click **Export**

✅ Done! Your file is ready.

---

## Verify Your Spreadsheet

Your converted spreadsheet should have:

### Column Structure:
- **Column A:** Product names (REQUIRED)
- **Other columns:** Can be empty or have existing data

### Example:
```
Column A              | Column B | Column C | ...
--------------------------------------------------
Product Name          | (optional data)
Walk-In Tub 3052      | 
Accessible Bathtub    | 
Walk-In Bath Model X  | 
```

The scraper will:
- ✅ Read product names from Column A
- ✅ Create supplier columns if they don't exist
- ✅ Preserve any other data in the spreadsheet

---

## What Happens to Supplier Columns?

The scraper will create/update these columns:
1. **Ferguson**
2. **Lowes**
3. **Consolidated Supply**
4. **Ferguson Home**
5. **Last Updated** (timestamp)

**If columns already exist:** They will be overwritten with new prices.

---

## After Converting

Run the scraper:

```bash
cd /Users/brentlichtenberg/VisualStudio/Supplier-Comparison

# If you exported to CSV:
python3 price_scraper.py products.csv

# If you exported to Excel:
python3 price_scraper.py products.xlsx
```

---

## Alternative: Use Numbers Export Menu

### Quick Method:
1. Open the Numbers file
2. **Right-click** on the file name in the title bar
3. Select **Export To** → **CSV** or **Excel**
4. Follow the steps above

---

## Troubleshooting

### "Can't find the file"
Make sure you saved it to:
```
/Users/brentlichtenberg/VisualStudio/Supplier-Comparison/
```

### "Wrong format"
The scraper supports:
- ✅ `.csv` (Recommended)
- ✅ `.xlsx` (Excel 2007+)
- ✅ `.xls` (Excel 97-2003)
- ❌ `.numbers` (Not supported - must convert)

### "Sheet is empty"
Make sure:
- Product names are in Column A
- At least one product name exists
- No empty rows at the top

---

## Keep Your Original

**Important:** The Numbers file will NOT be modified. Keep it as your master copy!

The scraper will:
- ✅ Read from the CSV/Excel version
- ✅ Create a backup before updating (`.backup` extension)
- ❌ Never touch the original Numbers file

---

## Ready!

Once converted, you're ready to run the scraper. See `QUICKSTART.md` for next steps!
