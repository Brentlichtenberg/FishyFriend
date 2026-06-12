#!/usr/bin/env python3
"""
Comprehensive extraction - get ALL products from pages 82-92.
"""

import pdfplumber
import re
import pandas as pd


def extract_all_shower_products(pdf_path, start_page=82, end_page=92):
    products = []
    
    print(f'Extracting ALL products from pages {start_page} to {end_page}...\n')
    
    with pdfplumber.open(pdf_path) as pdf:
        for page_num in range(start_page - 1, min(end_page, len(pdf.pages))):
            page = pdf.pages[page_num - 1]
            actual_page_num = page_num + 1
            
            text = page.extract_text()
            if not text:
                continue
            
            lines = text.split('\n')
            products_on_page = 0
            last_full_description = ""
            
            for i, line in enumerate(lines):
                line = line.strip()
                
                # Skip headers
                if (not line or line.startswith('•') or line.startswith('NOTE:') or 
                    'Description Net Wt SKU Color List Price' in line or
                    line.startswith('Shower and Tub Doors') or
                    re.search(r'Nominal Dimensions|List Price Guide|americanstandard', line)):
                    continue
                
                # Look for SKU and price
                sku_match = re.search(r'\b(AM\d{8}\.\d{3})\b', line)
                # Price can be 3 digits (983) or 4+ with comma (1,183)
                price_match = re.search(r'\b(\d{3,4}(?:,\d{3})?)\s*$', line)
                color_match = re.search(r'\b(Brushed Nickel|Silver Shine|Matte Black|Silver|Chrome)\b', line, re.IGNORECASE)
                
                if sku_match and price_match:
                    sku = sku_match.group(1)
                    price = price_match.group(1)
                    color = color_match.group(1) if color_match else ''
                    
                    # Get description from current line
                    desc_part = line[:sku_match.start()].strip()
                    desc_part = re.sub(r'\d+\s*lb\s*', '', desc_part)
                    desc_part = re.sub(r'\d+\.?\d*\s*kg\s*', '', desc_part)
                    desc_part = desc_part.strip()
                    
                    # Check for continuation line
                    continuation = ""
                    if i + 1 < len(lines):
                        next_line = lines[i + 1].strip()
                        if (next_line and 
                            not re.search(r'AM\d{8}', next_line) and
                            not next_line.startswith('•') and
                            len(next_line) > 3 and
                            not re.search(r'\d{3,4}(?:,\d{3})?\s*$', next_line) and
                            not re.search(r'Nominal Dimensions', next_line)):
                            if len(next_line) < 50:
                                continuation = next_line
                    
                    # Build full description
                    if desc_part and continuation:
                        full_desc = desc_part + " " + continuation
                    elif desc_part:
                        full_desc = desc_part
                    elif continuation:
                        full_desc = continuation
                    else:
                        full_desc = ""
                    
                    # Clean up
                    full_desc = re.sub(r'\d+\.?\d*\s*kg\s*', '', full_desc)
                    full_desc = re.sub(r'\d+\s*lb\s*', '', full_desc)
                    full_desc = re.sub(r'\s+', ' ', full_desc).strip()
                    
                    # Determine final description
                    if len(full_desc) > 25:
                        description = full_desc
                        last_full_description = description
                    elif last_full_description:
                        description = last_full_description
                    else:
                        description = full_desc
                    
                    products.append({
                        'Description': description,
                        'SKU': sku,
                        'Price': price,
                        'Color': color,
                        'Page': actual_page_num,
                        'QR Code URL': ''
                    })
                    products_on_page += 1
            
            if products_on_page > 0:
                print(f'Page {actual_page_num}: {products_on_page} products')
    
    return products


if __name__ == '__main__':
    catalog_path = '/Users/brentlichtenberg/Desktop/PSKU Project/American Standard Residential Product Catalog.pdf'
    products = extract_all_shower_products(catalog_path, start_page=82, end_page=92)
    
    if products:
        df = pd.DataFrame(products)
        df = df.drop_duplicates(subset=['SKU'], keep='first')
        
        output_path = '/Users/brentlichtenberg/Desktop/PSKU Project/WIT Options-2026-Pages82-92.csv'
        df.to_csv(output_path, index=False)
        
        print(f'\n{"="*70}')
        print(f'✓ Extracted {len(df)} products from pages 82-92')
        print(f'✓ Saved to: {output_path}')
        print("="*70)
        
        print(f'\nFirst 15 products:')
        for i, row in df.head(15).iterrows():
            print(f'{i+1}. {row["SKU"]} - {row["Description"][:45]}... | ${row["Price"]} | {row["Color"]} | Page {row["Page"]}')
        
        if len(df) > 15:
            print(f'\n... and {len(df) - 15} more products')
    else:
        print('\nNo products found')
