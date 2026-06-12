#!/usr/bin/env python3
"""Debug - Look at the exact line format"""

import pdfplumber

pdf_path = '/Users/brentlichtenberg/Desktop/PSKU Project/American Standard Residential Product Catalog.pdf'

with pdfplumber.open(pdf_path) as pdf:
    page = pdf.pages[61]  # Page 62 (0-indexed)
    text = page.extract_text()
    
    lines = text.split('\n')
    
    # Print lines around the product data
    for i, line in enumerate(lines[30:50], 30):
        print(f"Line {i}: |{line}|")
