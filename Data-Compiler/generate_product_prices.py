#!/usr/bin/env python3
"""
Generate product prices for All_Products_Margins_DEMO.csv
Uses WiT_Margins_Complete data for walk-in tubs and creates estimates for other products
based on industry-standard pricing patterns.
"""

import csv
import re
from typing import Dict, Optional, Tuple

# File paths
INCOMPLETE_FILE = "/Users/brentlichtenberg/Desktop/PSKU Project/All_Products_Margins_Incomplete.csv"
WIT_COMPLETE_FILE = "/Users/brentlichtenberg/Desktop/PSKU Project/WiT_Margins_Complete.csv"
OUTPUT_FILE = "/Users/brentlichtenberg/Desktop/PSKU Project/All_Product_Margins_DEMO.csv"

# Load WiT pricing data
def load_wit_prices() -> Dict[str, Dict[str, str]]:
    """Load pricing data from WiT_Margins_Complete.csv"""
    wit_prices = {}
    
    with open(WIT_COMPLETE_FILE, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            sku = row['SKU'].strip()
            if sku:
                wit_prices[sku] = {
                    'consumer_cost': row['Consumer Cost'],
                    'dealer_cost': row['Dealer Cost Estimate'],
                    'margin_amount': row.get('Margins Estimate Amount', ''),
                    'margin_pct': row.get('Margin Estimate Percentage', '')
                }
    
    return wit_prices

# Pricing estimation functions based on product category
def estimate_toilet_price(product_name: str) -> Tuple[float, float]:
    """Estimate toilet pricing"""
    if 'bidet' in product_name.lower():
        return 450.0, 180.0  # Consumer, Dealer
    return 350.0, 140.0

def estimate_shower_base_price(product_name: str) -> Tuple[float, float]:
    """Estimate shower base/pan pricing based on size"""
    # Extract dimensions if present
    size_match = re.search(r'(\d+)\s*x\s*(\d+)', product_name)
    
    if size_match:
        width = int(size_match.group(1))
        length = int(size_match.group(2))
        area = width * length
        
        # Base price on area
        if area < 1500:  # Small (e.g., 36x36)
            consumer = 450
            dealer = 180
        elif area < 2000:  # Medium (e.g., 48x36)
            consumer = 550
            dealer = 220
        elif area < 2500:  # Large (e.g., 60x36)
            consumer = 650
            dealer = 260
        else:  # Extra large
            consumer = 750
            dealer = 300
    else:
        consumer = 550
        dealer = 220
    
    # Adjust for material type
    if 'neo-angle' in product_name.lower() or 'neo' in product_name.lower():
        consumer += 100
        dealer += 40
    
    if 'trimmable' in product_name.lower():
        consumer += 150
        dealer += 60
    
    return consumer, dealer

def estimate_door_price(product_name: str, feature_group: str) -> Tuple[float, float]:
    """Estimate shower/tub door pricing"""
    base_consumer = 600
    base_dealer = 240
    
    # Size adjustments
    if re.search(r'60|66|72', product_name):
        base_consumer += 100
        base_dealer += 40
    
    # Type adjustments
    if 'barn' in product_name.lower() or 'rotolo' in product_name.lower():
        base_consumer += 200
        base_dealer += 80
    elif 'bypass' in product_name.lower() or 'slider' in product_name.lower():
        base_consumer += 150
        base_dealer += 60
    elif 'neo' in product_name.lower():
        base_consumer += 100
        base_dealer += 40
    
    # Glass type
    if 'silk' in product_name.lower():
        base_consumer += 50
        base_dealer += 20
    
    # Finish adjustments
    if 'oil rubbed bronze' in product_name.lower() or 'orb' in product_name.lower():
        base_consumer += 75
        base_dealer += 30
    elif 'matte black' in product_name.lower() or 'mb' in product_name.lower():
        base_consumer += 50
        base_dealer += 20
    
    return base_consumer, base_dealer

def estimate_wall_panel_price(product_name: str, feature_group: str) -> Tuple[float, float]:
    """Estimate wall panel pricing"""
    # Extract dimensions
    size_match = re.search(r'(\d+)\s*[x"]\s*(\d+)', product_name)
    
    if size_match:
        width = int(size_match.group(1))
        height = int(size_match.group(2))
        area = width * height
    else:
        area = 5760  # Default 60x96
    
    # Base price per square foot
    if 'solid surface' in feature_group.lower() or 'solid surface' in product_name.lower():
        price_per_sqft = 0.45
    elif 'moment' in product_name.lower():
        price_per_sqft = 0.40
    else:  # Acrylic
        price_per_sqft = 0.35
    
    consumer = (area / 144) * price_per_sqft * 100  # Convert to retail
    dealer = consumer * 0.40
    
    return consumer, dealer

def estimate_trim_price(product_name: str) -> Tuple[float, float]:
    """Estimate trim pricing"""
    base_consumer = 45
    base_dealer = 18
    
    # Type adjustments
    if 'window' in product_name.lower() and 'kit' in product_name.lower():
        base_consumer = 120
        base_dealer = 48
    elif 'pencil trim kit' in product_name.lower():
        base_consumer = 85
        base_dealer = 34
    elif 'corner' in product_name.lower():
        base_consumer = 35
        base_dealer = 14
    
    # Material adjustments
    if 'aluminum' in product_name.lower() or 'schluter' in product_name.lower():
        base_consumer += 15
        base_dealer += 6
    
    return base_consumer, base_dealer

def estimate_shelf_price(product_name: str) -> Tuple[float, float]:
    """Estimate shelf/caddy pricing"""
    if 'pod' in product_name.lower():
        return 522.0, 209.0
    elif 'solid surface' in product_name.lower():
        return 85.0, 34.0
    elif 'teak' in product_name.lower():
        return 95.0, 38.0
    elif 'metal' in product_name.lower():
        return 65.0, 26.0
    else:  # Acrylic
        return 55.0, 22.0

def estimate_rod_price(product_name: str) -> Tuple[float, float]:
    """Estimate curtain rod pricing"""
    base_consumer = 65
    base_dealer = 26
    
    # Size adjustments
    if '72' in product_name or '6\'' in product_name:
        base_consumer += 15
        base_dealer += 6
    elif '60' in product_name:
        base_consumer += 10
        base_dealer += 4
    
    # Type adjustments
    if 'curved' in product_name.lower():
        base_consumer += 20
        base_dealer += 8
    
    # Finish adjustments
    if 'matte black' in product_name.lower() or 'mb' in product_name:
        base_consumer += 10
        base_dealer += 4
    
    return base_consumer, base_dealer

def estimate_safety_bar_price(product_name: str) -> Tuple[float, float]:
    """Estimate grab bar/safety bar pricing"""
    base_consumer = 45
    base_dealer = 18
    
    # Size adjustments
    size_match = re.search(r'(\d+)', product_name)
    if size_match:
        length = int(size_match.group(1))
        if length >= 48:
            base_consumer = 75
            base_dealer = 30
        elif length >= 36:
            base_consumer = 60
            base_dealer = 24
    
    # Type adjustments
    if 'l-shaped' in product_name.lower() or 'l shaped' in product_name.lower():
        base_consumer += 35
        base_dealer += 14
    
    return base_consumer, base_dealer

def estimate_seat_price(product_name: str) -> Tuple[float, float]:
    """Estimate shower seat pricing"""
    if 'comfort plus' in product_name.lower():
        return 425.0, 170.0
    elif 'slimline' in product_name.lower():
        if 'teak' in product_name.lower():
            return 385.0, 154.0
        return 325.0, 130.0
    return 350.0, 140.0

def estimate_faucet_trim_price(product_name: str) -> Tuple[float, float]:
    """Estimate faucet trim kit pricing"""
    base_consumer = 275
    base_dealer = 110
    
    # Collection adjustments
    if 'townsend' in product_name.lower():
        base_consumer = 295
        base_dealer = 118
    elif 'edgemere' in product_name.lower():
        base_consumer = 285
        base_dealer = 114
    elif 'glenmere' in product_name.lower():
        base_consumer = 320
        base_dealer = 128
    elif 'studio' in product_name.lower():
        base_consumer = 265
        base_dealer = 106
    
    # Finish adjustments
    if 'matte black' in product_name.lower() or 'mb' in product_name:
        base_consumer += 25
        base_dealer += 10
    elif 'legacy bronze' in product_name.lower() or 'lb' in product_name:
        base_consumer += 20
        base_dealer += 8
    
    return base_consumer, base_dealer

def estimate_handshower_price(product_name: str) -> Tuple[float, float]:
    """Estimate handshower pricing"""
    if 'spectra' in product_name.lower():
        if 'duo' in product_name.lower():
            return 125.0, 50.0
        elif 'versa' in product_name.lower():
            return 145.0, 58.0
    return 115.0, 46.0

def estimate_rough_in_price(product_name: str) -> Tuple[float, float]:
    """Estimate rough-in valve pricing"""
    if 'flash' in product_name.lower() or 'ru101ss' in product_name.lower():
        return 285.0, 114.0
    return 250.0, 100.0

def estimate_kerdi_price(product_name: str) -> Tuple[float, float]:
    """Estimate Kerdi/Schluter pricing"""
    if 'kit' in product_name.lower():
        if 'shower' in product_name.lower():
            return 495.0, 198.0
        elif 'tub' in product_name.lower():
            return 425.0, 170.0
    elif 'board' in product_name.lower() and 'panel' in product_name.lower():
        return 165.0, 66.0
    elif 'membrane' in product_name.lower():
        return 145.0, 58.0
    elif 'washer' in product_name.lower() or 'screw' in product_name.lower():
        return 35.0, 14.0
    
    return 75.0, 30.0

def estimate_drain_accessory_price(product_name: str) -> Tuple[float, float]:
    """Estimate drain and waste/overflow pricing"""
    if 'waste' in product_name.lower() and 'overflow' in product_name.lower():
        return 185.0, 74.0
    elif 'drain' in product_name.lower():
        if 'brass' in product_name.lower():
            return 65.0, 26.0
        return 45.0, 18.0
    return 55.0, 22.0

def estimate_bathtub_price(product_name: str) -> Tuple[float, float]:
    """Estimate standard bathtub pricing"""
    if 'americast' in product_name.lower():
        if '6032' in product_name:
            return 650.0, 260.0
        return 625.0, 250.0
    return 550.0, 220.0

def estimate_miscellaneous_price(product_name: str) -> Tuple[float, float]:
    """Estimate miscellaneous items"""
    if 'silicone' in product_name.lower():
        return 12.0, 5.0
    elif 'adhesive' in product_name.lower():
        if 'sausage' in product_name.lower():
            return 18.0, 7.0
        return 15.0, 6.0
    elif 'tape' in product_name.lower():
        if 'butyl' in product_name.lower():
            return 22.0, 9.0
        return 15.0, 6.0
    elif 'repair' in product_name.lower() and 'kit' in product_name.lower():
        return 25.0, 10.0
    elif 'ceiling panel' in product_name.lower():
        return 285.0, 114.0
    elif 'extender' in product_name.lower() or 'extension' in product_name.lower():
        if 'kit' in product_name.lower():
            return 245.0, 98.0
        return 85.0, 34.0
    elif 'pallet' in product_name.lower():
        return 150.0, 60.0
    elif 'reinforcement' in product_name.lower():
        return 8.0, 3.2
    elif 'threshold' in product_name.lower():
        return 125.0, 50.0
    
    return 45.0, 18.0

def estimate_price(sku: str, display_name: str, feature_group: str, product_name: str) -> Tuple[Optional[float], Optional[float]]:
    """
    Estimate consumer and dealer prices based on product category and features
    Returns (consumer_price, dealer_price) or (None, None) if it's a category header
    """
    # If it's a category header (empty display_name), return None
    if not display_name or not display_name.strip():
        return None, None
    
    product_lower = product_name.lower()
    display_lower = display_name.lower()
    
    # Walk-in tubs - will be matched from WiT_Margins_Complete
    if any(x in product_lower for x in ['liberation', 'independence', 'walk in', 'walkin']):
        return None, None  # Will be filled from WiT data
    
    # Toilets and Bidets
    if 'toilet' in product_lower or 'bidet' in product_lower or 'cadet' in product_lower:
        return estimate_toilet_price(product_name)
    
    # Shower Bases/Pans
    if any(x in product_lower for x in ['shower base', 'shower pan', 'ultra low', 'neo', 'trimmable']):
        return estimate_shower_base_price(product_name)
    
    # Doors
    if any(x in product_lower for x in ['door', 'bypass', 'barn', 'pivot', 'hinge', 'slider']):
        return estimate_door_price(product_name, feature_group)
    
    # Wall Panels
    if any(x in product_lower for x in ['wall', 'panel', 'subway', 'smooth']):
        return estimate_wall_panel_price(product_name, feature_group)
    
    # Trim
    if any(x in product_lower for x in ['trim', 'molding', 'batten', 'edge']):
        return estimate_trim_price(product_name)
    
    # Shelves/Caddies
    if any(x in product_lower for x in ['shelf', 'shelves', 'caddy', 'pod', 'basket']):
        return estimate_shelf_price(product_name)
    
    # Rods
    if 'rod' in product_lower and ('curtain' in product_lower or 'shower' in product_lower):
        return estimate_rod_price(product_name)
    
    # Safety Bars
    if any(x in product_lower for x in ['grab bar', 'safety bar', 'l-shaped']):
        return estimate_safety_bar_price(product_name)
    
    # Seats
    if 'seat' in product_lower and ('shower' in product_lower or 'fold' in product_lower or 'comfort' in product_lower or 'slimline' in product_lower):
        return estimate_seat_price(product_name)
    
    # Faucet Trim Kits
    if any(x in product_lower for x in ['trim kit', 'tub/shower', 'faucet', 'townsend', 'edgemere', 'glenmere']):
        if 'tu' in sku.lower()[:2] or 'trim' in product_lower:
            return estimate_faucet_trim_price(product_name)
    
    # Handshowers
    if 'handshower' in product_lower or 'hand shower' in product_lower or 'spectra' in product_lower:
        if 'slide bar' in product_lower:
            return 165.0, 66.0
        return estimate_handshower_price(product_name)
    
    # Rough-in valves
    if 'rough' in product_lower or 'valve' in product_lower:
        if 'ru' in sku.lower()[:2]:
            return estimate_rough_in_price(product_name)
    
    # Kerdi/Schluter
    if 'kerdi' in product_lower or 'schluter' in feature_group.lower():
        return estimate_kerdi_price(product_name)
    
    # Drains and Waste/Overflow
    if 'drain' in product_lower or 'waste' in product_lower or 'overflow' in product_lower:
        return estimate_drain_accessory_price(product_name)
    
    # Bathtubs
    if 'bathtub' in product_lower or 'americast' in product_lower:
        return estimate_bathtub_price(product_name)
    
    # Miscellaneous
    return estimate_miscellaneous_price(product_name)

def calculate_margin(consumer: float, dealer: float) -> Tuple[float, float]:
    """Calculate margin amount and percentage"""
    margin_amount = consumer - dealer
    margin_pct = (margin_amount / consumer) * 100 if consumer > 0 else 0
    return margin_amount, margin_pct

def main():
    print("Loading WiT pricing data...")
    wit_prices = load_wit_prices()
    print(f"Loaded {len(wit_prices)} walk-in tub prices")
    
    print("\nGenerating product prices...")
    
    output_rows = []
    stats = {
        'total': 0,
        'categories': 0,
        'wit_matched': 0,
        'estimated': 0,
        'skipped': 0
    }
    
    with open(INCOMPLETE_FILE, 'r', encoding='utf-8') as infile:
        reader = csv.DictReader(infile)
        
        for row in reader:
            sku = row['SKU'].strip()
            display_name = row['Display Name'].strip()
            feature_group = row['Feature Group'].strip()
            product_name = row['Product Name'].strip()
            
            # Initialize output row
            output_row = row.copy()
            
            # Check if it's a category header
            if not display_name:
                stats['categories'] += 1
                output_rows.append(output_row)
                continue
            
            stats['total'] += 1
            
            # Try to match with WiT_Margins_Complete first
            matched = False
            for wit_sku, wit_data in wit_prices.items():
                # Match on SKU or on key parts of the product description
                if (sku == wit_sku or 
                    wit_sku in sku or 
                    sku in wit_sku or
                    (wit_sku.replace('.', '') in sku.replace('-', '').replace('.', ''))):
                    
                    output_row['Consumer Cost'] = wit_data['consumer_cost']
                    output_row['Dealer Cost Estimate'] = wit_data['dealer_cost']
                    output_row['Margin Estimate Amount'] = wit_data['margin_amount']
                    output_row['Margin Estimate Percentage'] = wit_data['margin_pct']
                    
                    stats['wit_matched'] += 1
                    matched = True
                    break
            
            # If not matched, estimate the price
            if not matched:
                consumer, dealer = estimate_price(sku, display_name, feature_group, product_name)
                
                if consumer is not None and dealer is not None:
                    margin_amount, margin_pct = calculate_margin(consumer, dealer)
                    
                    output_row['Consumer Cost'] = f"{consumer:.2f}"
                    output_row['Dealer Cost Estimate'] = f"{dealer:.2f}"
                    output_row['Margin Estimate Amount'] = f"{margin_amount:.2f}"
                    output_row['Margin Estimate Percentage'] = f"{margin_pct:.2f}"
                    
                    stats['estimated'] += 1
                else:
                    stats['skipped'] += 1
            
            output_rows.append(output_row)
    
    # Write output file
    print("\nWriting output file...")
    with open(OUTPUT_FILE, 'w', encoding='utf-8', newline='') as outfile:
        fieldnames = [
            'SKU', 'Display Name', 'Feature Group', 'Consumer Cost',
            'Product Name', 'Dealer Cost Estimate', 'Margin Estimate Amount',
            'Margin Estimate Percentage'
        ]
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(output_rows)
    
    print("\n" + "="*60)
    print("PRICING GENERATION COMPLETE")
    print("="*60)
    print(f"Output file: {OUTPUT_FILE}")
    print(f"\nStatistics:")
    print(f"  Total products processed: {stats['total']}")
    print(f"  Category headers: {stats['categories']}")
    print(f"  Walk-in tubs matched from WiT data: {stats['wit_matched']}")
    print(f"  Products with estimated prices: {stats['estimated']}")
    print(f"  Products skipped: {stats['skipped']}")
    print("\n" + "="*60)

if __name__ == "__main__":
    main()
