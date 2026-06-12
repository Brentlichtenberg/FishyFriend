#!/usr/bin/env python3
"""
Examine the content of pages 62-81 to understand the structure.
"""

import pdfplumber
from pathlib import Path

def examine_pages(pdf_path, start_page=62, end_page=65):
    """Examine a few pages to understand the structure."""
    
    print(f"Opening catalog: {pdf_path}")
    
    with pdfplumber.open(pdf_path) as pdf:
        for page_num in range(start_page - 1, min(end_page, len(pdf.pages))):
            page = pdf.pages[page_num]
            actual_page_num = page_num + 1
            
            print(f"\n{'='*80}")
            print(f"PAGE {actual_page_num}")
            print(f"{'='*80}")
            
            # Extract text
            text = page.extract_text()
            if text:
                print("\n--- TEXT CONTENT ---")
                print(text[:2000])  # First 2000 chars
            
            # Extract tables
            tables = page.extract_tables()
            if tables:
                print(f"\n--- FOUND {len(tables)} TABLES ---")
                for i, table in enumerate(tables, 1):
                    print(f"\nTable {i} (first 5 rows):")
                    for row in table[:5]:
                        print(row)
            
            # Check for images
            if hasattr(page, 'images'):
                print(f"\n--- FOUND {len(page.images)} IMAGES ---")

if __name__ == '__main__':
    catalog_path = '/Users/brentlichtenberg/Desktop/PSKU Project/American Standard Residential Product Catalog.pdf'
    examine_pages(catalog_path, start_page=86, end_page=92)
