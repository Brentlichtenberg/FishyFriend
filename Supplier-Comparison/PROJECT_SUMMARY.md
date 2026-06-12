# 🎯 American Standard Price Scraper - Project Summary

## ✅ What Was Created

A complete web scraping solution that:

1. **Reads your product spreadsheet** (CSV or Excel)
2. **Searches 4 supplier websites** for each product:
   - Ferguson.com
   - Lowes.com
   - ConsolidatedSupply.com
   - FergusonHome.com
3. **Extracts current prices** and updates your spreadsheet
4. **Marks products as "NA"** if not found
5. **Overwrites existing prices** each time it runs
6. **Creates automatic backups** before updating

---

## 📁 Project Structure

```
Supplier-Comparison/
│
├── 📄 price_scraper.py              # Main program - run this!
├── 📄 requirements.txt              # Python packages needed
├── 📄 setup.sh                      # Easy setup script
│
├── 📖 README.md                     # Full documentation
├── 📖 QUICKSTART.md                 # Quick start guide
├── 📖 PROJECT_SUMMARY.md            # This file
│
├── 📊 products_template.csv         # Sample spreadsheet template
├── 📊 ASTPSO Master Product List.numbers  # Your original file (needs conversion)
│
├── 📁 scrapers/                     # Web scraper modules
│   ├── __init__.py
│   ├── base_scraper.py             # Base scraper class
│   ├── ferguson_scraper.py         # Ferguson scraper
│   ├── lowes_scraper.py            # Lowe's scraper
│   ├── consolidated_scraper.py     # Consolidated Supply scraper
│   └── ferguson_home_scraper.py    # Ferguson Home scraper
│
└── 📁 utils/                        # Utility modules
    ├── __init__.py
    └── spreadsheet_handler.py      # Spreadsheet read/write operations
```

---

## 🚀 How to Use

### 1️⃣ First Time Setup

**Convert your Numbers file to CSV:**
1. Open `ASTPSO Master Product List.numbers`
2. File → Export To → CSV
3. Save as `products.csv`

**Install dependencies:**
```bash
cd "/Users/brentlichtenberg/VisualStudio/Supplier-Comparison"
./setup.sh
```

### 2️⃣ Run the Scraper

**Scrape all products:**
```bash
python3 price_scraper.py products.csv
```

**Test with one product:**
```bash
python3 price_scraper.py products.csv --product "Walk-In Tub 3052"
```

### 3️⃣ Check Results

- ✅ Open updated `products.csv`
- ✅ Review `price_scraper.log` for details
- ✅ Backup saved as `products.csv.backup`

---

## 📊 Spreadsheet Format

Your spreadsheet should look like this:

| **Product Name** | **Ferguson** | **Lowes** | **Consolidated Supply** | **Ferguson Home** | **Last Updated** |
|------------------|--------------|-----------|------------------------|------------------|------------------|
| Walk-In Tub 3052 | $2,499.00   | $2,350.00 | NA                     | $2,450.00       | 2026-01-05 14:30 |
| Accessible Bathtub| $3,200.00   | NA        | $3,150.00              | $3,100.00       | 2026-01-05 14:32 |

**Important:**
- ✅ Column A = Product names (required)
- ✅ Supplier columns created automatically if missing
- ✅ Prices overwritten each run
- ✅ "NA" for products not found
- ✅ Timestamp added automatically

---

## 🔧 Technical Features

### Smart Product Matching
- Normalizes product names
- Fuzzy matching algorithm
- Searches first 3 words of product name
- Case-insensitive matching

### Web Scraping
- Respectful rate limiting (2-3 sec delays)
- Proper User-Agent headers
- Error handling and retries
- Comprehensive logging

### Data Safety
- Automatic backups before updates
- Validates spreadsheet structure
- Safe file operations
- Detailed error logging

---

## 📝 Key Files Explained

### `price_scraper.py`
The main program. Coordinates all scraping operations.

**Usage:**
```bash
python3 price_scraper.py <spreadsheet_path> [--product <name>]
```

### `scrapers/`
Contains individual scrapers for each supplier website. Each scraper:
- Searches the website
- Parses HTML results
- Extracts prices
- Returns formatted data

### `utils/spreadsheet_handler.py`
Handles reading/writing CSV and Excel files safely.

### `requirements.txt`
Python packages needed:
- `requests` - HTTP requests
- `beautifulsoup4` - HTML parsing
- `pandas` - Spreadsheet operations
- `openpyxl` - Excel support
- `lxml` - Fast XML/HTML parsing

---

## ⚠️ Important Notes

### Rate Limiting
- 2-second delay between suppliers
- 3-second delay between products
- Don't run more than once per day

### Product Names
- Use clear, simple names
- Match supplier website terminology
- Example: "Walk-In Tub 3052" better than "American Standard Walk-In Bathtub Model #3052-LH White"

### Website Changes
If suppliers change their websites, scrapers may need updates. Check logs for errors.

### Legal/Ethical
- For personal use only
- Respects website terms of service
- Uses polite scraping practices
- Includes proper delays

---

## 🐛 Troubleshooting

### "Product not found" for many items
- ✅ Simplify product names
- ✅ Check names match supplier websites
- ✅ Try searching manually first

### SSL Certificate errors
```bash
pip3 install --upgrade certifi
```

### Permission denied
```bash
chmod +x setup.sh
chmod 644 products.csv
```

### Import errors
```bash
pip3 install -r requirements.txt --upgrade
```

---

## 📈 Performance

**Time estimates:**
- 4 suppliers × 2 seconds = 8 seconds per product
- 10 products ≈ 2 minutes
- 50 products ≈ 10 minutes
- 100 products ≈ 20 minutes

Plus 3-second delays between products for politeness.

---

## 🎓 Next Steps

1. **Convert your Numbers file** to CSV/Excel
2. **Run setup:** `./setup.sh`
3. **Test with one product** to verify it works
4. **Run full scrape** on your product list
5. **Schedule regular runs** (optional - once per day max)

---

## 📧 Support Files

- `README.md` - Complete documentation
- `QUICKSTART.md` - Fast setup guide
- `products_template.csv` - Example spreadsheet
- `price_scraper.log` - Operation logs (created when run)

---

## 🏁 Ready to Go!

Your price scraper is ready to use. Start with the QUICKSTART.md guide for the fastest path to results.

**Quick command:**
```bash
cd "/Users/brentlichtenberg/VisualStudio/Supplier-Comparison"
./setup.sh
python3 price_scraper.py products.csv
```

Good luck with your price comparisons! 🚀
