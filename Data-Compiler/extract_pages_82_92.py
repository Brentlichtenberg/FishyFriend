#!/usr/bin/env python3
"""
Extract data from pages 82-92.
"""

import pdfplumber
import re
import pandas as pd


def extract_walkin_tub_data(pdf_path, start_page=82, end_page=92):
    products = []
    
    print(f'Extracting pages {start_page} to {end_page}...')
    
    with pdfplumber.open(pdf_path) as pdf:
        for page_num in range(start_page - 1, min(end_page, len(pdf.pages))):
            page = pdf.pages[page_num]
            actual_page_num = page_num + 1
            
            print(f'Processing page {actual_page_num}...', end=' ')
            
            text = page.extract_text()
            if not text:
                print('No text')
                continue
            
            lines = text.split('\n')
            products_on_page = 0
            last_description = ''
            i = 0
            
            while i < len(lines):
                line = lines[i].strip()
                i += 1
                
                if (not line or line.startswith('•') or line.startswith('NOTE:') or 
                    line.startswith('*') or 'Description Net Wt SKU Color List Price' in line or
                    line.startswith('Bathing') or line.startswith('Walk-In-Baths') or
                    re.search(r'Nominal Dimensions', line)):
                    continue
                
                sku_match = re.search(r'\b([A-Z]{2}\d{8}\.\d{3})\b', line)
                price_match = re.search(r'\b(\d{1,2},?\d{3})\s*$', line)
                color_match = re.search(r'\b(White|Linen|Bone|Biscuit|Almond)\b', line, re.IGNORECASE)
                
                if sku_match and price_match:
                    sku = sku_match.group(1)
                    price = price_match.group(1)
                    color = color_match.group(1).capitalize() if color_match else ''
                    
                    desc_part2 = line[:sku_match.start()].strip()
                    desc_part2 = re.sub(r'\d+\s*lb\s*', '', desc_part2)
                    desc_part2 = re.sub(r'\d+\.?\d*\s*kg\s*', '', desc_part2)
                    desc_part2 = desc_part2.strip()
                    
                    desc_part3 = ''
                    if i < len(lines):
                        next_line = lines[i].strip()
                        if (next_line and 
                            not re.search(r'\d{4}\.\d{3}\.[A-Z]{2,3}', next_line) and
                            not next_line.startswith('•') and
                            not next_line.startswith('NOTE:') and
                            len(next_line) > 10 and
                            not re.search(r'Nominal Dimensions|in x|mm x', next_line)):
                            desc_part3 = next_line
                            i += 1
                    
                    if desc_part3:
                        full_description = desc_part2 + ' ' + desc_part3
                    elif desc_part2:
                        full_description = desc_part2
                    else:
                        full_description = last_description
                    
                    full_description = re.sub(r'\s+', ' ', full_description).strip()
                    
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
            
            print(f'{products_on_page} products')
    
    return products


if __name__ == '__main__':
    catalog_path = '/Users/brentlichtenberg/Desktop/PSKU Project/American Standard Residential Product Catalog.pdf'
    products = extract_walkin_tub_data(catalog_path, start_page=82, end_page=92)
    
    if products:
        df = pd.DataFrame(products)
        df = df.drop_duplicates(subset=['SKU'], keep='first')
        
        output_path = '/Users/brentlichtenberg/Desktop/PSKU Project/WIT Options-2026-Pages82-92.csv'
        df.to_csv(output_path, index=False)
        
        print(f'\n{"="*70}')
        print(f'✓ Extracted {len(df)} products from pages 82-92')
        print(f'✓ Saved to: {output_path}')
        print("="*70)
        
        print(f'\nFirst 5 products:')
        for i, row in df.head(5).iterrows():
            print(f'\n{i+1}. {row["Description"]}')
            print(f'   SKU: {row["SKU"]} | Price: ${row["Price"]} | Color: {row["Color"]}')
    else:
        print('No products found')
