# American Standard Product Price Scraper

A Python-based web scraper that automatically compares prices of American Standard bathroom products across multiple supplier websites and updates your spreadsheet with the latest pricing information.

## Supported Suppliers

1. **Ferguson** - https://www.ferguson.com
2. **Lowe's** - https://www.lowes.com
3. **Consolidated Supply** - https://www.consolidatedsupply.com
4. **Ferguson Home** - https://www.fergusonhome.com

## Features

- ✅ Scrapes prices from 4 major suppliers
- ✅ Automatically matches products by name
- ✅ Updates spreadsheet with current prices
- ✅ Marks unavailable products as "NA"
- ✅ Creates backup of spreadsheet before updating
- ✅ Comprehensive logging of all operations
- ✅ Supports both CSV and Excel formats (.xlsx, .xls)
- ✅ Polite scraping with delays between requests

## Prerequisites

- Python 3.8 or higher
- pip (Python package installer)

## Installation

1. **Install required packages:**
   ```bash
   pip install -r requirements.txt
   ```

## Spreadsheet Setup

Your spreadsheet should have the following structure:

| Column A (Product Name) | Ferguson | Lowes | Consolidated Supply | Ferguson Home | Last Updated |
|------------------------|----------|-------|---------------------|---------------|--------------|
| Product Name 1         | (price)  | (price)| (price)            | (price)       | (timestamp)  |
| Product Name 2         | (price)  | (price)| (price)            | (price)       | (timestamp)  |

**Important Notes:**
- Column A must contain the product names
- Supplier columns will be automatically created if they don't exist
- All prices will be overwritten each time the scraper runs
- Products not found will show "NA"

### Converting from Apple Numbers

If you have an Apple Numbers file (`.numbers`), you need to convert it to CSV or Excel:

1. Open the file in Numbers
2. Go to File > Export To > CSV (or Excel)
3. Save the file in the same directory as the scraper

## Usage

### Scrape All Products

To scrape prices for all products in your spreadsheet:

```bash
python price_scraper.py path/to/your/spreadsheet.csv
```

Or for Excel:
```bash
python price_scraper.py path/to/your/spreadsheet.xlsx
```

### Scrape Single Product (Testing)

To test with a single product:

```bash
python price_scraper.py path/to/your/spreadsheet.csv --product "Walk-In Tub Model 3052"
```

## Example

```bash
# Using the sample template
python price_scraper.py products_template.csv

# Using your own file
python price_scraper.py "ASTPSO Master Product List.csv"
```

## Output

The scraper will:
1. Read all product names from Column A
2. Search each supplier website for matching products
3. Extract the current price
4. Update the spreadsheet with prices (or "NA" if not found)
5. Add a "Last Updated" timestamp
6. Create a backup of the original file

### Log Files

All operations are logged to `price_scraper.log` in the same directory.

## How It Works

### Product Matching

The scraper uses fuzzy matching to find products:
- Normalizes product names (lowercase, removes extra spaces)
- Searches for the first 3 words of the product name
- Returns the first matching result

### Scraping Strategy

Each supplier scraper:
1. Searches the website with the product name
2. Parses HTML to find product listings
3. Matches product titles
4. Extracts price information
5. Returns numeric price value

### Rate Limiting

To be respectful to the websites:
- 2-second delay between each supplier request
- 3-second delay between products
- Proper User-Agent headers

## Troubleshooting

### "Product not found" for many products

- Check that product names in Column A match the actual product names on supplier websites
- Try simplifying product names (e.g., "Walk-In Tub 3052" instead of full model numbers)
- Check the log file for detailed error messages

### SSL Certificate Errors

If you get SSL errors, you may need to update your certificates:
```bash
pip install --upgrade certifi
```

### Permission Errors

Make sure you have write permissions for the spreadsheet file and directory.

### Website Changes

If a supplier website changes their HTML structure, the scraper may need updates. Check the log file and report issues.

## Important Notes

⚠️ **Web Scraping Considerations:**
- This tool is for personal use and price comparison
- Respect website terms of service
- Don't run too frequently (once per day is reasonable)
- Some websites may block automated access
- Prices may not always be accurate due to website changes

⚠️ **Backup:**
- Always keep a backup of your original spreadsheet
- The tool creates automatic backups with `.backup` extension

## File Structure

```
Supplier-Comparison/
├── price_scraper.py           # Main script
├── requirements.txt           # Python dependencies
├── README.md                 # This file
├── products_template.csv     # Sample template
├── scrapers/
│   ├── __init__.py
│   ├── base_scraper.py       # Base scraper class
│   ├── ferguson_scraper.py   # Ferguson scraper
│   ├── lowes_scraper.py      # Lowe's scraper
│   ├── consolidated_scraper.py  # Consolidated Supply scraper
│   └── ferguson_home_scraper.py # Ferguson Home scraper
└── utils/
    ├── __init__.py
    └── spreadsheet_handler.py # Spreadsheet operations
```

## Support

For issues or questions:
1. Check the log file (`price_scraper.log`)
2. Verify your spreadsheet format matches the template
3. Test with a single product first
4. Ensure all dependencies are installed

## License

This tool is provided as-is for personal use.
