package com.p3.syllesisfabrik.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.DBRef;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

    //model/order.java Snippet Start
@Document(collection = "orders")
public class Order {

    @Id
    private String id;

    @DBRef
    private UserLogin company;

    @DBRef
    private List<CartItem> cartItems;

    private double totalPrice;
    private LocalDateTime orderDate; // Raw LocalDateTime for database
    private boolean isApproved;
    private boolean isProcessing;
    private boolean isShipped;
    private boolean isInvoiced;
    private String formattedOrderDate; // Formatted date as a string for display

    // New field for expected delivery date
    private String expectedDeliveryDate;  // New field for expected delivery date
    private String deliveredDate;
    // Constructors
    public Order() {}

    public Order(UserLogin company, List<CartItem> cartItems, double totalPrice, LocalDateTime orderDate, boolean isApproved, boolean isProcessing, boolean isShipped, boolean isInvoiced, String expectedDeliveryDate, String deliveredDate) {
        this.company = company;
        this.cartItems = cartItems;
        this.totalPrice = totalPrice;
        this.orderDate = orderDate;
        this.isApproved = isApproved;
        this.isProcessing = isProcessing;
        this.isShipped = isShipped;
        this.isInvoiced = isInvoiced;
        this.formattedOrderDate = orderDate.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")); // Format date for display
        this.expectedDeliveryDate = expectedDeliveryDate; // Initialize expected delivery date
        this.deliveredDate = deliveredDate;
    }
    //model/order.java Snippet End

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public UserLogin getCompany() {
        return company;
    }

    public void setCompany(UserLogin company) {
        this.company = company;
    }

    public List<CartItem> getCartItems() {
        return cartItems;
    }

    public void setCartItems(List<CartItem> cartItems) {
        this.cartItems = cartItems;
    }

    public double getTotalPrice() {
        return totalPrice;
    }

    public void setTotalPrice(double totalPrice) {
        this.totalPrice = totalPrice;
    }

    public LocalDateTime getOrderDate() {
        return orderDate;
    }

    public void setOrderDate(LocalDateTime orderDate) {
        this.orderDate = orderDate;
        // Format and store the date as a string after it's set
        this.formattedOrderDate = orderDate.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"));
    }

    public boolean isApproved() {
        return isApproved;
    }

    public void setApproved(boolean approved) {
        isApproved = approved;
    }

    public boolean isProcessing() {
        return isProcessing;
    }

    public void setProcessing(boolean processing) {
        isProcessing = processing;
    }

    public boolean isShipped() {
        return isShipped;
    }

    public void setShipped(boolean shipped) {
        isShipped = shipped;
    }
    public boolean isInvoiced() {return isInvoiced;}
    public void setInvoiced(boolean invoiced) {isInvoiced = invoiced;}
    public String getFormattedOrderDate() {
        return formattedOrderDate;
    }

    public void setFormattedOrderDate(String formattedOrderDate) {
        this.formattedOrderDate = formattedOrderDate;
    }

    public String getExpectedDeliveryDate() {
        return expectedDeliveryDate;
    }

    public void setExpectedDeliveryDate(String expectedDeliveryDate) {
        this.expectedDeliveryDate = expectedDeliveryDate;
    }

    public String getDeliveredDate() {return deliveredDate;}

    public void setDeliveredDate(String deliveredDate) {this.deliveredDate = deliveredDate;}
}
