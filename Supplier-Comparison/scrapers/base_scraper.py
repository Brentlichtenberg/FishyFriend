"""
Base scraper class with common functionality
"""

import requests
from bs4 import BeautifulSoup
from typing import Optional
import logging
import re

logger = logging.getLogger(__name__)


class BaseScraper:
    """Base class for all supplier scrapers"""
    
    def __init__(self, base_url: str):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
        })
    
    def get_price(self, product_name: str) -> Optional[float]:
        """
        Get price for a product. Must be implemented by subclasses.
        
        Args:
            product_name: Name of the product to search for
            
        Returns:
            Price as float, or None if not found
        """
        raise NotImplementedError("Subclasses must implement get_price()")
    
    def clean_price(self, price_text: str) -> Optional[float]:
        """
        Extract numeric price from text
        
        Args:
            price_text: Raw price text (e.g., "$1,234.56")
            
        Returns:
            Price as float, or None if unable to parse
        """
        if not price_text:
            return None
            
        # Remove currency symbols, commas, and whitespace
        cleaned = re.sub(r'[^\d.]', '', price_text)
        
        try:
            return float(cleaned)
        except (ValueError, TypeError):
            return None
    
    def normalize_product_name(self, product_name: str) -> str:
        """
        Normalize product name for searching
        
        Args:
            product_name: Raw product name
            
        Returns:
            Normalized product name
        """
        # Convert to lowercase and remove extra whitespace
        normalized = ' '.join(product_name.lower().split())
        return normalized
    
    def make_request(self, url: str, **kwargs) -> Optional[requests.Response]:
        """
        Make HTTP request with error handling
        
        Args:
            url: URL to request
            **kwargs: Additional arguments for requests
            
        Returns:
            Response object or None if failed
        """
        try:
            response = self.session.get(url, timeout=30, **kwargs)
            response.raise_for_status()
            return response
        except requests.RequestException as e:
            logger.error(f"Request failed for {url}: {str(e)}")
            return None
