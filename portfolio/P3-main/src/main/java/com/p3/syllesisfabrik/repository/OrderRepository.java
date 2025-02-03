package com.p3.syllesisfabrik.repository;

import com.p3.syllesisfabrik.model.Order;
import com.p3.syllesisfabrik.model.UserLogin;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface OrderRepository extends MongoRepository<Order, String> {
    // Find orders where isProcessing is true, isApproved is false, and isShipped is false
    List<Order> findByIsProcessingAndIsApprovedFalseAndIsShippedFalse(boolean isProcessing);

    // New method for fetching orders ready to be shipped
    List<Order> findByIsApprovedTrueAndIsProcessingFalseAndIsShippedFalse();

    List<Order> findByIsApprovedTrueAndIsProcessingFalseAndIsShippedTrue();
    void deleteByCompany(UserLogin company);


    List<Order> findByIsApprovedTrueAndIsProcessingFalseAndIsShippedTrueAndIsInvoicedTrue();

    List<Order> findByIsApprovedTrueAndIsProcessingFalseAndIsShippedTrueAndIsInvoicedFalse();




    List<Order> findByExpectedDeliveryDateAndIsApprovedTrueAndIsProcessingFalseAndIsShippedFalse(String expectedDeliveryDate);



    List<Order> findAllByIsApprovedTrueAndIsProcessingFalseAndIsShippedTrueAndIsInvoicedTrue();
}
