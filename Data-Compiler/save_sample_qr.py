#!/usr/bin/env python3
"""
Save sample QR code images for manual inspection.
"""

import fitz
from PIL import Image
import io
import os


def save_sample_images(pdf_path, page_num=62, output_dir='/tmp/qr_samples'):
    """Save small images from a page for inspection."""
    os.makedirs(output_dir, exist_ok=True)
    
    doc = fitz.open(pdf_path)
    page = doc[page_num - 1]
    image_list = page.get_images(full=True)
    
    print(f"Extracting images from page {page_num}...")
    
    for img_index, img_info in enumerate(image_list):
        xref = img_info[0]
        base_image = doc.extract_image(xref)
        image_bytes = base_image["image"]
        
        img = Image.open(io.BytesIO(image_bytes))
        width, height = img.size
        
        # Save small square images
        if 25 <= width <= 70 and 25 <= height <= 70:
            filename = f"{output_dir}/page{page_num}_img{img_index+1}_{width}x{height}.png"
            img.save(filename)
            print(f"  Saved: {filename}")
    
    doc.close()
    print(f"\nImages saved to: {output_dir}")
    print("You can open these files to see if they're QR codes")


if __name__ == '__main__':
    catalog_path = '/Users/brentlichtenberg/Desktop/PSKU Project/American Standard Residential Product Catalog.pdf'
    save_sample_images(catalog_path, page_num=62)
