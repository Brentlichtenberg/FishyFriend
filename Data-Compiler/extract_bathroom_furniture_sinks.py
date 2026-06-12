#!/usr/bin/env python3
"""
Extract Bathroom Furniture and Bathroom Sinks data from pages 100-130
of American Standard Residential Product Catalog.

Output columns:
- Column A: Section title, Nominal Dimensions, Description, Separate Components, Required Components
- Net Wt
- SKU
- Color
- Price
- QR Code URL
"""

import pdfplumber
import pandas as pd
import re

def extract_bathroom_products(pdf_path, start_page, end_page, output_path):
    """
    Extract products from pages with the furniture/sinks format.
    
    Format pattern:
    - Product Title (e.g., "Studio® S Above Counter Sink Top with Center Hole Only")
    - Bullet points with features
    - "Nominal Dimensions:" followed by dimensions
    - "Description Net Wt SKU Color List Price" header
    - Product rows: Description | Net Wt (with lb/kg) | SKU | Color | Price
    - "Separate Components:" section (optional)
    - "Required Components:" section (optional)
    """
    
    products = []
    
    with pdfplumber.open(pdf_path) as pdf:
        for page_num in range(start_page - 1, end_page):
            page = pdf.pages[page_num]
            actual_page_num = page_num + 1
            print(f"\nProcessing page {actual_page_num}...")
            
            text = page.extract_text()
            if not text:
                continue
                
            lines = text.split('\n')
            
            current_product_title = ""
            current_nominal_dimensions = ""
            product_title_added = False
            in_description_section = False
            in_separate_components = False
            in_required_components = False
            
            for i, line in enumerate(lines):
                line = line.strip()
                
                # Skip empty lines and footers
                if not line or 'americanstandard-us.com' in line.lower() or 'list price guide' in line.lower():
                    continue
                
                # Skip navigation/section headers and mirrored text
                skip_lines = ['Bathroom Furniture', 'Furniture', 'Vanities', 'Bathroom Sinks', 
                             'Bathroom', 'Sinks', 'Pedestal Sinks', 'Pedestal', 'Above Counter',
                             'Drop-In', 'Under Counter', 'Wall-Hung', 'seitinaV', 'erutinruF',
                             'skniS', 'moorhtaB', 'latsedeP', 'Bowl Size:', 'Parts Program']
                if line in skip_lines or line.startswith('Bowl Size:'):
                    continue
                
                # Detect product title - clean line with ® or ™ that's not a bullet point
                is_title = (('®' in line or '™' in line) and 
                           not line.startswith('•') and 
                           not line.startswith('Nominal Dimensions') and
                           not line.startswith('Description') and
                           not line.startswith('Separate Components') and
                           not line.startswith('Required Components') and
                           not re.search(r'\b[0-9]{4,10}[.-][0-9A-Z.-]+\b', line) and
                           'Net Wt' not in line)
                
                if is_title:
                    current_product_title = line
                    product_title_added = False
                    in_description_section = False
                    in_separate_components = False
                    in_required_components = False
                    print(f"  Title: {current_product_title[:60]}...")
                    continue
                
                # Detect Nominal Dimensions
                if line.startswith('Nominal Dimensions'):
                    if i + 1 < len(lines):
                        current_nominal_dimensions = lines[i + 1].strip()
                    continue
                
                # Detect Description section header
                if 'Description' in line and 'Net Wt' in line and 'SKU' in line:
                    in_description_section = True
                    in_separate_components = False
                    in_required_components = False
                    continue
                
                # Detect Separate Components section
                if line == 'Separate Components:':
                    in_description_section = False
                    in_separate_components = True
                    in_required_components = False
                    continue
                
                # Detect Required Components section
                if line == 'Required Components:':
                    in_description_section = False
                    in_separate_components = False
                    in_required_components = True
                    continue
                
                # Extract product data rows
                if in_description_section or in_separate_components or in_required_components:
                    # Look for SKU
                    sku_match = re.search(r'\b([0-9]{4,10}[.-][0-9A-Z.-]+)\b', line)
                    
                    if sku_match:
                        sku = sku_match.group(1)
                        
                        # Extract price (last number in line)
                        price_match = re.search(r'\b(\d{1,2},?\d{3})\s*$', line)
                        if not price_match:
                            price_match = re.search(r'\b(\d{2,4})\s*$', line)
                        price = price_match.group(1) if price_match else ""
                        
                        # Extract color (word(s) between SKU and price)
                        color = ""
                        if price_match:
                            text_between = line[sku_match.end():price_match.start()].strip()
                            color = text_between
                        
                        # Extract weight (with lb or kg)
                        weight = ""
                        weight_match = re.search(r'(\d+(?:\.\d+)?\s*lb)', line[:sku_match.start()])
                        if weight_match:
                            weight = weight_match.group(1)
                        elif i > 0:
                            prev_line = lines[i-1].strip()
                            weight_match = re.search(r'(\d+(?:\.\d+)?\s*kg)', prev_line)
                            if weight_match:
                                weight = weight_match.group(1)
                        
                        # Extract description (text before weight or SKU)
                        description = ""
                        if weight_match:
                            description = line[:weight_match.start()].strip()
                        else:
                            description = line[:sku_match.start()].strip()
                        
                        # If description is short/empty, look at previous line(s)
                        if len(description) < 5 and i > 0:
                            prev_line = lines[i-1].strip()
                            # Check if it's a continuation line (not a section header)
                            if (prev_line and 
                                not prev_line.startswith('•') and
                                not prev_line.startswith('Nominal') and
                                not prev_line.endswith(':') and
                                not re.search(r'^\d+\.?\d*\s*kg\s*$', prev_line)):
                                description = prev_line
                        
                        # Add product title section if this is first Description entry
                        if in_description_section and not product_title_added and current_product_title:
                            products.append({
                                'Section': current_product_title,
                                'Net Wt': '',
                                'SKU': '',
                                'Color': '',
                                'Price': '',
                                'QR Code URL': ''
                            })
                            products.append({
                                'Section': '',
                                'Net Wt': '',
                                'SKU': '',
                                'Color': '',
                                'Price': '',
                                'QR Code URL': ''
                            })
                            if current_nominal_dimensions:
                                products.append({
                                    'Section': 'Nominal Dimensions',
                                    'Net Wt': '',
                                    'SKU': '',
                                    'Color': '',
                                    'Price': '',
                                    'QR Code URL': ''
                                })
                                products.append({
                                    'Section': current_nominal_dimensions,
                                    'Net Wt': '',
                                    'SKU': '',
                                    'Color': '',
                                    'Price': '',
                                    'QR Code URL': ''
                                })
                            products.append({
                                'Section': 'Description',
                                'Net Wt': '',
                                'SKU': '',
                                'Color': '',
                                'Price': '',
                                'QR Code URL': ''
                            })
                            product_title_added = True
                        
                        # Add section header for Separate/Required Components
                        if in_separate_components:
                            if not products or products[-1]['Section'] != 'Separate Components':
                                products.append({
                                    'Section': '',
                                    'Net Wt': '',
                                    'SKU': '',
                                    'Color': '',
                                    'Price': '',
                                    'QR Code URL': ''
                                })
                                products.append({
                                    'Section': 'Separate Components',
                                    'Net Wt': '',
                                    'SKU': '',
                                    'Color': '',
                                    'Price': '',
                                    'QR Code URL': ''
                                })
                        
                        if in_required_components:
                            if not products or products[-1]['Section'] != 'Required Components':
                                products.append({
                                    'Section': '',
                                    'Net Wt': '',
                                    'SKU': '',
                                    'Color': '',
                                    'Price': '',
                                    'QR Code URL': ''
                                })
                                products.append({
                                    'Section': 'Required Components',
                                    'Net Wt': '',
                                    'SKU': '',
                                    'Color': '',
                                    'Price': '',
                                    'QR Code URL': ''
                                })
                        
                        # Add the product row
                        products.append({
                            'Section': description,
                            'Net Wt': weight,
                            'SKU': sku,
                            'Color': color,
                            'Price': price,
                            'QR Code URL': ''
                        })
                        
                        print(f"    {sku} - {description[:40]}... | ${price} | {color} | {weight}")
    
    # Create DataFrame
    df = pd.DataFrame(products)
    
    # Save to CSV
    df.to_csv(output_path, index=False)
    
    print(f"\n{'='*70}")
    print(f"✓ Extracted {len(products)} entries from pages {start_page}-{end_page}")
    print(f"✓ Saved to: {output_path}")
    print(f"{'='*70}")
    
    return df

if __name__ == "__main__":
    pdf_path = "/Users/brentlichtenberg/Desktop/PSKU Project/American Standard Residential Product Catalog.pdf"
    output_path = "/Users/brentlichtenberg/Desktop/PSKU Project/BRL Options-2026-Populated.csv"
    
    print("Extracting Bathroom Furniture and Bathroom Sinks from pages 100-130...")
    
    df = extract_bathroom_products(pdf_path, 100, 130, output_path)
    
    print(f"\nFirst 20 entries:")
    for idx, row in df.head(20).iterrows():
        if row['SKU']:
            print(f"{idx+1}. {row['SKU']} - {row['Section'][:50]}... | ${row['Price']} | {row['Color']} | {row['Net Wt']}")
        else:
            print(f"{idx+1}. [{row['Section'][:60]}...]")
