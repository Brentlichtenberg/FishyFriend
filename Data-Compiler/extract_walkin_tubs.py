#!/usr/bin/env python3
"""
Extract Walk-in Tub data from American Standard catalog pages 62-81.
Extracts: Description, SKU, Price, Color, and QR Code URLs
"""

import pdfplumber
import re
import pandas as pd
from pathlib import Path
from PIL import Image
import io

try:
    from pyzbar import pyzbar
    PYZBAR_AVAILABLE = True
except ImportError:
    PYZBAR_AVAILABLE = False
    print("Warning: pyzbar not available. QR code extraction will be limited.")


def extract_qr_codes_from_page(page):
    """Extract QR codes from a PDF page."""
    qr_urls = []
    
    if not PYZBAR_AVAILABLE:
        return qr_urls
    
    try:
        # Convert page to image
        img = page.to_image(resolution=300)
        pil_img = img.original
        
        # Decode QR codes
        decoded_objects = pyzbar.decode(pil_img)
        
        for obj in decoded_objects:
            if obj.type == 'QRCODE':
                url = obj.data.decode('utf-8')
                qr_urls.append({
                    'url': url,
                    'position': obj.rect
                })
    except Exception as e:
        print(f"Error extracting QR codes: {e}")
    
    return qr_urls


def extract_walkin_tub_data(pdf_path, start_page=62, end_page=81):
    """
    Extract walk-in tub data from specific pages.
    Returns list of products with Description, SKU, Price, Color, and QR URL.
    """
    products = []
    
    print(f"Opening catalog: {pdf_path}")
    print(f"Extracting pages {start_page} to {end_page}...")
    
    with pdfplumber.open(pdf_path) as pdf:
        total_pages = len(pdf.pages)
        print(f"Total pages in PDF: {total_pages}")
        
        # Adjust page numbers (PDF is 0-indexed)
        for page_num in range(start_page - 1, min(end_page, total_pages)):
            page = pdf.pages[page_num]
            actual_page_num = page_num + 1
            
            print(f"\nProcessing page {actual_page_num}...")
            
            # Extract QR codes first
            qr_codes = extract_qr_codes_from_page(page)
            print(f"  Found {len(qr_codes)} QR codes")
            
            # Extract text
            text = page.extract_text()
            if not text:
                print(f"  No text found on page {actual_page_num}")
                continue
            
            # Parse the text line by line
            lines = text.split('\n')
            
            # Track the current description being built
            current_description = ""
            products_on_page = 0
            
            for i, line in enumerate(lines):
                line = line.strip()
                if not line:
                    continue
                
                # Skip feature bullet points and notes
                if line.startswith('•') or line.startswith('NOTE:') or line.startswith('*'):
                    current_description = ""
                    continue
                
                # Look for lines with product data
                # Pattern: SKU Color Price at the end of the line
                # Format examples:
                # "Description 3060.109.SLL Linen 10,207"
                # "141 lb 3060.109.SLW White 10,207"
                
                # Match SKU pattern (e.g., 3060.109.SLL)
                sku_match = re.search(r'\b(\d{4}\.\d{3}\.[A-Z]{2,3})\b', line)
                
                # Match price pattern (e.g., 10,207 or 8,834) - must have comma
                price_match = re.search(r'\b(\d{1,2},\d{3})\b$', line)
                
                # Match color
                color_match = re.search(r'\b(White|Linen|Bone|Biscuit|Almond)\b', line, re.IGNORECASE)
                
                if sku_match and price_match:
                    # This is a product data line
                    sku = sku_match.group(1)
                    price = price_match.group(1)
                    color = color_match.group(1).capitalize() if color_match else ""
                    
                    # Find the description - it's before the SKU
                    desc_part = line[:sku_match.start()].strip()
                    
                    # Remove weight info (lb/kg patterns) from description
                    desc_part = re.sub(r'\d+\s*lb\s*', '', desc_part)
                    desc_part = re.sub(r'\d+\.?\d*\s*kg\s*', '', desc_part)
                    desc_part = desc_part.strip()
                    
                    # If description is too short or empty, use accumulated description
                    if len(desc_part) < 15 and current_description:
                        # Combine with previous line(s)
                        description = current_description.strip() + " " + desc_part.strip()
                        description = description.strip()
                        current_description = ""
                    elif len(desc_part) < 15:
                        # Look ahead to next line for continuation
                        if i + 1 < len(lines):
                            next_line = lines[i + 1].strip()
                            # If next line doesn't have SKU, it's likely part of description
                            if not re.search(r'\d{4}\.\d{3}\.[A-Z]{2,3}', next_line):
                                description = desc_part
                            else:
                                description = desc_part
                        else:
                            description = desc_part
                    else:
                        description = desc_part
                    
                    # Clean up description
                    description = re.sub(r'\s+', ' ', description).strip()
                    
                    # Create product entry
                    product = {
                        'Description': description,
                        'SKU': sku,
                        'Price': price,
                        'Color': color,
                        'QR Code URL': '',  # Will be filled if QR codes detected
                        'Page': actual_page_num
                    }
                    products.append(product)
                    products_on_page += 1
                    current_description = ""
                    
                elif len(line) > 25 and not sku_match:
                    # This might be a description line, accumulate it
                    # But not if it's a dimension line or feature list
                    if not re.search(r'\d+\s*in\s*x\s*\d+\s*in', line) and not re.search(r'Nominal Dimensions', line):
                        current_description = line
            
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
    
    # Remove duplicates
    df = df.drop_duplicates(subset=['SKU'], keep='first')
    
    print(f"\nSaving {len(df)} unique products to {output_path}")
    df.to_csv(output_path, index=False)
    print("Done!")


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
                print(f"  {key}: {value}")
    
    # Save to CSV
    save_to_csv(products, output_path)
