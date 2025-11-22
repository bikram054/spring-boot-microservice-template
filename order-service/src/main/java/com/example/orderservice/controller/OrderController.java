package com.example.orderservice.controller;

import com.example.orderservice.dto.OrderRequest;
import com.example.orderservice.dto.OrderResponse;
import com.example.orderservice.service.OrderService;
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
@RequestMapping("/api/orders")
public class OrderController {
    private static final Logger logger = LoggerFactory.getLogger(OrderController.class);

    @Autowired
    private OrderService orderService;

    @GetMapping
    public Page<OrderResponse> getAllOrders(Pageable pageable) {
        logger.debug("GET /api/orders called with pagination");
        return orderService.getAllOrders(pageable);
    }

    @GetMapping("/{id}")
    public ResponseEntity<OrderResponse> getOrderById(@PathVariable Long id) {
        logger.debug("GET /api/orders/{} called", id);
        return orderService.getOrderById(id)
                .map(resp -> {
                    logger.debug("GET /api/orders/{} found", id);
                    return ResponseEntity.ok(resp);
                })
                .orElseGet(() -> {
                    logger.debug("GET /api/orders/{} not found", id);
                    return ResponseEntity.notFound().build();
                });
    }

    @PostMapping
    public ResponseEntity<OrderResponse> createOrder(@Valid @RequestBody OrderRequest orderRequest) {
        logger.info("POST /api/orders create request for userId={} productId={} quantity={}",
                orderRequest.userId(), orderRequest.productId(), orderRequest.quantity());
        OrderResponse resp = orderService.createOrder(orderRequest);
        logger.info("POST /api/orders created id={}", resp.id());
        return ResponseEntity.status(HttpStatus.CREATED).body(resp);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteOrder(@PathVariable Long id) {
        logger.info("DELETE /api/orders/{} called", id);
        orderService.deleteOrder(id);
        logger.info("DELETE /api/orders/{} completed", id);
        return ResponseEntity.noContent().build();
    }
}
