#!/usr/bin/env python3
"""
Extract products and list prices from American Standard catalog.
Focuses on product description tables with List Price column.
"""

import pdfplumber
import re
from pathlib import Path
import pandas as pd


def extract_products_with_list_prices(pdf_path):
    """Extract products and their list prices from the catalog."""
    products = []
    
    print(f"Opening PDF: {pdf_path}")
    
    with pdfplumber.open(pdf_path) as pdf:
        print(f"Total pages: {len(pdf.pages)}")
        
        for page_num, page in enumerate(pdf.pages, 1):
            if page_num % 20 == 0:
                print(f"Processing page {page_num}...")
            
            # Extract text and tables
            text = page.extract_text()
            if not text:
                continue
            
            # Check if page has "List Price" indicator
            if 'List Price' in text or 'LIST PRICE' in text or 'Price' in text:
                
                # Method 1: Extract tables
                tables = page.extract_tables()
                if tables:
                    for table in tables:
                        products.extend(parse_table_for_prices(table, page_num))
                
                # Method 2: Parse text directly
                lines = text.split('\n')
                for i, line in enumerate(lines):
                    # Look for lines with product descriptions and prices
                    # Pattern: Product Name ... number (potentially with commas)
                    
                    # Try to find price at end of line (with or without $)
                    price_match = re.search(r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\s*$', line)
                    
                    if price_match:
                        try:
                            price_str = price_match.group(1).replace(',', '')
                            price = float(price_str)
                            
                            # Only consider reasonable prices
                            if 100 <= price <= 100000:
                                # Extract product name (everything before the price)
                                product_name = line[:price_match.start()].strip()
                                
                                # Clean up product name
                                if product_name and len(product_name) > 10:
                                    # Look for product codes in the name
                                    codes = extract_product_codes(product_name)
                                    
                                    products.append({
                                        'product_name': product_name,
                                        'codes': codes,
                                        'list_price': price,
                                        'page': page_num,
                                        'source': 'text_line'
                                    })
                        except:
                            pass
    
    print(f"\nTotal products extracted: {len(products)}")
    return products


def parse_table_for_prices(table, page_num):
    """Parse a table to extract products and prices."""
    products = []
    
    if not table or len(table) < 2:
        return products
    
    # Find header row and price column
    price_col_idx = None
    header_row = None
    
    for row_idx, row in enumerate(table[:3]):  # Check first 3 rows for headers
        if not row:
            continue
        for col_idx, cell in enumerate(row):
            if cell and ('List Price' in str(cell) or 'Price' in str(cell)):
                price_col_idx = col_idx
                header_row = row_idx
                break
        if price_col_idx is not None:
            break
    
    # If we found a price column, extract data
    if price_col_idx is not None:
        for row in table[header_row + 1:]:
            if not row or len(row) <= price_col_idx:
                continue
            
            price_cell = row[price_col_idx]
            if not price_cell:
                continue
            
            # Extract price
            price_match = re.search(r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)', str(price_cell))
            if price_match:
                try:
                    price = float(price_match.group(1).replace(',', ''))
                    if 100 <= price <= 100000:
                        # Get product name from other columns
                        product_parts = [str(cell) for cell in row[:price_col_idx] if cell]
                        product_name = ' '.join(product_parts)
                        
                        if product_name:
                            codes = extract_product_codes(' '.join([str(c) for c in row if c]))
                            
                            products.append({
                                'product_name': product_name.strip(),
                                'codes': codes,
                                'list_price': price,
                                'page': page_num,
                                'source': 'table'
                            })
                except:
                    pass
    
    return products


def extract_product_codes(text):
    """Extract potential product codes from text."""
    codes = []
    
    # Various product code patterns
    patterns = [
        r'\b\d{7}\.\d{3}\b',  # 7-digit.3-digit
        r'\b[A-Z]{2}\d{6}\.\d{3}\b',  # TU105740.002
        r'\b\d{4}[A-Z]\d{2}[A-Z]{3,4}\b',  # 2848D09CLL
        r'\b\d{4}\.[A-Z]\d{1,2}[A-Z]?\.[A-Z]{2,4}\b',  # 2848.D09.CLL
        r'\b\d{4}[A-Z]\d{2,3}\.\d{3}\b',  # Mixed formats
        r'\b[A-Z]+\d{5,}\b',  # STMX type codes
    ]
    
    for pattern in patterns:
        matches = re.findall(pattern, text)
        codes.extend(matches)
    
    return list(set(codes))  # Remove duplicates


def create_matching_dict(products):
    """Create dictionary for matching product codes to prices."""
    price_dict = {}
    
    for product in products:
        price = product['list_price']
        
        # Add all extracted codes
        for code in product['codes']:
            variations = [
                code,
                code.upper(),
                code.lower(),
                code.replace('.', ''),
                code.replace('-', ''),
                re.sub(r'[^A-Za-z0-9]', '', code),
            ]
            
            for var in variations:
                if var:
                    price_dict[var] = price
        
        # Also try to extract codes from product name
        name_codes = extract_product_codes(product['product_name'])
        for code in name_codes:
            if code not in product['codes']:
                price_dict[code] = price
                price_dict[code.replace('.', '')] = price
    
    return price_dict


def main():
    pdf_path = Path.home() / "Desktop" / "PSKU Project" / "American Standard Residential Product Catalog.pdf"
    
    if not pdf_path.exists():
        print(f"Error: {pdf_path} not found!")
        return
    
    # Extract products
    products = extract_products_with_list_prices(pdf_path)
    
    # Save detailed results
    output_file = Path(__file__).parent / "catalog_list_prices.csv"
    if products:
        df = pd.DataFrame(products)
        df.to_csv(output_file, index=False)
        print(f"\nSaved {len(products)} products to {output_file}")
        
        # Show samples from page 62 and nearby
        print("\n=== Sample products (especially from page 62) ===")
        page_62_products = [p for p in products if p['page'] == 62]
        if page_62_products:
            print(f"\nFound {len(page_62_products)} products on page 62:")
            for p in page_62_products[:5]:
                print(f"  - {p['product_name'][:60]}... ${p['list_price']:,.0f}")
                if p['codes']:
                    print(f"    Codes: {', '.join(p['codes'])}")
        
        print("\n=== First 20 products ===")
        for i, p in enumerate(products[:20]):
            print(f"{i+1}. Page {p['page']}: {p['product_name'][:50]}... ${p['list_price']:,.0f}")
            if p['codes']:
                print(f"   Codes: {', '.join(p['codes'])}")
    
    # Create matching dictionary
    price_dict = create_matching_dict(products)
    print(f"\n\nCreated price dictionary with {len(price_dict)} entries for matching")
    
    return products, price_dict


if __name__ == "__main__":
    main()
