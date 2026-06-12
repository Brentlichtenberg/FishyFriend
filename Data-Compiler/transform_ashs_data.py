#!/usr/bin/env python3
"""
Transform ASHS Supplied.csv data to match the Template-WiT PSKU Margins.csv format.
Preserves category dividers (text string entries in column A).
"""

import csv
import os

# Input and output file paths
INPUT_FILE = "/Users/brentlichtenberg/Desktop/PSKU Project/ASHS Supplied.csv"
OUTPUT_FILE = "/Users/brentlichtenberg/Desktop/PSKU Project/All_Products_Margins_Incomplete.csv"

# Output column headers matching the template
OUTPUT_HEADERS = [
    "SKU",
    "Display Name", 
    "Feature Group",
    "Consumer Cost",
    "Product Name",
    "Dealer Cost Estimate",
    "Margin Estimate Amount",
    "Margin Estimate Percentage"
]

def is_category_divider(row):
    """
    Determine if a row is a category divider.
    Category dividers have text in column 0 but mostly empty subsequent columns,
    or have descriptive text that doesn't look like product data.
    """
    if not row or len(row) == 0 or not row[0].strip():
        return False
    
    col_0 = row[0].strip()
    
    # Skip if it's empty
    if not col_0:
        return False
    
    # If columns 1-3 are all empty or very sparse, it's likely a category header
    subsequent_cols = [row[i].strip() if i < len(row) else "" for i in range(1, 4)]
    
    # Check if all subsequent columns are empty
    if all(not col for col in subsequent_cols):
        return True
    
    # Check if it looks like "Category Name" with trailing commas
    # or if SAP_ProductID column is empty but others might have generic text
    if len(row) > 1 and not row[1].strip() and "," in col_0:
        return True
        
    # Additional heuristics: common category patterns
    category_keywords = [
        "WIT", "TOILET", "BIDET", "ACCESSORIES", "WALLS", "BATH REMODEL",
        "BATHTUBS", "SHOWER", "PANS", "DRAINS", "MOLDING", "CADDIES",
        "SHELVES", "PODS", "BASKETS", "CURTAIN", "RODS", "BRACKETS",
        "DOORS", "BYPASS", "PIVOT", "SLIDER", "BARN", "OVERSIZED",
        "NEO-ANGLE", "PALLETS", "SAFETY BARS", "SEATS", "KERDI",
        "TRIM", "CORNERS", "CONNECTORS", "CEILING", "TAPE", "ACRYLIC",
        "SOLID SURFACE", "PENCIL", "WINDOW KITS", "MOMENT", "SILICONE",
        "ADHESIVE", "REINFORCEMENT", "ROUGH IN", "HANDSHOWERS",
        "REPAIR KITS", "TRIMMABLE", "BASE"
    ]
    
    col_0_upper = col_0.upper()
    if any(keyword in col_0_upper for keyword in category_keywords):
        # Additional check: if it has no SAP_ProductID, it's likely a category
        if len(row) > 1 and not row[1].strip():
            return True
    
    return False

def transform_row(row):
    """
    Transform a data row from input format to output format.
    Input columns: [SKU, SAP_ProductID, LongDescr, Manufacturer, ...]
    Output columns: [SKU, Display Name, Feature Group, Consumer Cost, Product Name, 
                     Dealer Cost Estimate, Margin Estimate Amount, Margin Estimate Percentage]
    """
    if is_category_divider(row):
        # For category dividers, only include the category name in SKU column
        return [row[0].strip(), "", "", "", "", "", "", ""]
    
    # For product rows
    sku = row[0].strip() if len(row) > 0 else ""
    sap_product_id = row[1].strip() if len(row) > 1 else ""
    long_descr = row[2].strip() if len(row) > 2 else ""
    manufacturer = row[3].strip() if len(row) > 3 else ""
    
    # Skip completely empty rows
    if not sku and not sap_product_id and not long_descr:
        return None
    
    # Map to output format:
    # - SKU -> SKU
    # - Long Description -> Display Name
    # - Manufacturer -> Feature Group
    # - Long Description -> Product Name (can be same as Display Name)
    # - Leave cost and margin columns empty for now
    
    display_name = long_descr
    feature_group = manufacturer
    product_name = long_descr
    
    return [
        sku,
        display_name,
        feature_group,
        "",  # Consumer Cost
        product_name,
        "",  # Dealer Cost Estimate
        "",  # Margin Estimate Amount
        ""   # Margin Estimate Percentage
    ]

def main():
    print(f"Reading from: {INPUT_FILE}")
    print(f"Writing to: {OUTPUT_FILE}")
    
    # Read input file and transform
    output_rows = []
    
    with open(INPUT_FILE, 'r', encoding='utf-8') as infile:
        reader = csv.reader(infile)
        
        # Skip the first 3 header rows
        for _ in range(3):
            try:
                next(reader)
            except StopIteration:
                break
        
        # Process data rows
        row_count = 0
        category_count = 0
        product_count = 0
        
        for row in reader:
            # Skip empty rows
            if not row or all(not cell.strip() for cell in row):
                continue
            
            # Transform the row
            transformed = transform_row(row)
            
            if transformed:
                output_rows.append(transformed)
                row_count += 1
                
                if is_category_divider(row):
                    category_count += 1
                else:
                    product_count += 1
    
    # Write output file
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    
    with open(OUTPUT_FILE, 'w', encoding='utf-8', newline='') as outfile:
        writer = csv.writer(outfile)
        
        # Write header
        writer.writerow(OUTPUT_HEADERS)
        writer.writerow([""] * len(OUTPUT_HEADERS))  # Empty row after header
        
        # Write transformed data
        writer.writerows(output_rows)
    
    print(f"\nTransformation complete!")
    print(f"Total rows processed: {row_count}")
    print(f"Category dividers: {category_count}")
    print(f"Product rows: {product_count}")
    print(f"\nOutput saved to: {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
