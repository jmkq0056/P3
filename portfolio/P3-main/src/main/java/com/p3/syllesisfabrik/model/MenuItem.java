package com.p3.syllesisfabrik.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.util.List;
    //model/MenuItem.java Snippet Start
@Document(collection = "menuItems")
public class MenuItem {

    @Id
    private String id;
    private String title;
    private String description;
    private List<String> allergens;
    private int quantity;
    private boolean isAvailable;
    private double pricePerLiter;
    private List<String> imagePaths; // Use List<String> for image paths

    // Default constructor
    public MenuItem() {
    }

    // Full constructor
    public MenuItem(String title, String description, List<String> allergens, int quantity,
                    boolean isAvailable, double pricePerLiter, List<String> imagePaths) {
        this.title = title;
        this.description = description;
        this.allergens = allergens;
        this.quantity = quantity;
        this.isAvailable = isAvailable;
        this.pricePerLiter = pricePerLiter;
        this.imagePaths = imagePaths;
    }
    //model/MenuItem.java Snippet Start


    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public List<String> getAllergens() {
        return allergens;
    }

    public void setAllergens(List<String> allergens) {
        this.allergens = allergens;
    }

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }

    public boolean isAvailable() {
        return isAvailable;
    }

    public void setAvailable(boolean available) {
        isAvailable = available;
    }



    public double getPricePerLiter() {
        return pricePerLiter;
    }

    public void setPricePerLiter(double pricePerLiter) {
        this.pricePerLiter = pricePerLiter;
    }

    public List<String> getImagePaths() {
        return imagePaths;
    }

    public void setImagePaths(List<String> imagePaths) {
        this.imagePaths = imagePaths;
    }
}
