#!/usr/bin/env python3
"""
Extract embedded images from PDF pages using PyMuPDF.
"""

import fitz  # PyMuPDF
import cv2
import numpy as np
from PIL import Image
import io


def extract_images_from_page(pdf_path, page_num):
    """Extract all embedded images from a PDF page."""
    print(f"\nPage {page_num}:")
    
    doc = fitz.open(pdf_path)
    page = doc[page_num - 1]
    
    # Get list of images
    image_list = page.get_images(full=True)
    print(f"  Found {len(image_list)} embedded images")
    
    qr_codes = []
    
    for img_index, img_info in enumerate(image_list):
        xref = img_info[0]
        
        try:
            # Extract image
            base_image = doc.extract_image(xref)
            image_bytes = base_image["image"]
            image_ext = base_image["ext"]
            
            # Convert to PIL Image
            img = Image.open(io.BytesIO(image_bytes))
            print(f"    Image {img_index + 1}: {img.size[0]}x{img.size[1]} pixels, format: {image_ext}")
            
            # Convert to OpenCV format
            opencv_img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
            
            # Try to detect QR code
            qr_detector = cv2.QRCodeDetector()
            data, bbox, straight_qrcode = qr_detector.detectAndDecode(opencv_img)
            
            if data:
                print(f"      ✓ QR CODE FOUND: {data}")
                qr_codes.append(data)
            else:
                # Try grayscale
                gray = cv2.cvtColor(opencv_img, cv2.COLOR_BGR2GRAY)
                data, bbox, straight_qrcode = qr_detector.detectAndDecode(gray)
                if data:
                    print(f"      ✓ QR CODE FOUND (grayscale): {data}")
                    qr_codes.append(data)
        
        except Exception as e:
            print(f"    Error processing image {img_index + 1}: {e}")
    
    doc.close()
    return qr_codes


def scan_pages_for_images(pdf_path, start_page=62, end_page=65):
    """Scan a range of pages for embedded images and QR codes."""
    print("="*70)
    print(f"Extracting embedded images from pages {start_page}-{end_page}")
    print("="*70)
    
    all_qr_codes = {}
    
    for page_num in range(start_page, end_page + 1):
        qr_codes = extract_images_from_page(pdf_path, page_num)
        if qr_codes:
            all_qr_codes[page_num] = qr_codes
    
    print("\n" + "="*70)
    print("SUMMARY")
    print("="*70)
    if all_qr_codes:
        print(f"✓ Found QR codes on {len(all_qr_codes)} pages:")
        for page, codes in all_qr_codes.items():
            print(f"  Page {page}:")
            for code in codes:
                print(f"    - {code}")
    else:
        print("✗ No QR codes detected in embedded images")
    
    return all_qr_codes


if __name__ == '__main__':
    catalog_path = '/Users/brentlichtenberg/Desktop/PSKU Project/American Standard Residential Product Catalog.pdf'
    
    # Test on first few pages
    qr_codes = scan_pages_for_images(catalog_path, start_page=62, end_page=65)
