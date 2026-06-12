"""
Consolidated Supply scraper
URL: https://www.consolidatedsupply.com/Brands/American-Standard-Brands/Catalog/Tubs-And-Showers/Bathtubs/Walk-In-Bathtubs
"""

from .base_scraper import BaseScraper
from typing import Optional
from bs4 import BeautifulSoup
import logging
import urllib.parse

logger = logging.getLogger(__name__)


class ConsolidatedScraper(BaseScraper):
    """Scraper for ConsolidatedSupply.com"""
    
    def __init__(self):
        super().__init__('https://www.consolidatedsupply.com')
    
    def get_price(self, product_name: str) -> Optional[float]:
        """
        Get price for a product from Consolidated Supply
        
        Args:
            product_name: Name of the product
            
        Returns:
            Price as float, or None if not found
        """
        try:
            # Construct search URL
            search_query = urllib.parse.quote(f"american standard {product_name}")
            search_url = f"{self.base_url}/search.php?search_query={search_query}"
            
            logger.debug(f"Searching Consolidated Supply: {search_url}")
            
            response = self.make_request(search_url)
            if not response:
                return None
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Look for product listings
            product_items = soup.find_all(['div', 'li', 'article'], class_=lambda x: x and ('product' in x.lower() or 'item' in x.lower()))
            
            for item in product_items:
                # Find product name/title
                title_elem = item.find(['h2', 'h3', 'h4', 'a'], class_=lambda x: x and ('title' in x.lower() or 'name' in x.lower()) if x else False)
                
                if not title_elem:
                    title_elem = item.find('a', class_=lambda x: x and 'product' in x.lower() if x else False)
                
                if title_elem:
                    title_text = title_elem.get_text(strip=True).lower()
                    normalized_search = self.normalize_product_name(product_name)
                    
                    # Match product
                    search_terms = normalized_search.split()[:3]
                    if all(term in title_text for term in search_terms):
                        # Find price
                        price_elem = item.find(['span', 'div', 'p'], class_=lambda x: x and 'price' in x.lower() if x else False)
                        
                        if price_elem:
                            price_text = price_elem.get_text(strip=True)
                            price = self.clean_price(price_text)
                            if price:
                                logger.info(f"Found price on Consolidated Supply: ${price:.2f}")
                                return price
            
            logger.info("Product not found on Consolidated Supply")
            return None
            
        except Exception as e:
            logger.error(f"Error scraping Consolidated Supply: {str(e)}")
            return None
