# Data Compiler

A Python tool to compile data from multiple CSV files into a standardized template.

## Overview

This program extracts and combines data from ASHS SKUs and ASHS California CSV files to create a populated template file.

## Data Flow

### From ASHS SKUs.csv:
- Column A → Template Column A
- Column B (SAP_ProductID) → Template Column B
- Column C (LongDescr) → Template Column D

### From ASHS California.csv:
- Matches Column E (Sku) to Template Column A
- When matched:
  - Column B (DisplayName) → Template Column C
  - Column C (RetailPrice) → Template Column F

### Template Structure:
- **Column A**: SKU identifier (from SKUs file)
- **Column B**: SAP Product ID (from SKUs file)
- **Column C**: Display Name (from California file, matched)
- **Column D**: Long Description (from SKUs file)
- **Column E**: (Reserved for future use)
- **Column F**: Retail Price (from California file, matched)
- **Column G**: (Reserved for future steps)

## Requirements

```
pandas
```

## Installation

1. Install required packages:
```bash
pip install pandas
```

## Usage

1. Place your input files on the Desktop:
   - `ASHS SKUs.csv`
   - `ASHS California.csv`

2. Run the compiler:
```bash
python data_compiler.py
```

3. The output file `Data-Comparison-Template-Populated.csv` will be created in the Data-Compiler directory.

## Custom File Paths

You can modify the file paths in the `main()` function of `data_compiler.py` to use different locations.

## Output

The script will:
- Load both CSV files
- Create a template base from SKUs data
- Match and populate data from California file
- Save the final populated template
- Display statistics about matches found

## Example Output

```
============================================================
Data Compiler - Starting compilation process
============================================================
Loading ASHS SKUs.csv...
Loading ASHS California.csv...
SKUs data loaded: 500 rows
California data loaded: 300 rows

Creating template base from SKUs data...
Template base created with 500 rows

Matching California data to template...
Matches found: 250
No matches: 250

Saving template to Data-Comparison-Template-Populated.csv...
Template saved successfully!
Total rows: 500

============================================================
Compilation complete!
============================================================
```
