#!/usr/bin/env python3
"""
Final corrected version - recognize that products span 2 lines in the pattern.
"""

import pdfplumber
import re
import pandas as pd


def extract_walkin_tub_data(pdf_path, start_page=62, end_page=81):
    """
    Extract walk-in tub data.
    Pattern: Each product is described across 2 lines:
    Line 1: Base description + weight + SKU + Color + Price
    Line 2: Additional description details
    OR
    Line 1: Base description
    Line 2: Additional details + SKU + Color + Price
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
            i = 0
            last_description = ""  # Track last description for reuse
            
            while i < len(lines):
                line = lines[i].strip()
                i += 1
                
                # Skip empty, bullets, notes, headers
                if (not line or line.startswith('•') or line.startswith('NOTE:') or 
                    line.startswith('*') or 'Description Net Wt SKU Color List Price' in line or
                    line.startswith('Bathing') or line.startswith('Walk-In-Baths') or
                    re.search(r'Nominal Dimensions', line)):
                    continue
                
                # Check if this line has SKU and price (product data line)
                sku_match = re.search(r'\b(\d{4}\.\d{3}\.[A-Z]{2,3})\b', line)
                price_match = re.search(r'\b(\d{1,2},\d{3})\b$', line)
                color_match = re.search(r'\b(White|Linen|Bone|Biscuit|Almond)\b', line, re.IGNORECASE)
                
                if sku_match and price_match:
                    sku = sku_match.group(1)
                    price = price_match.group(1)
                    color = color_match.group(1).capitalize() if color_match else ""
                    
                    # Get description from this line (before SKU)
                    desc_part2 = line[:sku_match.start()].strip()
                    desc_part2 = re.sub(r'\d+\s*lb\s*', '', desc_part2)
                    desc_part2 = re.sub(r'\d+\.?\d*\s*kg\s*', '', desc_part2)
                    desc_part2 = desc_part2.strip()
                    
                    # Look at next line for continuation description
                    desc_part3 = ""
                    if i < len(lines):
                        next_line = lines[i].strip()
                        # If next line doesn't have SKU, it might be a continuation
                        if (next_line and 
                            not re.search(r'\d{4}\.\d{3}\.[A-Z]{2,3}', next_line) and
                            not next_line.startswith('•') and
                            not next_line.startswith('NOTE:') and
                            len(next_line) > 10 and
                            not re.search(r'Nominal Dimensions|in x|mm x', next_line)):
                            desc_part3 = next_line
                            i += 1  # Consume this line
                    
                    # Combine all parts
                    if desc_part3:
                        full_description = desc_part2 + " " + desc_part3
                    elif desc_part2:
                        full_description = desc_part2
                    else:
                        # If description is empty, reuse last description
                        # This happens when a product line has multiple SKUs with same description
                        full_description = last_description
                    
                    full_description = re.sub(r'\s+', ' ', full_description).strip()
                    
                    # Update last_description if we have a substantial one
                    if len(full_description) > 20:
                        last_description = full_description
                    
                    products.append({
                        'Description': full_description,
                        'SKU': sku,
                        'Price': price,
                        'Color': color,
                        'QR Code URL': ''
                    })
                    products_on_page += 1
            
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
        
        print(f"\n{'='*80}")
        print("Sample products (first 10):")
        print("="*80)
        for i, row in df.head(10).iterrows():
            print(f"\n{i+1}.")
            print(f"   Description: {row['Description']}")
            print(f"   SKU: {row['SKU']}")
            print(f"   Price: ${row['Price']}")
            print(f"   Color: {row['Color']}")
        
        df.to_csv(output_path, index=False)
        print(f"\n{'='*80}")
        print(f"✓ SUCCESS: Saved {len(df)} products to:")
        print(f"  {output_path}")
        print("="*80)
        print("\nNote: QR Code URL column is empty - QR codes would need to be")
        print("scanned manually or with specialized OCR tools.")


if __name__ == '__main__':
    main()
