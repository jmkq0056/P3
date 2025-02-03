package com.p3.syllesisfabrik.repository;

import com.p3.syllesisfabrik.model.UserLogin; // Importing the UserLogin model to manage UserLogin entities.
import org.springframework.data.mongodb.repository.MongoRepository; // MongoRepository provides standard CRUD operations for MongoDB.
import java.util.Optional; // Optional is used to handle cases where the result may or may not be present.

// Repository interface for managing UserLogin entities in MongoDB
public interface UserLoginRepository extends MongoRepository<UserLogin, String> {

    //spring.data.mongodb make queries to the mongodb by itself based on naming and parameters
    //Query derivation is it called
    UserLogin findByCompanyName(String companyName); // Custom query method
    // Find a user by their login code
    // This method will return the UserLogin object associated with the given login code
    UserLogin findByLoginCode(String loginCode);

    // Find a user by their company email
    // This method will return the UserLogin object associated with the given company email
    UserLogin findByCompanyEmail(String companyEmail);

    // Check if a login code already exists in the database
    // Returns true if a user with the given login code exists, otherwise false
    boolean existsByLoginCode(String loginCode);

    // Check if a company name already exists in the database
    // Returns true if a user with the given company name exists, otherwise false
    boolean existsByCompanyName(String companyName);

    boolean existsByCompanyCVR(String companyCVR);

    // Check if a company email already exists in the database
    // Returns true if a user with the given company email exists, otherwise false
    boolean existsByCompanyEmail(String companyEmail);
    boolean existsByPhoneNumber(String phoneNumber);

    boolean existsByCompanyCVRAndIdNot(String companyCVR, String id);
    boolean existsByCompanyEmailAndIdNot(String companyEmail, String id);
    boolean existsByCompanyNameAndIdNot(String companyName, String id);
    boolean existsByPhoneNumberAndIdNot(String phoneNumber, String id);



}
