#!/usr/bin/env python3
"""
Extract QR codes from PDF using PyMuPDF (high-resolution rendering) + OpenCV.
"""

import fitz  # PyMuPDF
import cv2
import numpy as np
from PIL import Image
import pandas as pd


def extract_qr_codes_from_page(pdf_path, page_num, dpi=300):
    """
    Render a PDF page at high resolution and extract QR codes.
    
    Args:
        pdf_path: Path to PDF file
        page_num: Page number (1-indexed)
        dpi: Resolution for rendering (higher = better QR detection)
    
    Returns:
        List of QR code URLs found on the page
    """
    qr_codes = []
    
    try:
        doc = fitz.open(pdf_path)
        page = doc[page_num - 1]  # PyMuPDF uses 0-indexed pages
        
        # Calculate zoom factor for desired DPI
        zoom = dpi / 72  # PDF default is 72 DPI
        mat = fitz.Matrix(zoom, zoom)
        
        # Render page to pixmap
        pix = page.get_pixmap(matrix=mat)
        
        # Convert to PIL Image
        img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
        
        # Convert to OpenCV format
        opencv_img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
        
        # Try OpenCV QRCodeDetector
        qr_detector = cv2.QRCodeDetector()
        data, bbox, straight_qrcode = qr_detector.detectAndDecode(opencv_img)
        
        if data:
            qr_codes.append(data)
            print(f"  ✓ Found QR code: {data[:60]}...")
        
        # Also try with grayscale
        if not data:
            gray = cv2.cvtColor(opencv_img, cv2.COLOR_BGR2GRAY)
            data, bbox, straight_qrcode = qr_detector.detectAndDecode(gray)
            if data:
                qr_codes.append(data)
                print(f"  ✓ Found QR code (grayscale): {data[:60]}...")
        
        doc.close()
        
    except Exception as e:
        print(f"  ✗ Error on page {page_num}: {e}")
    
    return qr_codes


def extract_all_qr_codes(pdf_path, start_page=62, end_page=81):
    """Extract QR codes from all pages in range."""
    print(f"Extracting QR codes from pages {start_page}-{end_page}...")
    print(f"Using high-resolution rendering (300 DPI)...\n")
    
    qr_by_page = {}
    
    for page_num in range(start_page, end_page + 1):
        print(f"Page {page_num}:", end=" ")
        qr_codes = extract_qr_codes_from_page(pdf_path, page_num, dpi=300)
        
        if qr_codes:
            qr_by_page[page_num] = qr_codes
        else:
            print("  No QR codes found")
    
    return qr_by_page


def update_csv_with_qr_codes(csv_path, qr_by_page):
    """Update the CSV file with extracted QR code URLs."""
    df = pd.read_csv(csv_path)
    
    print(f"\n{'='*70}")
    print(f"Updating CSV with QR codes...")
    print(f"{'='*70}")
    
    # If we have QR codes, try to map them to products
    # For now, let's see what we found
    if qr_by_page:
        print(f"\nQR codes found on {len(qr_by_page)} pages:")
        for page, codes in qr_by_page.items():
            print(f"  Page {page}: {len(codes)} QR code(s)")
            for code in codes:
                print(f"    - {code}")
    else:
        print("\nNo QR codes were automatically detected.")
        print("This could mean:")
        print("  1. QR codes are too small or low quality")
        print("  2. They require even higher resolution")
        print("  3. Manual scanning is needed")
    
    return df


if __name__ == '__main__':
    catalog_path = '/Users/brentlichtenberg/Desktop/PSKU Project/American Standard Residential Product Catalog.pdf'
    csv_path = '/Users/brentlichtenberg/Desktop/PSKU Project/WIT Options-2026-Populated.csv'
    
    # First, test on just one page
    print("="*70)
    print("Testing QR extraction on page 62...")
    print("="*70)
    qr_codes = extract_qr_codes_from_page(catalog_path, 62, dpi=400)
    
    if qr_codes:
        print(f"\n✓ SUCCESS! Found {len(qr_codes)} QR code(s) on page 62")
        print("\nProceeding to extract from all pages...")
        qr_by_page = extract_all_qr_codes(catalog_path, start_page=62, end_page=81)
        df = update_csv_with_qr_codes(csv_path, qr_by_page)
    else:
        print("\n✗ No QR codes found on test page.")
        print("\nTrying even higher resolution (600 DPI)...")
        qr_codes = extract_qr_codes_from_page(catalog_path, 62, dpi=600)
        
        if qr_codes:
            print(f"\n✓ SUCCESS at 600 DPI!")
            qr_by_page = extract_all_qr_codes(catalog_path, start_page=62, end_page=81)
            df = update_csv_with_qr_codes(csv_path, qr_by_page)
        else:
            print("\n✗ Still no QR codes detected.")
            print("\nRecommendation: Manual extraction required.")
            print("  - Try scanning with mobile device camera")
            print("  - Or use Adobe Acrobat to export graphics")
