package com.example.orderservice.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record OrderResponse(
        Long id,
        Long userId,
        String userName,
        Long productId,
        String productName,
        Integer quantity,
        BigDecimal totalAmount,
        String status,
        LocalDateTime orderDate) {
}
