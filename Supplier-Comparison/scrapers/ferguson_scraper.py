"""
Ferguson scraper
URL: https://www.ferguson.com/category/bathroom-plumbing/bathroom-accessories/?prefn1=brand&prefv1=American%2BStandard
"""

from .base_scraper import BaseScraper
from typing import Optional
from bs4 import BeautifulSoup
import logging
import urllib.parse

logger = logging.getLogger(__name__)


class FergusonScraper(BaseScraper):
    """Scraper for Ferguson.com"""
    
    def __init__(self):
        super().__init__('https://www.ferguson.com')
    
    def get_price(self, product_name: str) -> Optional[float]:
        """
        Get price for a product from Ferguson
        
        Args:
            product_name: Name of the product
            
        Returns:
            Price as float, or None if not found
        """
        try:
            # Construct search URL
            search_query = urllib.parse.quote(product_name)
            search_url = f"{self.base_url}/search?searchTerm={search_query}&prefn1=brand&prefv1=American Standard"
            
            logger.debug(f"Searching Ferguson: {search_url}")
            
            response = self.make_request(search_url)
            if not response:
                return None
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Look for product cards and prices
            # Ferguson typically uses classes like 'product-tile', 'price', etc.
            product_tiles = soup.find_all(['div', 'article'], class_=lambda x: x and ('product' in x.lower() or 'tile' in x.lower()))
            
            for tile in product_tiles:
                # Check if product name matches
                title_elem = tile.find(['h2', 'h3', 'h4', 'a'], class_=lambda x: x and 'title' in x.lower() if x else False)
                if not title_elem:
                    title_elem = tile.find('a', class_=lambda x: x and 'product' in x.lower() if x else False)
                
                if title_elem:
                    title_text = title_elem.get_text(strip=True).lower()
                    normalized_search = self.normalize_product_name(product_name)
                    
                    # Check if key terms from search are in the title
                    search_terms = normalized_search.split()[:3]  # Use first 3 words
                    if all(term in title_text for term in search_terms):
                        # Find price in this tile
                        price_elem = tile.find(['span', 'div', 'p'], class_=lambda x: x and 'price' in x.lower() if x else False)
                        
                        if price_elem:
                            price_text = price_elem.get_text(strip=True)
                            price = self.clean_price(price_text)
                            if price:
                                logger.info(f"Found price on Ferguson: ${price:.2f}")
                                return price
            
            logger.info("Product not found on Ferguson")
            return None
            
        except Exception as e:
            logger.error(f"Error scraping Ferguson: {str(e)}")
            return None
