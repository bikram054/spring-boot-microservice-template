package com.example.productservice.service;

import com.example.productservice.entity.Product;
import com.example.productservice.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.List;
import java.util.Optional;

@Service
public class ProductService {
    private static final Logger logger = LoggerFactory.getLogger(ProductService.class);

    @Autowired
    private ProductRepository productRepository;

    public Page<Product> getAllProducts(Pageable pageable) {
        logger.debug("Fetching products with pagination");
        Page<Product> page = productRepository.findAll(pageable);
        logger.debug("Fetched {} products", page.getNumberOfElements());
        return page;
    }

    public Optional<Product> getProductById(Long id) {
        if (id == null) {
            return Optional.empty();
        }
        logger.debug("Fetching product by id={}", id);
        Optional<Product> result = productRepository.findById(id);
        if (result.isPresent())
            logger.debug("Found product id={}", id);
        else
            logger.debug("Product id={} not found", id);
        return result;
    }

    public Product createProduct(Product product) {
        logger.info("Creating product name={} price={}", product.getName(), product.getPrice());
        Product saved = productRepository.save(product);
        logger.info("Created product id={}", saved.getId());
        return saved;
    }

    public Product updateProduct(Long id, Product productDetails) {
        if (id == null) {
            throw new IllegalArgumentException("Product id cannot be null");
        }
        logger.info("Updating product id={}", id);
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found"));
        product.setName(productDetails.getName());
        product.setDescription(productDetails.getDescription());
        product.setPrice(productDetails.getPrice());
        product.setStock(productDetails.getStock());
        Product saved = productRepository.save(product);
        logger.info("Updated product id={}", saved.getId());
        return saved;
    }

    public void deleteProduct(Long id) {
        if (id == null) {
            throw new IllegalArgumentException("Product id cannot be null");
        }
        logger.info("Deleting product id={}", id);
        productRepository.deleteById(id);
    }
}
