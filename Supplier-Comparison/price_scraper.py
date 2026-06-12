#!/usr/bin/env python3
"""
Price Scraper for American Standard Bathroom Products
Compares prices across multiple supplier websites and updates spreadsheet
"""

import pandas as pd
import time
import logging
from datetime import datetime
from typing import Dict, List, Optional
from scrapers.ferguson_scraper import FergusonScraper
from scrapers.lowes_scraper import LowesScraper
from scrapers.consolidated_scraper import ConsolidatedScraper
from scrapers.ferguson_home_scraper import FergusonHomeScraper
from utils.spreadsheet_handler import SpreadsheetHandler

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('price_scraper.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class PriceScraper:
    """Main price scraper that coordinates scraping across all suppliers"""
    
    SUPPLIERS = {
        'Ferguson': FergusonScraper(),
        'Lowes': LowesScraper(),
        'Consolidated Supply': ConsolidatedScraper(),
        'Ferguson Home': FergusonHomeScraper()
    }
    
    def __init__(self, spreadsheet_path: str):
        """
        Initialize the price scraper
        
        Args:
            spreadsheet_path: Path to the Excel or CSV file
        """
        self.spreadsheet_path = spreadsheet_path
        self.spreadsheet_handler = SpreadsheetHandler(spreadsheet_path)
        
    def scrape_all_prices(self) -> pd.DataFrame:
        """
        Scrape prices for all products from all suppliers
        
        Returns:
            Updated DataFrame with current prices
        """
        logger.info("Starting price scraping process...")
        
        # Load the spreadsheet
        df = self.spreadsheet_handler.load()
        
        if df.empty:
            logger.error("Spreadsheet is empty or could not be loaded")
            return df
            
        # Ensure supplier columns exist
        for supplier_name in self.SUPPLIERS.keys():
            if supplier_name not in df.columns:
                df[supplier_name] = "NA"
        
        # Get product names from column A
        product_names = df.iloc[:, 0].tolist()  # Column A (index 0)
        
        logger.info(f"Found {len(product_names)} products to search")
        
        # Scrape prices for each product
        for idx, product_name in enumerate(product_names):
            if pd.isna(product_name) or product_name == "":
                continue
                
            logger.info(f"Processing product {idx + 1}/{len(product_names)}: {product_name}")
            
            # Scrape from each supplier
            for supplier_name, scraper in self.SUPPLIERS.items():
                try:
                    logger.info(f"  Searching {supplier_name}...")
                    price = scraper.get_price(product_name)
                    
                    if price is not None:
                        df.at[idx, supplier_name] = f"${price:.2f}"
                        logger.info(f"  Found price: ${price:.2f}")
                    else:
                        df.at[idx, supplier_name] = "NA"
                        logger.info(f"  Product not found")
                        
                except Exception as e:
                    logger.error(f"  Error scraping {supplier_name}: {str(e)}")
                    df.at[idx, supplier_name] = "NA"
                
                # Be polite - add delay between requests
                time.sleep(2)
            
            # Longer delay between products
            time.sleep(3)
        
        # Add last updated timestamp
        df['Last Updated'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        # Save updated spreadsheet
        self.spreadsheet_handler.save(df)
        logger.info("Scraping complete! Spreadsheet updated.")
        
        return df
    
    def scrape_single_product(self, product_name: str) -> Dict[str, Optional[float]]:
        """
        Scrape prices for a single product from all suppliers
        
        Args:
            product_name: Name of the product to search
            
        Returns:
            Dictionary mapping supplier names to prices
        """
        results = {}
        
        for supplier_name, scraper in self.SUPPLIERS.items():
            try:
                price = scraper.get_price(product_name)
                results[supplier_name] = price
            except Exception as e:
                logger.error(f"Error scraping {supplier_name} for {product_name}: {str(e)}")
                results[supplier_name] = None
                
        return results


def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Scrape American Standard bathroom product prices from multiple suppliers'
    )
    parser.add_argument(
        'spreadsheet',
        help='Path to the spreadsheet file (Excel or CSV)'
    )
    parser.add_argument(
        '--product',
        help='Scrape prices for a single product (optional)'
    )
    
    args = parser.parse_args()
    
    scraper = PriceScraper(args.spreadsheet)
    
    if args.product:
        # Scrape single product
        logger.info(f"Searching for: {args.product}")
        results = scraper.scrape_single_product(args.product)
        
        print(f"\nPrices for '{args.product}':")
        for supplier, price in results.items():
            if price is not None:
                print(f"  {supplier}: ${price:.2f}")
            else:
                print(f"  {supplier}: NA")
    else:
        # Scrape all products
        scraper.scrape_all_prices()
        print("\nPrice scraping complete! Check the updated spreadsheet.")


if __name__ == "__main__":
    main()
