package com.p3.syllesisfabrik.service;

import com.p3.syllesisfabrik.model.CartItem;
import com.p3.syllesisfabrik.model.MenuItem;
import com.p3.syllesisfabrik.model.UserLogin;
import com.p3.syllesisfabrik.repository.CartItemRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CartItemService {

    @Autowired
    private CartItemRepository cartItemRepository;

    /**
     * Saves a new CartItem to the database.
     *
     * @param cartItem The CartItem to be saved.
     * @return The saved CartItem.
     */
    public CartItem save(CartItem cartItem) {
        return cartItemRepository.save(cartItem);
    }

    /**
     * Retrieves all CartItems associated with a specific company.
     *
     * @param company The UserLogin representing the company.
     * @return A list of CartItems for the given company.
     */
    public List<CartItem> findByCompany(UserLogin company) {
        return cartItemRepository.findByCompany(company);
    }

    /**
     * Retrieves all un-ordered CartItems for a specific company.
     *
     * @param company The UserLogin representing the company.
     * @return A list of un-ordered CartItems for the given company.
     */
    public List<CartItem> findUnorderedItemsByCompany(UserLogin company) {
        return cartItemRepository.findByCompanyAndOrdered(company, false);
    }

    /**
     * Updates the ordered status of CartItems for a specific company.
     *
     * @param cartItems The list of CartItems to update.
     * @param ordered   The new ordered status.
     */
    public void updateOrderedStatus(List<CartItem> cartItems, boolean ordered) {
        cartItems.forEach(cartItem -> cartItem.setOrdered(ordered));
        cartItemRepository.saveAll(cartItems);
    }

    /**
     * Deletes a CartItem by its ID.
     *
     * @param cartItemId The ID of the CartItem to be deleted.
     */
    public void deleteById(String cartItemId) {
        cartItemRepository.deleteById(cartItemId);
    }

    /**
     * Deletes all CartItems for a specific company.
     *
     * @param company The UserLogin representing the company.
     */
    public void deleteAllByCompany(UserLogin company) {
        List<CartItem> companyCartItems = cartItemRepository.findByCompany(company);
        cartItemRepository.deleteAll(companyCartItems);
    }

    // Finds CartItems where ordered is false and associated with a specific company and menu item
    public List<CartItem> findItemsByCompanyAndMenuItemAndOrderedFalse(UserLogin company, MenuItem menuItem) {
        return cartItemRepository.findByCompanyAndMenuItemAndOrderedFalse(company, menuItem);
    }

    public void deleteByCompany(UserLogin company) {
        cartItemRepository.deleteByCompany(company);
    }

    public List<CartItem> findByMenuItem(MenuItem menuItem) {
        return cartItemRepository.findByMenuItem(menuItem);
    }

    // Deletes a specific cart item
    public void delete(CartItem cartItem) {
        cartItemRepository.delete(cartItem);
    }
}
