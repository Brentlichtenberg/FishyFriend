#!/usr/bin/env python3
"""
PDF Catalog Extractor
Extracts product information and prices from American Standard catalog PDF.
"""

import pdfplumber
import re
from pathlib import Path


class CatalogExtractor:
    def __init__(self, pdf_path):
        """
        Initialize the CatalogExtractor with PDF path.
        
        Args:
            pdf_path: Path to the catalog PDF file
        """
        self.pdf_path = pdf_path
        self.products = []
        
    def extract_products(self):
        """Extract product information from the PDF catalog."""
        print(f"Opening PDF: {self.pdf_path}")
        
        with pdfplumber.open(self.pdf_path) as pdf:
            print(f"Total pages: {len(pdf.pages)}")
            
            for page_num, page in enumerate(pdf.pages, 1):
                if page_num % 10 == 0:
                    print(f"Processing page {page_num}...")
                
                # Extract text from page
                text = page.extract_text()
                if text:
                    self._parse_page_text(text, page_num)
                
                # Try to extract tables
                tables = page.extract_tables()
                if tables:
                    for table in tables:
                        self._parse_table(table, page_num)
        
        print(f"\nTotal products extracted: {len(self.products)}")
        return self.products
    
    def _parse_page_text(self, text, page_num):
        """
        Parse text content to find products and prices.
        Looking for patterns like:
        - Product codes (numbers, dots, letters)
        - Prices ($ followed by numbers)
        """
        lines = text.split('\n')
        
        for i, line in enumerate(lines):
            # Look for price patterns - more flexible
            price_matches = re.findall(r'\$\s*(\d+(?:,\d{3})*(?:\.\d{2})?)', line)
            
            # Look for product codes (various formats)
            # Examples: 7018201.002, TU105740.002, 2848D09CLL, 1660774.002
            code_patterns = [
                r'\b\d{7}\.\d{3}\b',  # 7-digit.3-digit (7018201.002)
                r'\b[A-Z]{2}\d{6}\.\d{3}\b',  # 2-letter-6-digit.3-digit (TU105740.002)
                r'\b\d{4}[A-Z]\d{2}[A-Z]{3,4}\b',  # 4-digit-letter-2-digit-letters (2848D09CLL)
                r'\b\d{4}\.[A-Z]\d{1,2}[A-Z]?\.[A-Z]{2,4}\b',  # Dotted format (2848.D09.CLL)
                r'\b[A-Z]{2,3}\d{6}\.\d{3}\b',  # 2-3-letter-6-digit.3-digit
                r'\b\d{10,12}\b',  # Long numeric codes
                r'\b[A-Z]{1,2}\d{4,8}[A-Z]?\b',  # Mixed letter-number codes
            ]
            
            all_codes = []
            for pattern in code_patterns:
                code_matches = re.findall(pattern, line)
                all_codes.extend(code_matches)
            
            # Also look for context clues - lines with both product codes and prices
            if all_codes:
                # Look ahead and behind for prices
                context_lines = []
                for j in range(max(0, i-2), min(len(lines), i+3)):
                    context_lines.append(lines[j])
                context_text = ' '.join(context_lines)
                
                context_prices = re.findall(r'\$\s*(\d+(?:,\d{3})*(?:\.\d{2})?)', context_text)
                
                if context_prices:
                    for code in all_codes:
                        for price in context_prices:
                            try:
                                price_clean = float(price.replace(',', ''))
                                if 10 <= price_clean <= 100000:  # Reasonable range
                                    self.products.append({
                                        'code': code,
                                        'description': line.strip(),
                                        'price': price_clean,
                                        'page': page_num
                                    })
                            except:
                                pass
    
    def _parse_table(self, table, page_num):
        """Parse table data to extract products and prices."""
        if not table or len(table) < 2:
            return
        
        # Try to identify columns with product codes and prices
        for row in table[1:]:  # Skip header
            if not row:
                continue
            
            # Look for cells with product codes and prices
            price_cell = None
            code_cell = None
            
            for cell in row:
                if cell:
                    # Check for price
                    price_match = re.search(r'\$?\s*(\d+(?:,\d{3})*(?:\.\d{2})?)', str(cell))
                    if price_match and not code_cell:
                        try:
                            price_val = float(price_match.group(1).replace(',', ''))
                            if 10 <= price_val <= 100000:  # Reasonable price range
                                price_cell = price_val
                        except:
                            pass
                    
                    # Check for product code
                    if re.search(r'\d{4,}', str(cell)) and len(str(cell)) <= 30:
                        code_cell = str(cell).strip()
            
            if code_cell and price_cell:
                self.products.append({
                    'code': code_cell,
                    'description': ' '.join([str(c) for c in row if c]).strip(),
                    'price': price_cell,
                    'page': page_num
                })
    
    def get_product_dict(self):
        """
        Create a dictionary for fast product lookup.
        Key: product code (normalized), Value: price
        """
        product_dict = {}
        
        for product in self.products:
            code = product['code']
            # Store multiple normalized versions for better matching
            normalized_codes = [
                code,
                code.upper(),
                code.lower(),
                code.replace('.', ''),
                code.replace('-', ''),
                code.replace(' ', ''),
            ]
            
            for norm_code in normalized_codes:
                if norm_code not in product_dict:
                    product_dict[norm_code] = product['price']
        
        return product_dict
    
    def save_to_csv(self, output_file):
        """Save extracted products to CSV for review."""
        import pandas as pd
        
        if not self.products:
            print("No products to save!")
            return
        
        df = pd.DataFrame(self.products)
        df.to_csv(output_file, index=False)
        print(f"Saved {len(self.products)} products to {output_file}")


def main():
    """Test the extractor."""
    pdf_path = Path.home() / "Desktop" / "PSKU Project" / "American Standard Residential Product Catalog.pdf"
    
    if not pdf_path.exists():
        print(f"Error: {pdf_path} not found!")
        return
    
    extractor = CatalogExtractor(pdf_path)
    products = extractor.extract_products()
    
    # Save for review
    output_file = Path(__file__).parent / "catalog_products_extracted.csv"
    extractor.save_to_csv(output_file)
    
    # Show some examples
    print("\nSample products extracted:")
    for i, product in enumerate(products[:10]):
        print(f"{i+1}. Code: {product['code']}, Price: ${product['price']}, Page: {product['page']}")


if __name__ == "__main__":
    main()
