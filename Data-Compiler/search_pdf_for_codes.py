#!/usr/bin/env python3
"""
Search PDF for specific product codes and extract nearby prices.
"""

import pdfplumber
import re
from pathlib import Path
import pandas as pd


def search_pdf_for_codes(pdf_path, codes_to_find):
    """Search PDF for specific codes and extract nearby prices."""
    print(f"Searching PDF for {len(codes_to_find)} product codes...")
    
    found_prices = {}
    
    with pdfplumber.open(pdf_path) as pdf:
        for page_num, page in enumerate(pdf.pages, 1):
            if page_num % 50 == 0:
                print(f"Searched {page_num}/{len(pdf.pages)} pages...")
            
            text = page.extract_text()
            if not text:
                continue
            
            # Check each code
            for code in codes_to_find:
                if code in found_prices:
                    continue  # Already found
                
                # Look for the code in the text
                if code in text or code.replace('.', '') in text:
                    # Extract surrounding context (200 chars)
                    idx = text.find(code)
                    if idx == -1:
                        idx = text.find(code.replace('.', ''))
                    
                    if idx != -1:
                        start = max(0, idx - 100)
                        end = min(len(text), idx + 100)
                        context = text[start:end]
                        
                        # Look for prices in context
                        prices = re.findall(r'\$\s*(\d+(?:,\d{3})*(?:\.\d{2})?)', context)
                        
                        if prices:
                            # Take the first reasonable price
                            for price_str in prices:
                                try:
                                    price = float(price_str.replace(',', ''))
                                    if 10 <= price <= 100000:
                                        found_prices[code] = price
                                        print(f"Found {code}: ${price} (page {page_num})")
                                        break
                                except:
                                    pass
    
    return found_prices


def main():
    # Load ASHS SKUs to get codes
    skus_file = Path.home() / "Desktop" / "ASHS SKUs.csv"
    skus_df = pd.read_csv(skus_file)
    
    # Get all codes from columns A and B
    codes = set()
    col_a = skus_df.iloc[:, 0].dropna().astype(str)
    col_b = skus_df.iloc[:, 1].dropna().astype(str)
    
    codes.update(col_a.values)
    codes.update(col_b.values)
    
    # Remove empty and invalid codes
    codes = {c for c in codes if c and c != 'nan' and len(c) > 3}
    
    print(f"Loaded {len(codes)} unique product codes from ASHS SKUs")
    
    # Search PDF
    pdf_path = Path.home() / "Desktop" / "PSKU Project" / "American Standard Residential Product Catalog.pdf"
    found_prices = search_pdf_for_codes(pdf_path, codes)
    
    print(f"\n\nFound prices for {len(found_prices)} products")
    
    # Save results
    output_file = Path(__file__).parent / "catalog_matched_prices.csv"
    if found_prices:
        df = pd.DataFrame(list(found_prices.items()), columns=['Product Code', 'Catalog Price'])
        df.to_csv(output_file, index=False)
        print(f"Saved to {output_file}")
    
    return found_prices


if __name__ == "__main__":
    main()
