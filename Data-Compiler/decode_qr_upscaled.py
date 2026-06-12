#!/usr/bin/env python3
"""
Extract small images (likely QR codes) and upscale them for detection.
"""

import fitz  # PyMuPDF
import cv2
import numpy as np
from PIL import Image
import io


def extract_and_decode_small_images(pdf_path, page_num, min_size=25, max_size=70):
    """
    Extract small square images (likely QR codes) and try to decode them.
    """
    print(f"\nPage {page_num}:")
    
    doc = fitz.open(pdf_path)
    page = doc[page_num - 1]
    
    image_list = page.get_images(full=True)
    print(f"  Found {len(image_list)} embedded images")
    
    qr_codes = []
    
    for img_index, img_info in enumerate(image_list):
        xref = img_info[0]
        
        try:
            base_image = doc.extract_image(xref)
            image_bytes = base_image["image"]
            
            img = Image.open(io.BytesIO(image_bytes))
            width, height = img.size
            
            # Look for small square images (likely QR codes)
            if (min_size <= width <= max_size and 
                min_size <= height <= max_size and 
                abs(width - height) <= 5):  # Roughly square
                
                print(f"    Potential QR code: Image {img_index + 1} ({width}x{height})")
                
                # Upscale the image significantly
                scale_factor = 10
                new_size = (width * scale_factor, height * scale_factor)
                img_upscaled = img.resize(new_size, Image.NEAREST)  # NEAREST preserves QR patterns
                
                # Convert to OpenCV
                opencv_img = cv2.cvtColor(np.array(img_upscaled), cv2.COLOR_RGB2BGR)
                
                # Try QR detection
                qr_detector = cv2.QRCodeDetector()
                data, bbox, straight_qrcode = qr_detector.detectAndDecode(opencv_img)
                
                if data:
                    print(f"      ✓ QR CODE DECODED: {data}")
                    qr_codes.append(data)
                else:
                    # Try with even more upscaling
                    img_upscaled2 = img.resize((width * 20, height * 20), Image.NEAREST)
                    opencv_img2 = cv2.cvtColor(np.array(img_upscaled2), cv2.COLOR_RGB2BGR)
                    data, bbox, straight_qrcode = qr_detector.detectAndDecode(opencv_img2)
                    
                    if data:
                        print(f"      ✓ QR CODE DECODED (20x scale): {data}")
                        qr_codes.append(data)
                    else:
                        # Try thresholding
                        gray = cv2.cvtColor(opencv_img, cv2.COLOR_BGR2GRAY)
                        _, binary = cv2.threshold(gray, 128, 255, cv2.THRESH_BINARY)
                        data, bbox, straight_qrcode = qr_detector.detectAndDecode(binary)
                        
                        if data:
                            print(f"      ✓ QR CODE DECODED (binary): {data}")
                            qr_codes.append(data)
                        else:
                            print(f"      ✗ Could not decode")
        
        except Exception as e:
            print(f"    Error processing image {img_index + 1}: {e}")
    
    doc.close()
    return qr_codes


def scan_all_pages(pdf_path, start_page=62, end_page=81):
    """Scan all pages for QR codes."""
    print("="*70)
    print(f"Scanning pages {start_page}-{end_page} for QR codes")
    print("="*70)
    
    all_qr_codes = {}
    
    for page_num in range(start_page, end_page + 1):
        qr_codes = extract_and_decode_small_images(pdf_path, page_num)
        if qr_codes:
            all_qr_codes[page_num] = qr_codes
    
    print("\n" + "="*70)
    print("RESULTS")
    print("="*70)
    if all_qr_codes:
        print(f"✓ Found QR codes on {len(all_qr_codes)} pages:\n")
        for page, codes in sorted(all_qr_codes.items()):
            print(f"Page {page}:")
            for i, code in enumerate(codes, 1):
                print(f"  {i}. {code}")
            print()
    else:
        print("✗ No QR codes could be decoded")
        print("\nPossible reasons:")
        print("  - QR codes may be vector graphics (not raster images)")
        print("  - Images may be too degraded to decode")
        print("  - May require manual scanning")
    
    return all_qr_codes


if __name__ == '__main__':
    catalog_path = '/Users/brentlichtenberg/Desktop/PSKU Project/American Standard Residential Product Catalog.pdf'
    
    # Test on first page
    print("Testing on page 62...")
    qr_codes = extract_and_decode_small_images(catalog_path, 62)
    
    if qr_codes:
        print(f"\n✓ SUCCESS! Found {len(qr_codes)} QR code(s)")
        print("\nScanning all pages...")
        all_codes = scan_all_pages(catalog_path, start_page=62, end_page=81)
    else:
        print("\n✗ No QR codes decoded on test page")
        print("Proceeding to scan all pages anyway...")
        all_codes = scan_all_pages(catalog_path, start_page=62, end_page=81)
