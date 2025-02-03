package com.p3.syllesisfabrik.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.DBRef;
import org.springframework.data.mongodb.core.mapping.Document;
import com.p3.syllesisfabrik.repository.CartItemRepository;
import java.util.List;
//model/CartItem.java Snippet Start
@Document(collection = "cartItems")
public class CartItem {

    @Id
    private String id;

    @DBRef
    private MenuItem menuItem; // Reference to the MenuItem being added to the cart

    @DBRef
    private UserLogin company; // Reference to the company (UserLogin) who added the item to the cart

    private int desiredQuantity; // Quantity of the item that the company wishes to order
    private double totalCost; // Calculated total cost based on desired quantity and price per liter
    private boolean ordered = false; // Flag to indicate if the cart item has been ordered

    public CartItem() {}

    public CartItem(MenuItem menuItem, UserLogin company, int desiredQuantity, double totalCost) {
        this.menuItem = menuItem;
        this.company = company;
        this.desiredQuantity = desiredQuantity;
        this.totalCost = totalCost;
    }

    //model/CartItem.java Snippet End
    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public MenuItem getMenuItem() {
        return menuItem;
    }

    public void setMenuItem(MenuItem menuItem) {
        this.menuItem = menuItem;
    }

    public UserLogin getCompany() {
        return company;
    }

    public void setCompany(UserLogin company) {
        this.company = company;
    }

    public int getDesiredQuantity() {
        return desiredQuantity;
    }

    public void setDesiredQuantity(int desiredQuantity) {
        this.desiredQuantity = desiredQuantity;
    }

    public double getTotalCost() {
        return totalCost;
    }

    public void setTotalCost(double totalCost) {
        this.totalCost = totalCost;
    }

    public boolean isOrdered() {
        return ordered;
    }

    public void setOrdered(boolean ordered) {
        this.ordered = ordered;
    }


}
