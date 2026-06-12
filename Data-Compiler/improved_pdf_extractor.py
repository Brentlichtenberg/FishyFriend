#!/usr/bin/env python3
"""
Advanced PDF Catalog Extractor with better pattern matching.
"""

import pdfplumber
import re
from pathlib import Path
import pandas as pd


def extract_all_prices_from_catalog(pdf_path):
    """Extract comprehensive pricing data from catalog."""
    products = []
    
    print(f"Opening PDF: {pdf_path}")
    
    with pdfplumber.open(pdf_path) as pdf:
        print(f"Total pages: {len(pdf.pages)}")
        
        for page_num, page in enumerate(pdf.pages, 1):
            if page_num % 50 == 0:
                print(f"Processing page {page_num}...")
            
            text = page.extract_text()
            if not text:
                continue
            
            # Try multiple extraction strategies
            
            # Strategy 1: Look for MSRP or List Price tables
            if 'MSRP' in text or 'List Price' in text or 'Price' in text:
                lines = text.split('\n')
                for i, line in enumerate(lines):
                    # Look for lines with product codes and prices
                    # Patterns: CODE ... $PRICE or CODE $PRICE
                    matches = re.findall(
                        r'([A-Z0-9][\w\.\-]{4,20})\s+.*?\$\s*(\d+(?:,\d{3})*(?:\.\d{2})?)',
                        line
                    )
                    
                    for code, price in matches:
                        try:
                            price_val = float(price.replace(',', ''))
                            if 10 <= price_val <= 100000:
                                products.append({
                                    'code': code.strip(),
                                    'price': price_val,
                                    'page': page_num,
                                    'context': line[:100]
                                })
                        except:
                            pass
            
            # Strategy 2: Extract tables
            tables = page.extract_tables()
            if tables:
                for table in tables:
                    if not table or len(table) < 2:
                        continue
                    
                    # Find columns that might contain codes and prices
                    for row_idx, row in enumerate(table):
                        if not row:
                            continue
                        
                        code_cell = None
                        price_cell = None
                        
                        for cell_idx, cell in enumerate(row):
                            if not cell:
                                continue
                            
                            cell_str = str(cell).strip()
                            
                            # Check for price
                            price_match = re.search(r'\$?\s*(\d+(?:,\d{3})*(?:\.\d{2})?)', cell_str)
                            if price_match:
                                try:
                                    price_val = float(price_match.group(1).replace(',', ''))
                                    if 10 <= price_val <= 100000:
                                        price_cell = price_val
                                except:
                                    pass
                            
                            # Check for product code
                            if re.match(r'^[A-Z0-9][\w\.\-]{3,20}$', cell_str):
                                code_cell = cell_str
                        
                        if code_cell and price_cell:
                            products.append({
                                'code': code_cell,
                                'price': price_cell,
                                'page': page_num,
                                'context': ' | '.join([str(c) for c in row if c])[:100]
                            })
    
    print(f"\nTotal products extracted: {len(products)}")
    return products


def create_price_dict(products):
    """Create dictionary with multiple normalized versions of each code."""
    price_dict = {}
    
    for product in products:
        code = product['code']
        price = product['price']
        
        # Store various normalized versions
        variations = [
            code,
            code.upper(),
            code.lower(),
            code.replace('.', ''),
            code.replace('-', ''),
            code.replace(' ', ''),
            re.sub(r'[^A-Za-z0-9]', '', code).upper(),
            re.sub(r'[^A-Za-z0-9]', '', code).lower(),
        ]
        
        # Also try with dots in different positions (e.g., 2848D09CLL <-> 2848.D09.CLL)
        if '.' not in code and len(code) > 6:
            # Try adding dots: 2848D09CLL -> 2848.D09.CLL
            # Common pattern: XXXX.XXX.XXX
            variations.append(f"{code[:4]}.{code[4:7]}.{code[7:]}")
            variations.append(f"{code[:4]}.{code[4:]}")
        
        for var in variations:
            if var and var not in price_dict:
                price_dict[var] = price
    
    return price_dict


def main():
    pdf_path = Path.home() / "Desktop" / "PSKU Project" / "American Standard Residential Product Catalog.pdf"
    
    if not pdf_path.exists():
        print(f"Error: {pdf_path} not found!")
        return
    
    products = extract_all_prices_from_catalog(pdf_path)
    
    # Save extracted products
    output_file = Path(__file__).parent / "catalog_prices_improved.csv"
    if products:
        df = pd.DataFrame(products)
        df.to_csv(output_file, index=False)
        print(f"Saved {len(products)} products to {output_file}")
        
        # Show sample
        print("\nSample products:")
        for i, p in enumerate(products[:20]):
            print(f"{i+1}. {p['code']}: ${p['price']}")
    else:
        print("No products extracted")
    
    # Create and show price dictionary stats
    price_dict = create_price_dict(products)
    print(f"\nPrice dictionary contains {len(price_dict)} normalized entries")


if __name__ == "__main__":
    main()
