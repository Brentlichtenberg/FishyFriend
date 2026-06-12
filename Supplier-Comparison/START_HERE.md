# 🛁 American Standard Bathroom Products - Price Comparison Tool

**Automatically scrape and compare prices across 4 major suppliers**

---

## 🎯 What This Does

This tool automatically:
- ✅ Reads American Standard product names from your spreadsheet
- ✅ Searches 4 supplier websites (Ferguson, Lowe's, Consolidated Supply, Ferguson Home)
- ✅ Extracts current prices for each product
- ✅ Updates your spreadsheet with the latest pricing
- ✅ Marks unavailable products as "NA"
- ✅ Creates backups before each update

---

## 🚀 Quick Start (3 Steps)

### 1. Convert Your Spreadsheet
Convert `ASTPSO Master Product List.numbers` to CSV:
- Open in Numbers → File → Export To → CSV
- Save as `products.csv`

### 2. Install Dependencies
```bash
cd "/Users/brentlichtenberg/VisualStudio/Supplier-Comparison"
./setup.sh
```

### 3. Run the Scraper
```bash
python3 price_scraper.py products.csv
```

**Done!** Your spreadsheet now has current prices.

---

## 📚 Documentation

Choose your path:

| Document | Best For | What's Inside |
|----------|----------|---------------|
| **[FILE_GUIDE.md](FILE_GUIDE.md)** | 📖 Navigation | Guide to all documentation |
| **[QUICKSTART.md](QUICKSTART.md)** | ⚡ Speed | 5-minute setup |
| **[CHECKLIST.md](CHECKLIST.md)** | ✅ Beginners | Step-by-step checklist |
| **[CONVERT_NUMBERS.md](CONVERT_NUMBERS.md)** | 🔄 Conversion | Convert Numbers to CSV |
| **[README.md](README.md)** | 📖 Complete | Full documentation |
| **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** | 🎯 Overview | What was built |

**Not sure where to start?** → Read [FILE_GUIDE.md](FILE_GUIDE.md)

---

## 🌐 Supported Suppliers

1. **Ferguson** - https://www.ferguson.com
2. **Lowe's** - https://www.lowes.com  
3. **Consolidated Supply** - https://www.consolidatedsupply.com
4. **Ferguson Home** - https://www.fergusonhome.com

---

## 📊 Spreadsheet Format

**Input:** Product names in Column A
**Output:** Prices added in supplier columns

| Product Name | Ferguson | Lowes | Consolidated Supply | Ferguson Home |
|--------------|----------|-------|---------------------|---------------|
| Walk-In Tub 3052 | $2,499.00 | $2,350.00 | NA | $2,450.00 |

---

## 🔧 Commands

```bash
# Setup
./setup.sh

# Test installation
python3 test_setup.py

# Test single product
python3 price_scraper.py products.csv --product "Walk-In Tub"

# Scrape all products
python3 price_scraper.py products.csv

# View logs
tail -f price_scraper.log
```

---

## 📁 Project Structure

```
Supplier-Comparison/
├── 📖 Documentation
│   ├── FILE_GUIDE.md          ← Start here if unsure
│   ├── QUICKSTART.md          ← 5-minute setup
│   ├── CHECKLIST.md           ← Step-by-step guide
│   ├── CONVERT_NUMBERS.md     ← Convert Numbers file
│   ├── README.md              ← Full documentation
│   └── PROJECT_SUMMARY.md     ← Project overview
│
├── 🐍 Main Scripts
│   ├── price_scraper.py       ← Run this to scrape prices
│   ├── test_setup.py          ← Test your installation
│   └── setup.sh               ← Install dependencies
│
├── 📊 Data
│   ├── products_template.csv  ← Example spreadsheet
│   └── products.csv           ← Your data (create this)
│
├── 🔧 Code Modules
│   ├── scrapers/              ← Website scrapers
│   │   ├── ferguson_scraper.py
│   │   ├── lowes_scraper.py
│   │   ├── consolidated_scraper.py
│   │   └── ferguson_home_scraper.py
│   └── utils/                 ← Utilities
│       └── spreadsheet_handler.py
│
└── ⚙️ Config
    ├── requirements.txt       ← Python packages
    └── .gitignore            ← Git ignore rules
```

---

## ⚡ Example Usage

### Test Single Product
```bash
python3 price_scraper.py products.csv --product "Walk-In Tub 3052"
```

**Output:**
```
Searching for: Walk-In Tub 3052
  Ferguson: $2,499.00
  Lowes: $2,350.00
  Consolidated Supply: NA
  Ferguson Home: $2,450.00
```

### Scrape All Products
```bash
python3 price_scraper.py products.csv
```

**Output:**
```
Starting price scraping process...
Found 25 products to search
Processing product 1/25: Walk-In Tub 3052
  Searching Ferguson... Found price: $2,499.00
  Searching Lowes... Found price: $2,350.00
  ...
Scraping complete! Spreadsheet updated.
```

---

## ⚠️ Important Notes

- **Rate Limiting:** 2-3 seconds between requests (be polite to websites)
- **Runtime:** ~2-3 minutes per 10 products
- **Frequency:** Run once per day maximum
- **Backups:** Automatic backups created before each update
- **Logging:** All operations logged to `price_scraper.log`

---

## 🐛 Troubleshooting

**Setup Issues?**
```bash
python3 test_setup.py
```

**Products Not Found?**
- Simplify product names
- Remove model numbers
- Use generic terms

**Check Logs:**
```bash
tail -20 price_scraper.log
```

**Full Troubleshooting:** See [README.md](README.md) → Troubleshooting section

---

## 🎓 Learning Path

**Beginner:** `CHECKLIST.md` → Follow all steps  
**Fast:** `QUICKSTART.md` → Get running quickly  
**Complete:** `README.md` → Everything explained  

**Lost?** → [FILE_GUIDE.md](FILE_GUIDE.md)

---

## 📈 Features

✅ 4 supplier websites supported  
✅ Automatic price extraction  
✅ Smart product matching  
✅ Spreadsheet auto-update  
✅ Backup before updates  
✅ Comprehensive logging  
✅ CSV & Excel support  
✅ Error handling  
✅ Rate limiting (polite scraping)  
✅ "NA" for unavailable products  

---

## 🔐 Requirements

- Python 3.8 or higher
- Internet connection
- Spreadsheet in CSV or Excel format (.csv, .xlsx, .xls)

---

## 📦 Installation

```bash
# 1. Navigate to project
cd "/Users/brentlichtenberg/VisualStudio/Supplier-Comparison"

# 2. Run setup
./setup.sh

# 3. Test installation
python3 test_setup.py

# 4. Ready to go!
```

---

## 💡 Tips

- Start with a small test (5-10 products)
- Use clear, simple product names
- Check logs after each run
- Keep backups of your data
- Don't run too frequently (once/day max)

---

## 🎉 You're All Set!

Your price scraper is ready. Choose your next step:

1. **New?** → Read [CHECKLIST.md](CHECKLIST.md)
2. **Quick?** → Read [QUICKSTART.md](QUICKSTART.md)  
3. **Converting?** → Read [CONVERT_NUMBERS.md](CONVERT_NUMBERS.md)
4. **Lost?** → Read [FILE_GUIDE.md](FILE_GUIDE.md)

---

**Happy price comparing!** 🚀

*Built for comparing American Standard bathroom products across multiple suppliers*
