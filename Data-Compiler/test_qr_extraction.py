#!/usr/bin/env python3
"""
Attempt to extract QR codes using opencv and qrcode detector.
"""

import pdfplumber
import cv2
import numpy as np
from PIL import Image
import io


def extract_qr_from_page(page):
    """Try to extract QR codes from a PDF page using OpenCV."""
    qr_urls = []
    
    try:
        # Convert page to image at high resolution
        img = page.to_image(resolution=300)
        pil_img = img.original
        
        # Convert PIL image to OpenCV format
        opencv_img = cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR)
        
        # Create QR code detector
        qr_detector = cv2.QRCodeDetector()
        
        # Detect and decode
        data, bbox, straight_qrcode = qr_detector.detectAndDecode(opencv_img)
        
        if data:
            qr_urls.append({'url': data, 'method': 'opencv'})
            print(f"    Found QR code: {data[:50]}...")
    
    except Exception as e:
        print(f"    Error extracting QR: {e}")
    
    return qr_urls


def test_qr_extraction(pdf_path, page_num=62):
    """Test QR extraction on a specific page."""
    print(f"Testing QR extraction on page {page_num}...")
    
    with pdfplumber.open(pdf_path) as pdf:
        page = pdf.pages[page_num - 1]
        qr_codes = extract_qr_from_page(page)
        
        if qr_codes:
            print(f"\n✓ Successfully extracted {len(qr_codes)} QR code(s):")
            for i, qr in enumerate(qr_codes, 1):
                print(f"  {i}. {qr['url']}")
        else:
            print("\n✗ No QR codes found")
            print("  QR codes might be:")
            print("  - Too low resolution")
            print("  - Embedded as vector graphics")
            print("  - Need manual extraction")


if __name__ == '__main__':
    catalog_path = '/Users/brentlichtenberg/Desktop/PSKU Project/American Standard Residential Product Catalog.pdf'
    test_qr_extraction(catalog_path, page_num=62)
