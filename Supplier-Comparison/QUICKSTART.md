# Quick Start Guide

## Step 1: Convert Your Spreadsheet

Your Apple Numbers file needs to be converted to CSV or Excel format:

1. Open `ASTPSO Master Product List.numbers` in Numbers
2. Click **File** → **Export To** → **CSV** (recommended) or **Excel**
3. Save it as `products.csv` in this folder

## Step 2: Install Dependencies

Run the setup script:

```bash
cd /Users/brentlichtenberg/VisualStudio/Supplier-Comparison
./setup.sh
```

Or manually install:

```bash
pip3 install -r requirements.txt
```

## Step 3: Run the Scraper

```bash
python3 price_scraper.py products.csv
```

The scraper will:
- ✅ Read product names from Column A
- ✅ Search all 4 supplier websites
- ✅ Update prices in the spreadsheet
- ✅ Mark unavailable products as "NA"
- ✅ Create a backup before updating

## Test with One Product First

```bash
python3 price_scraper.py products.csv --product "Walk-In Tub 3052"
```

## View Results

- Open the updated `products.csv` in Excel or Numbers
- Check `price_scraper.log` for detailed operation logs
- Backup file: `products.csv.backup`

## Tips

- ⏱️ Scraping takes time (2-3 seconds per supplier per product)
- 📝 Use simple, clear product names for better matching
- 🔄 Run once per day to respect website resources
- 💾 Always keep backups of your data

## Troubleshooting

**Products not found?**
- Check product names match what's on the supplier websites
- Simplify names (e.g., "Walk-In Tub 3052" vs long descriptions)

**SSL errors?**
```bash
pip3 install --upgrade certifi
```

**Need help?**
- Check `price_scraper.log` for errors
- See full documentation in `README.md`
