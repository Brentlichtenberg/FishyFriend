# ✅ Setup Checklist

Complete these steps to start scraping prices:

---

## 📋 Pre-Flight Checklist

### ☐ Step 1: Verify Python Installation
```bash
python3 --version
```
**Required:** Python 3.8 or higher

---

### ☐ Step 2: Navigate to Project Directory
```bash
cd "/Users/brentlichtenberg/VisualStudio/Supplier-Comparison"
```

---

### ☐ Step 3: Install Dependencies
```bash
./setup.sh
```
**Or manually:**
```bash
pip3 install -r requirements.txt
```

**What gets installed:**
- ✅ requests (HTTP requests)
- ✅ beautifulsoup4 (HTML parsing)
- ✅ pandas (spreadsheet operations)
- ✅ openpyxl (Excel support)
- ✅ lxml (fast parsing)

---

### ☐ Step 4: Test Setup
```bash
python3 test_setup.py
```
**Expected result:** All green checkmarks ✅

---

### ☐ Step 5: Convert Numbers File to CSV
See detailed instructions in `CONVERT_NUMBERS.md`

**Quick steps:**
1. Open `ASTPSO Master Product List.numbers`
2. File → Export To → CSV
3. Save as `products.csv` in this folder

---

### ☐ Step 6: Verify Spreadsheet Format

Your CSV should have:
- ✅ Column A = Product names
- ✅ At least 1 product
- ✅ No empty rows at top

**Example:**
```csv
Product Name,Any Other Columns...
Walk-In Tub 3052,
Accessible Bathtub,
```

---

## 🧪 Testing Phase

### ☐ Step 7: Test with One Product
```bash
python3 price_scraper.py products.csv --product "Walk-In Tub"
```

**Expected:**
- Script runs without errors
- Shows prices from some/all suppliers
- Takes about 8-10 seconds

---

### ☐ Step 8: Check Output
After running, verify:
- ✅ Terminal shows "Searching [supplier]..." messages
- ✅ Prices found or "NA" shown
- ✅ No Python errors or crashes

---

## 🚀 Production Run

### ☐ Step 9: Run Full Scrape
```bash
python3 price_scraper.py products.csv
```

**What to expect:**
- Takes 2-3 minutes per 10 products
- Shows progress in terminal
- Creates log file

---

### ☐ Step 10: Verify Results

**Check these files:**
1. ✅ `products.csv` - Updated with prices
2. ✅ `products.csv.backup` - Original saved
3. ✅ `price_scraper.log` - Detailed logs

**Open products.csv and verify:**
- ✅ Supplier columns created
- ✅ Prices populated or "NA"
- ✅ Last Updated timestamp added

---

## 📊 Results Review

### ☐ Step 11: Analyze Coverage

Count how many products were found:
- **Ferguson:** _____ / _____
- **Lowes:** _____ / _____
- **Consolidated Supply:** _____ / _____
- **Ferguson Home:** _____ / _____

---

### ☐ Step 12: Handle "NA" Results

If many products show "NA":
1. Check product names match website terminology
2. Simplify names (remove model numbers)
3. Try searching manually on supplier sites
4. Adjust product names in spreadsheet
5. Re-run scraper

---

## 🔧 Troubleshooting Checklist

### If imports fail:
- ☐ Check Python version (3.8+)
- ☐ Run `pip3 install -r requirements.txt`
- ☐ Try `pip3 install --upgrade pip`

### If scraper crashes:
- ☐ Check `price_scraper.log`
- ☐ Verify spreadsheet format
- ☐ Test with single product first
- ☐ Check internet connection

### If products not found:
- ☐ Simplify product names
- ☐ Remove special characters
- ☐ Check names on supplier websites
- ☐ Use generic terms (e.g., "Walk-In Tub")

### If SSL errors:
- ☐ Run `pip3 install --upgrade certifi`
- ☐ Check firewall settings

---

## 📅 Ongoing Use

### ☐ Schedule Regular Updates
**Recommended:** Run once per day maximum

**Create a cron job (optional):**
```bash
# Run daily at 2 AM
0 2 * * * cd /Users/brentlichtenberg/VisualStudio/Supplier-Comparison && python3 price_scraper.py products.csv
```

---

### ☐ Maintain Backups
The scraper creates backups automatically, but also:
- Keep original Numbers file safe
- Periodically save CSV to cloud storage
- Keep important log files

---

## ✨ Optional Enhancements

### ☐ Add More Products
Just add rows to Column A in your CSV

### ☐ Monitor Price Changes
Compare current CSV with backups to see price trends

### ☐ Export to Other Formats
Use spreadsheet software to export results to Excel, PDF, etc.

---

## 📚 Reference Documents

- **QUICKSTART.md** - Fast setup guide
- **README.md** - Complete documentation  
- **PROJECT_SUMMARY.md** - Project overview
- **CONVERT_NUMBERS.md** - Numbers conversion guide

---

## ✅ Final Checklist

Before your first run:
- ☐ Python 3.8+ installed
- ☐ All packages installed (`pip3 install -r requirements.txt`)
- ☐ Numbers file converted to CSV
- ☐ Product names in Column A
- ☐ Test setup passed (`python3 test_setup.py`)
- ☐ Single product test successful

**Ready to go!** 🚀

---

## 🎯 Quick Commands Reference

```bash
# Setup
./setup.sh

# Test setup
python3 test_setup.py

# Test one product
python3 price_scraper.py products.csv --product "Product Name"

# Run full scrape
python3 price_scraper.py products.csv

# View logs
tail -f price_scraper.log

# Check last 20 log entries
tail -20 price_scraper.log
```

---

**Questions?** Check the full documentation in `README.md`

**Problems?** Review `price_scraper.log` for detailed error messages
