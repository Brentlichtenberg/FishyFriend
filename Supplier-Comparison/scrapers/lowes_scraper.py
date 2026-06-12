"""
Lowe's scraper
URL: https://www.lowes.com/b/american-standard
"""

from .base_scraper import BaseScraper
from typing import Optional
from bs4 import BeautifulSoup
import logging
import urllib.parse

logger = logging.getLogger(__name__)


class LowesScraper(BaseScraper):
    """Scraper for Lowes.com"""
    
    def __init__(self):
        super().__init__('https://www.lowes.com')
    
    def get_price(self, product_name: str) -> Optional[float]:
        """
        Get price for a product from Lowe's
        
        Args:
            product_name: Name of the product
            
        Returns:
            Price as float, or None if not found
        """
        try:
            # Construct search URL - Lowe's search with American Standard filter
            search_query = urllib.parse.quote(f"american standard {product_name}")
            search_url = f"{self.base_url}/search?searchTerm={search_query}"
            
            logger.debug(f"Searching Lowe's: {search_url}")
            
            response = self.make_request(search_url)
            if not response:
                return None
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Look for product grids/cards
            product_cards = soup.find_all(['div', 'article'], class_=lambda x: x and ('product' in x.lower() or 'grid-item' in x.lower()))
            
            for card in product_cards:
                # Find product title
                title_elem = card.find(['a', 'h2', 'h3', 'span'], class_=lambda x: x and ('title' in x.lower() or 'description' in x.lower()) if x else False)
                
                if not title_elem:
                    title_elem = card.find('a', attrs={'data-type': 'product'})
                
                if title_elem:
                    title_text = title_elem.get_text(strip=True).lower()
                    normalized_search = self.normalize_product_name(product_name)
                    
                    # Match product
                    search_terms = normalized_search.split()[:3]
                    if all(term in title_text for term in search_terms):
                        # Find price
                        price_elem = card.find(['span', 'div'], class_=lambda x: x and 'price' in x.lower() if x else False)
                        
                        if not price_elem:
                            price_elem = card.find('span', attrs={'data-selector': 'price'})
                        
                        if price_elem:
                            price_text = price_elem.get_text(strip=True)
                            price = self.clean_price(price_text)
                            if price:
                                logger.info(f"Found price on Lowe's: ${price:.2f}")
                                return price
            
            logger.info("Product not found on Lowe's")
            return None
            
        except Exception as e:
            logger.error(f"Error scraping Lowe's: {str(e)}")
            return None
