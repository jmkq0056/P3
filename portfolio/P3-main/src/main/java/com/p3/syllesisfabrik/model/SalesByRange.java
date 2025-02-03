package com.p3.syllesisfabrik.model;

import java.time.LocalDate;
import java.util.List;
    //model/SalesByRange Snippet Start
public class SalesByRange {

    private String rangeLabel; // e.g., "Week 47, 2024", "January 2024", "Year 2024"
    private LocalDate startDate;
    private LocalDate endDate;
    private double totalRevenue;
    private int totalOrders;
    private List<String> topSellingProducts;

    // Constructor
    public SalesByRange(String rangeLabel, LocalDate startDate, LocalDate endDate, double totalRevenue, int totalOrders, List<String> topSellingProducts) {
        this.rangeLabel = rangeLabel;
        this.startDate = startDate;
        this.endDate = endDate;
        this.totalRevenue = totalRevenue;
        this.totalOrders = totalOrders;
        this.topSellingProducts = topSellingProducts;
    }
    //model/SalesByRange Snippet End

    // Getters and Setters
    public String getRangeLabel() {
        return rangeLabel;
    }

    public void setRangeLabel(String rangeLabel) {
        this.rangeLabel = rangeLabel;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }

    public LocalDate getEndDate() {
        return endDate;
    }

    public void setEndDate(LocalDate endDate) {
        this.endDate = endDate;
    }

    public double getTotalRevenue() {
        return totalRevenue;
    }

    public void setTotalRevenue(double totalRevenue) {
        this.totalRevenue = totalRevenue;
    }

    public int getTotalOrders() {
        return totalOrders;
    }

    public void setTotalOrders(int totalOrders) {
        this.totalOrders = totalOrders;
    }

    public List<String> getTopSellingProducts() {
        return topSellingProducts;
    }

    public void setTopSellingProducts(List<String> topSellingProducts) {
        this.topSellingProducts = topSellingProducts;
    }
}
