#!/usr/bin/env python3
"""
Final version - properly combine split descriptions.
"""

import pdfplumber
import re
import pandas as pd


def extract_walkin_tub_data(pdf_path, start_page=62, end_page=81):
    """
    Extract walk-in tub data with smart description combining.
    """
    products = []
    
    print(f"Opening catalog: {pdf_path}")
    print(f"Extracting pages {start_page} to {end_page}...")
    
    with pdfplumber.open(pdf_path) as pdf:
        for page_num in range(start_page - 1, min(end_page, len(pdf.pages))):
            page = pdf.pages[page_num]
            actual_page_num = page_num + 1
            
            print(f"\nProcessing page {actual_page_num}...")
            
            text = page.extract_text()
            if not text:
                continue
            
            lines = text.split('\n')
            products_on_page = 0
            pending_description = ""
            
            for i, line in enumerate(lines):
                line = line.strip()
                if not line or line.startswith('•') or line.startswith('NOTE:') or line.startswith('*'):
                    continue
                
                # Check if line has SKU and price
                sku_match = re.search(r'\b(\d{4}\.\d{3}\.[A-Z]{2,3})\b', line)
                price_match = re.search(r'\b(\d{1,2},\d{3})\b$', line)
                color_match = re.search(r'\b(White|Linen|Bone|Biscuit|Almond)\b', line, re.IGNORECASE)
                
                if sku_match and price_match:
                    sku = sku_match.group(1)
                    price = price_match.group(1)
                    color = color_match.group(1).capitalize() if color_match else ""
                    
                    # Get description from line before SKU
                    desc_on_line = line[:sku_match.start()].strip()
                    desc_on_line = re.sub(r'\d+\s*lb\s*', '', desc_on_line)
                    desc_on_line = re.sub(r'\d+\.?\d*\s*kg\s*', '', desc_on_line)
                    desc_on_line = desc_on_line.strip()
                    
                    # Combine with pending description
                    if pending_description and desc_on_line:
                        full_description = pending_description + " " + desc_on_line
                    elif pending_description:
                        full_description = pending_description
                    else:
                        full_description = desc_on_line
                    
                    full_description = re.sub(r'\s+', ' ', full_description).strip()
                    
                    products.append({
                        'Description': full_description,
                        'SKU': sku,
                        'Price': price,
                        'Color': color,
                        'QR Code URL': ''
                    })
                    products_on_page += 1
                    pending_description = ""
                    
                # Check if this is a potential description line (long line without SKU/price)
                elif (len(line) > 25 and 
                      not sku_match and 
                      not price_match and
                      not re.search(r'Nominal Dimensions|in x|mm x', line)):
                    # This could be the first part of a description
                    # Check if next line has a SKU
                    if i + 1 < len(lines):
                        next_line = lines[i + 1].strip()
                        if re.search(r'\d{4}\.\d{3}\.[A-Z]{2,3}', next_line):
                            # Next line has product data, so this is a description
                            pending_description = line
            
            print(f"  Extracted {products_on_page} products")
    
    print(f"\nTotal products: {len(products)}")
    return products


def main():
    catalog_path = '/Users/brentlichtenberg/Desktop/PSKU Project/American Standard Residential Product Catalog.pdf'
    output_path = '/Users/brentlichtenberg/Desktop/PSKU Project/WIT Options-2026-Populated.csv'
    
    products = extract_walkin_tub_data(catalog_path, start_page=62, end_page=81)
    
    if products:
        df = pd.DataFrame(products)
        df = df.drop_duplicates(subset=['SKU'], keep='first')
        
        print(f"\n{'='*70}")
        print("Sample products (first 10):")
        print("="*70)
        for i, row in df.head(10).iterrows():
            print(f"\n{i+1}. {row['Description']}")
            print(f"   SKU: {row['SKU']} | Price: ${row['Price']} | Color: {row['Color']}")
        
        df.to_csv(output_path, index=False)
        print(f"\n{'='*70}")
        print(f"✓ Saved {len(df)} products to: {output_path}")
        print("="*70)


if __name__ == '__main__':
    main()
