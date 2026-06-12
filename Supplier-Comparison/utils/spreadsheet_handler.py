"""
Spreadsheet handler for reading and writing product data
"""

import pandas as pd
import logging
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)


class SpreadsheetHandler:
    """Handle reading and writing spreadsheet files (CSV and Excel)"""
    
    SUPPORTED_FORMATS = ['.csv', '.xlsx', '.xls']
    
    def __init__(self, file_path: str):
        """
        Initialize spreadsheet handler
        
        Args:
            file_path: Path to the spreadsheet file
        """
        self.file_path = Path(file_path)
        self.file_extension = self.file_path.suffix.lower()
        
        if self.file_extension not in self.SUPPORTED_FORMATS:
            raise ValueError(
                f"Unsupported file format: {self.file_extension}. "
                f"Supported formats: {', '.join(self.SUPPORTED_FORMATS)}"
            )
    
    def load(self) -> pd.DataFrame:
        """
        Load spreadsheet data
        
        Returns:
            DataFrame with spreadsheet data
        """
        try:
            if not self.file_path.exists():
                logger.warning(f"File not found: {self.file_path}")
                return pd.DataFrame()
            
            if self.file_extension == '.csv':
                df = pd.read_csv(self.file_path)
            else:  # Excel formats
                df = pd.read_excel(self.file_path)
            
            logger.info(f"Loaded {len(df)} rows from {self.file_path}")
            return df
            
        except Exception as e:
            logger.error(f"Error loading spreadsheet: {str(e)}")
            return pd.DataFrame()
    
    def save(self, df: pd.DataFrame) -> bool:
        """
        Save DataFrame to spreadsheet
        
        Args:
            df: DataFrame to save
            
        Returns:
            True if successful, False otherwise
        """
        try:
            # Create backup of existing file
            if self.file_path.exists():
                backup_path = self.file_path.with_suffix(f'{self.file_extension}.backup')
                self.file_path.rename(backup_path)
                logger.info(f"Created backup: {backup_path}")
            
            # Save based on format
            if self.file_extension == '.csv':
                df.to_csv(self.file_path, index=False)
            else:  # Excel formats
                df.to_excel(self.file_path, index=False, engine='openpyxl')
            
            logger.info(f"Saved {len(df)} rows to {self.file_path}")
            return True
            
        except Exception as e:
            logger.error(f"Error saving spreadsheet: {str(e)}")
            return False
    
    def validate_structure(self, df: pd.DataFrame) -> bool:
        """
        Validate that the spreadsheet has the expected structure
        
        Args:
            df: DataFrame to validate
            
        Returns:
            True if valid, False otherwise
        """
        if df.empty:
            logger.warning("DataFrame is empty")
            return False
        
        # Check that column A exists (product names)
        if len(df.columns) < 1:
            logger.error("Spreadsheet must have at least one column (product names)")
            return False
        
        # Check that there are product names
        if df.iloc[:, 0].isna().all():
            logger.error("Column A (product names) is empty")
            return False
        
        return True
