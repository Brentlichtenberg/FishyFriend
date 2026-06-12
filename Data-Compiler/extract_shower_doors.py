#!/usr/bin/env python3
"""
Extract shower door data from pages 82-92.
Different format than walk-in tubs.
"""

import pdfplumber
import re
import pandas as pd


def extract_shower_door_data(pdf_path, start_page=82, end_page=92):
    products = []
    
    print(f'Extracting shower door data from pages {start_page} to {end_page}...\n')
    
    with pdfplumber.open(pdf_path) as pdf:
        for page_num in range(start_page - 1, min(end_page, len(pdf.pages))):
            page = pdf.pages[page_num]
            actual_page_num = page_num + 1
            
            print(f'Page {actual_page_num}:', end=' ')
            
            text = page.extract_text()
            if not text:
                print('No text')
                continue
            
            lines = text.split('\n')
            products_on_page = 0
            i = 0
            last_full_description = ""
            
            while i < len(lines):
                line = lines[i].strip()
                i += 1
                
                # Skip headers, bullets, notes
                if (not line or line.startswith('•') or line.startswith('NOTE:') or 
                    line.startswith('*') or 'Description Net Wt SKU Color List Price' in line or
                    line.startswith('Shower and Tub Doors') or
                    re.search(r'Nominal Dimensions', line) or
                    re.search(r'americanstandard', line) or
                    re.search(r'List Price Guide', line)):
                    continue
                
                # Look for SKU pattern: AM followed by 8 digits, dot, 3 digits
                sku_match = re.search(r'\b(AM\d{8}\.\d{3})\b', line)
                
                # Look for price - appears right before the end (after color)
                price_match = re.search(r'\b(\d{1,2},?\d{3})\s*$', line)
                
                # Look for color
                color_match = re.search(r'\b(Brushed Nickel|Silver Shine|Matte Black|Silver|Chrome)\b', line, re.IGNORECASE)
                
                if sku_match and price_match:
                    # This is a product data line
                    sku = sku_match.group(1)
                    price = price_match.group(1)
                    color = color_match.group(1) if color_match else ''
                    
                    # Get description from line before SKU
                    desc_on_line = line[:sku_match.start()].strip()
                    
                    # Remove weight info
                    desc_on_line = re.sub(r'\d+\s*lb\s*', '', desc_on_line)
                    desc_on_line = re.sub(r'\d+\.?\d*\s*kg\s*', '', desc_on_line)
                    desc_on_line = desc_on_line.strip()
                    
                    # If there's a substantial description on this line, it's the full description
                    if len(desc_on_line) > 25:
                        description = desc_on_line
                        last_full_description = description
                    else:
                        # Otherwise, reuse the last full description (for color variants)
                        description = last_full_description
                    
                    description = re.sub(r'\s+', ' ', description).strip()
                    
                    products.append({
                        'Description': description,
                        'SKU': sku,
                        'Price': price,
                        'Color': color,
                        'QR Code URL': ''
                    })
                    products_on_page += 1
            
            print(f'{products_on_page} products')
    
    return products


if __name__ == '__main__':
    catalog_path = '/Users/brentlichtenberg/Desktop/PSKU Project/American Standard Residential Product Catalog.pdf'
    products = extract_shower_door_data(catalog_path, start_page=82, end_page=92)
    
    if products:
        df = pd.DataFrame(products)
        df = df.drop_duplicates(subset=['SKU'], keep='first')
        
        output_path = '/Users/brentlichtenberg/Desktop/PSKU Project/WIT Options-2026-Pages82-92.csv'
        df.to_csv(output_path, index=False)
        
        print(f'\n{"="*70}')
        print(f'✓ Extracted {len(df)} shower door products from pages 82-92')
        print(f'✓ Saved to: {output_path}')
        print("="*70)
        
        print(f'\nAll products:')
        for i, row in df.iterrows():
            print(f'\n{i+1}. {row["Description"]}')
            print(f'   SKU: {row["SKU"]} | Price: ${row["Price"]} | Color: {row["Color"]}')
    else:
        print('\nNo products found')
