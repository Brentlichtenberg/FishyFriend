"""
Ferguson Home scraper
URL: https://www.fergusonhome.com/walk-in-tubs/c114059?facets=manufacturer_s:American%20Standard
"""

from .base_scraper import BaseScraper
from typing import Optional
from bs4 import BeautifulSoup
import logging
import urllib.parse

logger = logging.getLogger(__name__)


class FergusonHomeScraper(BaseScraper):
    """Scraper for FergusonHome.com"""
    
    def __init__(self):
        super().__init__('https://www.fergusonhome.com')
    
    def get_price(self, product_name: str) -> Optional[float]:
        """
        Get price for a product from Ferguson Home
        
        Args:
            product_name: Name of the product
            
        Returns:
            Price as float, or None if not found
        """
        try:
            # Construct search URL with American Standard filter
            search_query = urllib.parse.quote(product_name)
            search_url = f"{self.base_url}/search?q={search_query}&facets=manufacturer_s:American Standard"
            
            logger.debug(f"Searching Ferguson Home: {search_url}")
            
            response = self.make_request(search_url)
            if not response:
                return None
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Look for product tiles
            product_tiles = soup.find_all(['div', 'article'], class_=lambda x: x and ('product' in x.lower() or 'tile' in x.lower()))
            
            for tile in product_tiles:
                # Find product title
                title_elem = tile.find(['h2', 'h3', 'h4', 'a'], class_=lambda x: x and ('title' in x.lower() or 'name' in x.lower()) if x else False)
                
                if not title_elem:
                    title_elem = tile.find('a', href=lambda x: x and '/product/' in x if x else False)
                
                if title_elem:
                    title_text = title_elem.get_text(strip=True).lower()
                    normalized_search = self.normalize_product_name(product_name)
                    
                    # Match product
                    search_terms = normalized_search.split()[:3]
                    if all(term in title_text for term in search_terms):
                        # Find price
                        price_elem = tile.find(['span', 'div'], class_=lambda x: x and 'price' in x.lower() if x else False)
                        
                        if price_elem:
                            price_text = price_elem.get_text(strip=True)
                            price = self.clean_price(price_text)
                            if price:
                                logger.info(f"Found price on Ferguson Home: ${price:.2f}")
                                return price
            
            logger.info("Product not found on Ferguson Home")
            return None
            
        except Exception as e:
            logger.error(f"Error scraping Ferguson Home: {str(e)}")
            return None
