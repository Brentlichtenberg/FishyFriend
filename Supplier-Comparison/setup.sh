#!/bin/bash
# Setup script for Price Scraper

echo "=== American Standard Price Scraper Setup ==="
echo ""

# Check Python version
echo "Checking Python version..."
python3 --version

if [ $? -ne 0 ]; then
    echo "❌ Python 3 is not installed. Please install Python 3.8 or higher."
    exit 1
fi

echo "✅ Python is installed"
echo ""

# Install dependencies
echo "Installing required packages..."
pip3 install -r requirements.txt

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo "✅ Dependencies installed successfully"
echo ""

# Check if Numbers file exists and remind to convert
if [ -f "ASTPSO Master Product List.numbers" ]; then
    echo "⚠️  Found Apple Numbers file: ASTPSO Master Product List.numbers"
    echo "   Please convert this to CSV or Excel format:"
    echo "   1. Open in Numbers"
    echo "   2. File > Export To > CSV (or Excel)"
    echo "   3. Save as 'products.csv' or 'products.xlsx'"
    echo ""
fi

echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Make sure your spreadsheet is in CSV or Excel format"
echo "2. Run the scraper:"
echo "   python3 price_scraper.py your_spreadsheet.csv"
echo ""
echo "For help, see README.md"
