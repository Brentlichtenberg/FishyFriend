#!/usr/bin/env python3
"""
Quick test script to verify the scraper setup and test with a single product
"""

import sys
import os

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def test_imports():
    """Test that all required packages are installed"""
    print("Testing imports...")
    try:
        import requests
        import bs4
        import pandas
        import openpyxl
        print("✅ All required packages are installed")
        return True
    except ImportError as e:
        print(f"❌ Missing package: {e}")
        print("Please run: pip3 install -r requirements.txt")
        return False

def test_scrapers():
    """Test that all scraper modules can be imported"""
    print("\nTesting scraper modules...")
    try:
        from scrapers import (
            FergusonScraper,
            LowesScraper,
            ConsolidatedScraper,
            FergusonHomeScraper
        )
        print("✅ All scraper modules loaded successfully")
        return True
    except ImportError as e:
        print(f"❌ Error loading scrapers: {e}")
        return False

def test_utils():
    """Test utility modules"""
    print("\nTesting utility modules...")
    try:
        from utils import SpreadsheetHandler
        print("✅ Utility modules loaded successfully")
        return True
    except ImportError as e:
        print(f"❌ Error loading utilities: {e}")
        return False

def show_usage():
    """Show usage instructions"""
    print("\n" + "="*60)
    print("SETUP VERIFIED! ✅")
    print("="*60)
    print("\nNext steps:")
    print("\n1. Convert your Numbers file to CSV:")
    print("   Open 'ASTPSO Master Product List.numbers'")
    print("   File → Export To → CSV")
    print("   Save as 'products.csv'")
    print("\n2. Test with a single product:")
    print('   python3 price_scraper.py products.csv --product "Walk-In Tub"')
    print("\n3. Run on all products:")
    print("   python3 price_scraper.py products.csv")
    print("\n4. Check results:")
    print("   - Updated: products.csv")
    print("   - Backup: products.csv.backup")
    print("   - Logs: price_scraper.log")
    print("\n" + "="*60)

def main():
    print("="*60)
    print("PRICE SCRAPER - SETUP VERIFICATION")
    print("="*60)
    
    all_good = True
    
    all_good &= test_imports()
    all_good &= test_scrapers()
    all_good &= test_utils()
    
    if all_good:
        show_usage()
    else:
        print("\n❌ Setup incomplete. Please fix the errors above.")
        sys.exit(1)

if __name__ == "__main__":
    main()
