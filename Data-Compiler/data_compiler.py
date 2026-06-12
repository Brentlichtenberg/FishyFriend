#!/usr/bin/env python3
"""
Data Compiler
Compiles data from ASHS SKUs and ASHS California CSV files into a template.
"""

import pandas as pd
import os
from pathlib import Path
from extract_list_prices import extract_products_with_list_prices, create_matching_dict
import re


class DataCompiler:
    def __init__(self, skus_file, california_file, catalog_pdf, output_file):
        """
        Initialize the DataCompiler with input and output file paths.
        
        Args:
            skus_file: Path to ASHS SKUs.csv
            california_file: Path to ASHS California.csv
            catalog_pdf: Path to American Standard catalog PDF
            output_file: Path for the output template file
        """
        self.skus_file = skus_file
        self.california_file = california_file
        self.catalog_pdf = catalog_pdf
        self.output_file = output_file
        self.template_df = None
        self.catalog_prices = {}
        
    def load_data(self):
        """Load the CSV files and PDF catalog into DataFrames."""
        print(f"Loading {self.skus_file}...")
        self.skus_df = pd.read_csv(self.skus_file)
        
        print(f"Loading {self.california_file}...")
        self.california_df = pd.read_csv(self.california_file)
        
        print(f"SKUs data loaded: {len(self.skus_df)} rows")
        print(f"California data loaded: {len(self.california_df)} rows")
        
        # Load catalog data
        if self.catalog_pdf and os.path.exists(self.catalog_pdf):
            print(f"\nLoading catalog PDF: {self.catalog_pdf}")
            products = extract_products_with_list_prices(self.catalog_pdf)
            self.catalog_prices = create_matching_dict(products)
            print(f"Catalog list prices loaded: {len(products)} products, {len(self.catalog_prices)} matching entries")
        else:
            print("Warning: Catalog PDF not found, column G will remain empty")
        
    def create_template_base(self):
        """
        Create the template base from ASHS SKUs data.
        Transfers:
        - Column A → Template Column A
        - Column B (SAP_ProductID) → Template Column B
        - Column C (LongDescr) → Template Column D
        """
        print("\nCreating template base from SKUs data...")
        
        # Get the columns from SKUs file
        # Assuming Column A, B, C are the first three columns (index 0, 1, 2)
        col_a = self.skus_df.iloc[:, 0]  # Column A
        col_b = self.skus_df.iloc[:, 1]  # Column B (SAP_ProductID)
        col_c = self.skus_df.iloc[:, 2]  # Column C (LongDescr)
        
        # Create template DataFrame with 7 columns (A through G)
        self.template_df = pd.DataFrame({
            'A': col_a,           # Column A from SKUs
            'B': col_b,           # SAP_ProductID from SKUs
            'C': '',              # Will be filled from California data
            'D': col_c,           # LongDescr from SKUs
            'E': '',              # Empty for now
            'F': '',              # Will be filled from California data
            'G': ''               # Will be filled from catalog PDF
        })
        
        print(f"Template base created with {len(self.template_df)} rows")
        
    def populate_from_california(self):
        """
        Populate template columns C, E, and F from California data.
        Matches Column E from California to Column A in template.
        When matched:
        - California Column B → Template Column C (DisplayName)
        - California Column C → Template Column F (RetailPrice)
        - California Column D → Template Column E (FeatureGroup)
        """
        print("\nMatching California data to template...")
        
        matches_found = 0
        no_matches = 0
        
        # Get California columns for matching
        california_col_e = self.california_df.iloc[:, 4]  # Column E (Sku)
        california_col_b = self.california_df.iloc[:, 1]  # Column B (DisplayName)
        california_col_c = self.california_df.iloc[:, 2]  # Column C (RetailPrice)
        california_col_d = self.california_df.iloc[:, 3]  # Column D (FeatureGroup)
        
        # Create a dictionary for faster lookups
        california_dict = {}
        for idx, sku in enumerate(california_col_e):
            if pd.notna(sku) and sku != '':
                california_dict[str(sku)] = {
                    'display_name': california_col_b.iloc[idx],
                    'retail_price': california_col_c.iloc[idx],
                    'feature_group': california_col_d.iloc[idx]
                }
        
        # Match and populate
        for idx in range(len(self.template_df)):
            template_col_a_value = str(self.template_df.at[idx, 'A'])
            
            if template_col_a_value in california_dict:
                self.template_df.at[idx, 'C'] = california_dict[template_col_a_value]['display_name']
                self.template_df.at[idx, 'E'] = california_dict[template_col_a_value]['feature_group']
                self.template_df.at[idx, 'F'] = california_dict[template_col_a_value]['retail_price']
                matches_found += 1
            else:
                no_matches += 1
        
        print(f"Matches found: {matches_found}")
        print(f"No matches: {no_matches}")
    
    def populate_catalog_prices(self):
        """
        Populate column G with prices from the PDF catalog.
        Match products using columns A, B, or D from the template.
        """
        print("\nMatching catalog prices to template...")
        
        if not self.catalog_prices:
            print("No catalog prices available, skipping...")
            return
        
        matches_found = 0
        
        for idx in range(len(self.template_df)):
            # Get values from columns A, B, D to try matching
            col_a = str(self.template_df.at[idx, 'A']) if pd.notna(self.template_df.at[idx, 'A']) else ''
            col_b = str(self.template_df.at[idx, 'B']) if pd.notna(self.template_df.at[idx, 'B']) else ''
            col_d = str(self.template_df.at[idx, 'D']) if pd.notna(self.template_df.at[idx, 'D']) else ''
            
            # Try to find a match in catalog
            price = self._find_catalog_price(col_a, col_b, col_d)
            
            if price:
                self.template_df.at[idx, 'G'] = price
                matches_found += 1
        
        print(f"Catalog price matches found: {matches_found}")
        print(f"No catalog matches: {len(self.template_df) - matches_found}")
    
    def _find_catalog_price(self, *codes):
        """
        Try to find a price in the catalog for any of the given codes.
        Uses fuzzy matching and normalization.
        """
        for code in codes:
            if not code or code == 'nan':
                continue
            
            # Try exact match first
            if code in self.catalog_prices:
                return self.catalog_prices[code]
            
            # Try normalized versions
            normalized_versions = [
                code.upper(),
                code.lower(),
                code.replace('.', ''),
                code.replace('-', ''),
                code.replace(' ', ''),
                re.sub(r'[^A-Za-z0-9]', '', code),
            ]
            
            for norm_code in normalized_versions:
                if norm_code in self.catalog_prices:
                    return self.catalog_prices[norm_code]
            
            # Try partial matches for longer codes
            if len(code) > 6:
                for catalog_code, price in self.catalog_prices.items():
                    if catalog_code in code or code in catalog_code:
                        return price
        
        return None
        
    def save_template(self):
        """Save the populated template to a CSV file."""
        print(f"\nSaving template to {self.output_file}...")
        
        # Save without index and without header (or with simple headers)
        self.template_df.to_csv(self.output_file, index=False)
        
        print(f"Template saved successfully!")
        print(f"Total rows: {len(self.template_df)}")
        
    def compile(self):
        """Main compilation process."""
        print("=" * 60)
        print("Data Compiler - Starting compilation process")
        print("=" * 60)
        
        self.load_data()
        self.create_template_base()
        self.populate_from_california()
        self.populate_catalog_prices()
        self.save_template()
        
        print("\n" + "=" * 60)
        print("Compilation complete!")
        print("=" * 60)
        
        return self.template_df


def main():
    """Main entry point for the script."""
    # Default file paths
    base_dir = Path(__file__).parent
    desktop = Path.home() / "Desktop"
    psku_dir = desktop / "PSKU Project"
    
    # Input files
    skus_file = desktop / "ASHS SKUs.csv"
    california_file = desktop / "ASHS California.csv"
    catalog_pdf = psku_dir / "American Standard Residential Product Catalog.pdf"
    
    # Output file
    output_file = base_dir / "Data-Comparison-Template-Populated.csv"
    
    # Check if input files exist
    if not skus_file.exists():
        print(f"Error: {skus_file} not found!")
        return
    
    if not california_file.exists():
        print(f"Error: {california_file} not found!")
        return
    
    # Create compiler and run
    compiler = DataCompiler(skus_file, california_file, catalog_pdf, output_file)
    compiler.compile()
    
    print(f"\nOutput file location: {output_file}")


if __name__ == "__main__":
    main()
