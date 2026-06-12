#!/usr/bin/env python3
"""
Enhanced extraction with better description combination and QR code URL extraction.
"""

import pdfplumber
import re
import pandas as pd
from pathlib import Path
from PIL import Image
import io


def extract_qr_urls_from_images(page):
    """
    Try to extract QR code URLs from page images.
    Even without pyzbar, we can try to get image positions.
    """
    qr_info = []
    
    try:
        # Get images from the page
        images = page.images
        for img in images:
            # Store image position info (can be used to correlate with products)
            qr_info.append({
                'bbox': (img['x0'], img['top'], img['x1'], img['bottom']),
                'page': page.page_number
            })
    except Exception as e:
        pass
    
    return qr_info


def combine_description_parts(lines, index):
    """
    Combine multi-line descriptions by looking at the current and previous line.
    """
    current_line = lines[index].strip()
    
    # Check if previous line might be part of the description
    if index > 0:
        prev_line = lines[index - 1].strip()
        # If previous line is substantial and doesn't contain a price/SKU
        if (len(prev_line) > 20 and 
            not re.search(r'\d{4}\.\d{3}\.[A-Z]{2,3}', prev_line) and
            not re.search(r'\d{1,2},\d{3}$', prev_line) and
            not prev_line.startswith('•') and
            not re.search(r'\d+\s*lb|\d+\.?\d*\s*kg', prev_line)):
            return prev_line + " " + current_line
    
    return current_line


def extract_walkin_tub_data(pdf_path, start_page=62, end_page=81):
    """
    Extract walk-in tub data from specific pages with improved description handling.
    """
    products = []
    
    print(f"Opening catalog: {pdf_path}")
    print(f"Extracting pages {start_page} to {end_page}...")
    
    with pdfplumber.open(pdf_path) as pdf:
        total_pages = len(pdf.pages)
        print(f"Total pages in PDF: {total_pages}")
        
        for page_num in range(start_page - 1, min(end_page, total_pages)):
            page = pdf.pages[page_num]
            actual_page_num = page_num + 1
            
            print(f"\nProcessing page {actual_page_num}...")
            
            # Get QR code image positions
            qr_images = extract_qr_urls_from_images(page)
            print(f"  Found {len(qr_images)} images (potential QR codes)")
            
            # Extract text
            text = page.extract_text()
            if not text:
                print(f"  No text found on page {actual_page_num}")
                continue
            
            lines = text.split('\n')
            products_on_page = 0
            last_description_base = ""
            
            for i, line in enumerate(lines):
                line = line.strip()
                if not line:
                    continue
                
                # Skip feature bullet points and notes
                if line.startswith('•') or line.startswith('NOTE:') or line.startswith('*'):
                    last_description_base = ""
                    continue
                
                # Match SKU and price
                sku_match = re.search(r'\b(\d{4}\.\d{3}\.[A-Z]{2,3})\b', line)
                price_match = re.search(r'\b(\d{1,2},\d{3})\b$', line)
                color_match = re.search(r'\b(White|Linen|Bone|Biscuit|Almond)\b', line, re.IGNORECASE)
                
                if sku_match and price_match:
                    # This is a product data line
                    sku = sku_match.group(1)
                    price = price_match.group(1)
                    color = color_match.group(1).capitalize() if color_match else ""
                    
                    # Get description from this line
                    desc_current = line[:sku_match.start()].strip()
                    desc_current = re.sub(r'\d+\s*lb\s*', '', desc_current)
                    desc_current = re.sub(r'\d+\.?\d*\s*kg\s*', '', desc_current)
                    desc_current = desc_current.strip()
                    
                    # Combine with previous description if needed
                    if len(desc_current) < 20 and i > 0:
                        # Check previous line
                        prev_line = lines[i-1].strip() if i > 0 else ""
                        if (len(prev_line) > 20 and 
                            not re.search(r'\d{4}\.\d{3}\.[A-Z]{2,3}', prev_line) and
                            not re.search(r'\d{1,2},\d{3}$', prev_line) and
                            not prev_line.startswith('•')):
                            # Check if it's a continuation (same base description)
                            if last_description_base and prev_line.startswith(last_description_base[:20]):
                                description = prev_line
                            else:
                                description = prev_line + " " + desc_current if desc_current else prev_line
                                description = description.strip()
                        else:
                            description = desc_current
                    else:
                        description = desc_current
                        # Track base description for grouping
                        if len(description) > 30:
                            last_description_base = description
                    
                    # Clean up description
                    description = re.sub(r'\s+', ' ', description).strip()
                    
                    # Create product entry
                    product = {
                        'Description': description,
                        'SKU': sku,
                        'Price': price,
                        'Color': color,
                        'QR Code URL': '',  # To be filled manually or with additional processing
                        'Page': actual_page_num
                    }
                    products.append(product)
                    products_on_page += 1
            
            print(f"  Extracted {products_on_page} products from page {actual_page_num}")
    
    print(f"\n{'='*60}")
    print(f"Total products extracted: {len(products)}")
    return products


def save_to_csv(products, output_path):
    """Save extracted products to CSV."""
    if not products:
        print("No products to save!")
        return
    
    df = pd.DataFrame(products)
    
    # Reorder columns to match template
    columns = ['Description', 'SKU', 'Price', 'Color', 'QR Code URL']
    for col in columns:
        if col not in df.columns:
            df[col] = ''
    
    df = df[columns]
    
    # Remove the Page column if it exists
    if 'Page' in df.columns:
        df = df.drop('Page', axis=1)
    
    # Remove duplicates based on SKU
    df = df.drop_duplicates(subset=['SKU'], keep='first')
    
    print(f"\nSaving {len(df)} unique products to {output_path}")
    df.to_csv(output_path, index=False)
    print("Done!")
    
    return df


if __name__ == '__main__':
    # Paths
    catalog_path = '/Users/brentlichtenberg/Desktop/PSKU Project/American Standard Residential Product Catalog.pdf'
    output_path = '/Users/brentlichtenberg/Desktop/PSKU Project/WIT Options-2026-Populated.csv'
    
    # Extract data
    products = extract_walkin_tub_data(catalog_path, start_page=62, end_page=81)
    
    # Display sample
    if products:
        print("\n" + "="*60)
        print("Sample of extracted data (first 5 products):")
        print("="*60)
        for i, product in enumerate(products[:5], 1):
            print(f"\nProduct {i}:")
            for key, value in product.items():
                if key != 'Page':
                    print(f"  {key}: {value}")
    
    # Save to CSV
    df = save_to_csv(products, output_path)
    
    print(f"\n{'='*60}")
    print(f"CSV file created: {output_path}")
    print(f"Total rows: {len(df)}")
    print(f"\nNote: QR Code URLs need to be manually extracted from the PDF")
    print(f"or use advanced QR scanning tools.")
