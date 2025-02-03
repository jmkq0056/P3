package com.p3.syllesisfabrik.service;

import com.p3.syllesisfabrik.model.Order;
import com.p3.syllesisfabrik.model.UserLogin;
import com.p3.syllesisfabrik.repository.OrderRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

@Service
public class OrderService {

    @Autowired
    private OrderRepository orderRepository;

    public Order save(Order order) {
        return orderRepository.save(order);
    }

    public Optional<Order> findById(String id) {
        return orderRepository.findById(id);
    }

    public List<Order> findAll() {
        return orderRepository.findAll();
    }

    public void deleteById(String id) {
        orderRepository.deleteById(id);
    }
    public List<Order> fetchCurrentOrders() {
        // Fetch orders where isProcessing is true, isApproved is false, and isShipped is false
        return orderRepository.findByIsProcessingAndIsApprovedFalseAndIsShippedFalse(true);
    }
    // Fetch orders that are approved, not yet processed, and not yet shipped
    public List<Order> fetchReadyToBeShippedOrders() {
        return orderRepository.findByIsApprovedTrueAndIsProcessingFalseAndIsShippedFalse();
    }

    public List<Order> fetchCompletedOrders() {
        return orderRepository.findByIsApprovedTrueAndIsProcessingFalseAndIsShippedTrueAndIsInvoicedTrue();
    }

    public List<Order> fetchCustomerCompletedOrders() {
        return orderRepository.findByIsApprovedTrueAndIsProcessingFalseAndIsShippedTrue();
    }
    public void saveOrder(Order order) {
        // Save the order to the database
        orderRepository.save(order);
    }
    public void deleteByCompany(UserLogin company) {
        orderRepository.deleteByCompany(company);
    }


    public List<Order> orderReadyToBeInvoiced() {
        return orderRepository.findByIsApprovedTrueAndIsProcessingFalseAndIsShippedTrueAndIsInvoicedFalse();
    }

    public List<Order> getOrdersByExpectedDelivery(String expectedDeliveryDate) {
        return orderRepository.findByExpectedDeliveryDateAndIsApprovedTrueAndIsProcessingFalseAndIsShippedFalse(expectedDeliveryDate);
    }


    public List<Order> findAllCompletedOrders() {
        // Use the repository method to fetch all completed orders
        return orderRepository.findAllByIsApprovedTrueAndIsProcessingFalseAndIsShippedTrueAndIsInvoicedTrue();
    }

    // Fetches all orders
    public List<Order> findAllOrders() {
        return orderRepository.findAll();
    }

    // Deletes a specific order
    public void deleteOrder(Order order) {
        orderRepository.delete(order);
    }
}
