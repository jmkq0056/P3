package com.p3.syllesisfabrik.service;

import com.p3.syllesisfabrik.model.MenuItem;
import com.p3.syllesisfabrik.repository.MenuItemRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;
import java.util.List;

@Service
public class MenuItemService {

    @Autowired
    private MenuItemRepository menuItemRepository;

    public List<MenuItem> findAll() {
        return menuItemRepository.findAll();
    }

    public MenuItem saveMenuItem(MenuItem menuItem) {
        return menuItemRepository.save(menuItem);
    }

    public void deleteById(String id) {
        menuItemRepository.deleteById(id);  // Deletes the MenuItem by its ID
    }
    public Optional<MenuItem> findById(String id) {
        return menuItemRepository.findById(id);  // Uses the built-in MongoRepository method
    }

    public Optional<MenuItem> findByTitle(String title) {
        return menuItemRepository.findByTitleIgnoreCase(title);
    }

}
