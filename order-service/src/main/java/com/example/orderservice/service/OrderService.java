package com.example.orderservice.service;

import com.example.orderservice.dto.OrderRequest;
import com.example.orderservice.dto.OrderResponse;
import com.example.orderservice.entity.Order;
import com.example.orderservice.repository.OrderRepository;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class OrderService {
    private static final Logger logger = LoggerFactory.getLogger(OrderService.class);
    @Autowired
    private OrderRepository orderRepository;
    
    @Autowired
    private RestTemplate restTemplate;
    
    @Value("${user.service.url}")
    private String userServiceUrl;
    
    @Value("${product.service.url}")
    private String productServiceUrl;
    
    public List<OrderResponse> getAllOrders() {
        logger.debug("Fetching all orders");
        List<OrderResponse> responses = orderRepository.findAll().stream()
            .map(this::mapToOrderResponse)
            .collect(Collectors.toList());
        logger.debug("Fetched {} orders", responses.size());
        return responses;
    }
    
    public Optional<OrderResponse> getOrderById(Long id) {
        logger.debug("Fetching order by id={}", id);
        Optional<OrderResponse> result = orderRepository.findById(id)
            .map(this::mapToOrderResponse);
        if (result.isPresent()) {
            logger.debug("Found order id={}", id);
        } else {
            logger.debug("Order id={} not found", id);
        }
        return result;
    }
    
    @CircuitBreaker(name = "productService", fallbackMethod = "createOrderFallback")
    public OrderResponse createOrder(OrderRequest orderRequest) {
        logger.info("Creating order for userId={} productId={} quantity={}",
            orderRequest.userId(), orderRequest.productId(), orderRequest.quantity());
        try {
            Object product = restTemplate.getForObject(
                productServiceUrl + "/api/products/" + orderRequest.productId(),
                Object.class);

            if (!(product instanceof Map<?, ?> productMap)) {
                logger.error("Invalid product response format for productId={}", orderRequest.productId());
                throw new IllegalArgumentException("Invalid product response format");
            }

            Double price = ((Number) productMap.get("price")).doubleValue();
            Double totalAmount = price * orderRequest.quantity();

            Order order = new Order();
            order.setUserId(orderRequest.userId());
            order.setProductId(orderRequest.productId());
            order.setQuantity(orderRequest.quantity());
            order.setTotalAmount(totalAmount);

            Order savedOrder = orderRepository.save(order);
            logger.info("Order created id={} totalAmount={}", savedOrder.getId(), savedOrder.getTotalAmount());
            return mapToOrderResponse(savedOrder);
        } catch (HttpClientErrorException e) {
            logger.warn("Failed to retrieve product from product service: {}", e.getMessage());
            throw new IllegalArgumentException("Failed to retrieve product: " + e.getMessage());
        } catch (Exception e) {
            logger.error("Unexpected error while creating order: {}", e.getMessage(), e);
            throw e;
        }
    }
    
    public OrderResponse createOrderFallback(OrderRequest orderRequest, Exception ex) {
        logger.warn("createOrderFallback triggered for userId={} productId={} due to: {}",
            orderRequest.userId(), orderRequest.productId(), ex.toString());
        throw new IllegalArgumentException("Product service is currently unavailable. Please try again later.");
    }
    
    public void deleteOrder(Long id) {
        logger.info("Deleting order id={}", id);
        orderRepository.deleteById(id);
    }
    
    private OrderResponse mapToOrderResponse(Order order) {
        String userName = "Unknown";
        String productName = "Unknown";
        
        try {
            Map<String, Object> user = restTemplate.getForObject(
                userServiceUrl + "/api/users/" + order.getUserId(),
                Map.class);
            if (user != null && user.get("name") instanceof String name) {
                userName = name;
            }
        } catch (Exception e) {
            logger.debug("Could not fetch user name for userId={}: {}", order.getUserId(), e.getMessage());
        }
        
        try {
            Map<String, Object> product = restTemplate.getForObject(
                productServiceUrl + "/api/products/" + order.getProductId(),
                Map.class);
            if (product != null && product.get("name") instanceof String name) {
                productName = name;
            }
        } catch (Exception e) {
            logger.debug("Could not fetch product name for productId={}: {}", order.getProductId(), e.getMessage());
        }
        
        return new OrderResponse(
            order.getId(),
            order.getUserId(),
            userName,
            order.getProductId(),
            productName,
            order.getQuantity(),
            order.getTotalAmount(),
            order.getStatus(),
            order.getOrderDate()
        );
    }
}
