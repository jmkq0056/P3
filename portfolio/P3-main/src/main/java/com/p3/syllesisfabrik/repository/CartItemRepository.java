package com.p3.syllesisfabrik.repository;

import com.p3.syllesisfabrik.model.CartItem;
import com.p3.syllesisfabrik.model.MenuItem;
import com.p3.syllesisfabrik.model.UserLogin;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CartItemRepository extends MongoRepository<CartItem, String> {

    // Custom method to find all cart items by company (UserLogin)
    List<CartItem> findByCompany(UserLogin company);

    // Custom method to find all cart items by company that are not ordered yet
    List<CartItem> findByCompanyAndOrdered(UserLogin company, boolean ordered);

    List<CartItem> findByCompanyAndMenuItemAndOrderedFalse(UserLogin company, MenuItem menuItem);
    // Find CartItems by Company and MenuItem and ensure ordered = false
    void deleteByCompany(UserLogin company);

    List<CartItem> findByMenuItem(MenuItem menuItem);
    // Find cart items that belong to a company, linked to a menu item, and are not yet ordered
}

