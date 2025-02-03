package com.p3.syllesisfabrik.repository;

import com.p3.syllesisfabrik.model.MenuItem;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MenuItemRepository extends MongoRepository<MenuItem, String> {
    // Custom query methods can be added if needed
    List<MenuItem> findByIsAvailable(boolean isAvailable);
    List<MenuItem> findByTitleContainingIgnoreCase(String title);
    // Find by exact title (case-insensitive)
    Optional<MenuItem> findByTitleIgnoreCase(String title);
}
