package com.example.productservice.controller;

import com.example.productservice.dto.CreateProductRequest;
import com.example.productservice.dto.ProductDto;
import com.example.productservice.dto.UpdateProductRequest;
import com.example.productservice.entity.Product;
import com.example.productservice.mapper.ProductMapper;
import com.example.productservice.service.ProductService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/products")
public class ProductController {
    private static final Logger logger = LoggerFactory.getLogger(ProductController.class);

    @Autowired
    private ProductService productService;

    @Autowired
    private ProductMapper productMapper;

    @GetMapping
    public Page<ProductDto> getAllProducts(Pageable pageable) {
        logger.debug("GET /api/products called with pagination");
        return productService.getAllProducts(pageable)
                .map(productMapper::toDto);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ProductDto> getProductById(@PathVariable Long id) {
        logger.debug("GET /api/products/{} called", id);
        return productService.getProductById(id)
                .map(product -> {
                    logger.debug("GET /api/products/{} found", id);
                    return ResponseEntity.ok(productMapper.toDto(product));
                })
                .orElseGet(() -> {
                    logger.debug("GET /api/products/{} not found", id);
                    return ResponseEntity.notFound().build();
                });
    }

    @PostMapping
    public ResponseEntity<ProductDto> createProduct(@Valid @RequestBody CreateProductRequest request) {
        logger.info("POST /api/products create name={} price={}", request.getName(), request.getPrice());
        Product product = productMapper.toEntity(request);
        Product saved = productService.createProduct(product);
        logger.info("POST /api/products created id={}", saved.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(productMapper.toDto(saved));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ProductDto> updateProduct(@PathVariable Long id,
            @Valid @RequestBody UpdateProductRequest request) {
        try {
            // We need to map UpdateProductRequest to Product entity for the service
            // But service takes Product with all fields.
            // Let's create a temp product with fields from request
            Product tempProduct = new Product();
            tempProduct.setName(request.getName());
            tempProduct.setDescription(request.getDescription());
            tempProduct.setPrice(request.getPrice());
            tempProduct.setStock(request.getStock());

            Product updated = productService.updateProduct(id, tempProduct);
            logger.info("PUT /api/products/{} updated", id);
            return ResponseEntity.ok(productMapper.toDto(updated));
        } catch (RuntimeException e) {
            logger.debug("PUT /api/products/{} not found", id);
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteProduct(@PathVariable Long id) {
        logger.info("DELETE /api/products/{} called", id);
        productService.deleteProduct(id);
        logger.info("DELETE /api/products/{} completed", id);
        return ResponseEntity.noContent().build();
    }
}
