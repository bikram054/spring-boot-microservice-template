package com.example.userservice.controller;

import com.example.userservice.dto.CreateUserRequest;
import com.example.userservice.dto.UpdateUserRequest;
import com.example.userservice.dto.UserDto;
import com.example.userservice.entity.User;
import com.example.userservice.mapper.UserMapper;
import com.example.userservice.service.UserService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.lang.NonNull;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/users")
public class UserController {
    private static final Logger logger = LoggerFactory.getLogger(UserController.class);

    @Autowired
    private UserService userService;

    @Autowired
    private UserMapper userMapper;

    @GetMapping
    public Page<UserDto> getAllUsers(@NonNull Pageable pageable) {
        logger.debug("GET /users called with pagination");
        return userService.getAllUsers(pageable)
                .map(userMapper::toDto);
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserDto> getUserById(@PathVariable @NonNull Long id) {
        logger.debug("GET /users/{} called", id);
        return userService.getUserById(id)
                .map(user -> {
                    logger.debug("GET /users/{} found", id);
                    return ResponseEntity.ok(userMapper.toDto(user));
                })
                .orElseGet(() -> {
                    logger.debug("GET /users/{} not found", id);
                    return ResponseEntity.notFound().build();
                });
    }

    @PostMapping
    public ResponseEntity<UserDto> createUser(@Valid @RequestBody CreateUserRequest request) {
        logger.info("POST /users create name={} email={}", request.getName(), request.getEmail());
        User user = userMapper.toEntity(request);
        User saved = userService.createUser(user);
        logger.info("POST /users created id={}", saved.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(userMapper.toDto(saved));
    }

    @PutMapping("/{id}")
    public ResponseEntity<UserDto> replaceUser(@PathVariable @NonNull Long id,
            @Valid @RequestBody CreateUserRequest request) {
        // PUT = full replace; reusing CreateUserRequest as it has all required fields
        try {
            User user = userMapper.toEntity(request);
            User replaced = userService.replaceUser(id, user);
            logger.info("PUT /users/{} replaced", id);
            return ResponseEntity.ok(userMapper.toDto(replaced));
        } catch (RuntimeException e) {
            logger.debug("PUT /users/{} not found", id);
            return ResponseEntity.notFound().build();
        }
    }

    @PatchMapping("/{id}")
    public ResponseEntity<UserDto> patchUser(@PathVariable @NonNull Long id,
            @Valid @RequestBody UpdateUserRequest request) {
        // PATCH = partial update
        try {
            // We need to fetch the user first to update it using mapper, but
            // UserService.updateUser
            // currently takes a User entity with the fields to update.
            // A better approach with DTOs:
            // 1. Fetch existing (Service)
            // 2. Map updates (Mapper)
            // 3. Save (Service)
            // However, to minimize Service changes, I will map DTO to a temporary User
            // object
            // and pass it to userService.updateUser which handles the logic.

            User tempUser = new User();
            // We only set fields that are present in the request
            // But UpdateUserRequest fields are always present (null if not set).
            // UserMapper.updateEntity updates a target entity.

            // Let's use a temporary user and manually map for now to match Service
            // expectation
            // Or better: update Service to take DTO? No, keep Service pure.
            // I'll create a temp user with the fields from request.
            if (request.getName() != null)
                tempUser.setName(request.getName());
            if (request.getEmail() != null)
                tempUser.setEmail(request.getEmail());
            if (request.getPhone() != null)
                tempUser.setPhone(request.getPhone());

            User updated = userService.updateUser(id, tempUser);
            logger.info("PATCH /users/{} updated", id);
            return ResponseEntity.ok(userMapper.toDto(updated));
        } catch (RuntimeException e) {
            logger.debug("PATCH /users/{} not found or invalid", id);
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable @NonNull Long id) {
        logger.info("DELETE /users/{} called", id);
        userService.deleteUser(id);
        logger.info("DELETE /users/{} completed", id);
        return ResponseEntity.noContent().build();
    }
}
