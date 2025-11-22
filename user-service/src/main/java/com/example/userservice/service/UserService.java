package com.example.userservice.service;

import com.example.userservice.entity.User;
import com.example.userservice.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.List;
import java.util.Optional;

@Service
public class UserService {
    private static final Logger logger = LoggerFactory.getLogger(UserService.class);

    @Autowired
    private UserRepository userRepository;

    public Page<User> getAllUsers(Pageable pageable) {
        logger.debug("Fetching users with pagination");
        Page<User> page = userRepository.findAll(pageable);
        logger.debug("Fetched {} users", page.getNumberOfElements());
        return page;
    }

    public Optional<User> getUserById(Long id) {
        if (id == null) {
            return Optional.empty();
        }
        logger.debug("Fetching user by id={}", id);
        Optional<User> result = userRepository.findById(id);
        if (result.isPresent())
            logger.debug("Found user id={}", id);
        else
            logger.debug("User id={} not found", id);
        return result;
    }

    public User createUser(User user) {
        logger.info("Creating user name={} email={}", user.getName(), user.getEmail());
        User saved = userRepository.save(user);
        logger.info("Created user id={}", saved.getId());
        return saved;
    }

    public User updateUser(Long id, User userDetails) {
        if (id == null) {
            throw new IllegalArgumentException("User id cannot be null");
        }
        logger.info("Updating user id={}", id);
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Only update fields that are provided (non-null) to avoid violating NOT NULL
        // constraints
        if (userDetails.getName() != null) {
            user.setName(userDetails.getName());
        }
        if (userDetails.getEmail() != null) {
            user.setEmail(userDetails.getEmail());
        }
        if (userDetails.getPhone() != null) {
            user.setPhone(userDetails.getPhone());
        }

        // Validate required fields remain present
        if (user.getName() == null || user.getName().isBlank()) {
            throw new IllegalArgumentException("User 'name' is required and cannot be null or empty");
        }
        if (user.getEmail() == null || user.getEmail().isBlank()) {
            throw new IllegalArgumentException("User 'email' is required and cannot be null or empty");
        }

        User saved = userRepository.save(user);
        logger.info("Updated user id={}", saved.getId());
        return saved;
    }

    /**
     * Replace the user record with the provided details. This is a full replace
     * (PUT semantics) and requires required fields to be present.
     */
    public User replaceUser(Long id, User userDetails) {
        if (id == null) {
            throw new IllegalArgumentException("User id cannot be null");
        }
        logger.info("Replacing user id={}", id);
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Full replace - required fields must be present
        if (userDetails.getName() == null || userDetails.getName().isBlank()) {
            throw new IllegalArgumentException("User 'name' is required for full replace");
        }
        if (userDetails.getEmail() == null || userDetails.getEmail().isBlank()) {
            throw new IllegalArgumentException("User 'email' is required for full replace");
        }

        user.setName(userDetails.getName());
        user.setEmail(userDetails.getEmail());
        user.setPhone(userDetails.getPhone());

        User saved = userRepository.save(user);
        logger.info("Replaced user id={}", saved.getId());
        return saved;
    }

    public void deleteUser(Long id) {
        if (id == null) {
            throw new IllegalArgumentException("User id cannot be null");
        }
        logger.info("Deleting user id={}", id);
        userRepository.deleteById(id);
    }
}
