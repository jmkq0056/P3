package com.p3.syllesisfabrik.service;

import com.p3.syllesisfabrik.model.UserLogin; // The UserLogin entity class that maps to the user data in the database.
import com.p3.syllesisfabrik.repository.UserLoginRepository; // The repository interface for interacting with the UserLogin table in the database.
import org.springframework.beans.factory.annotation.Autowired; // Annotation used for dependency injection, allowing Spring to inject components (like the repository).
import org.springframework.stereotype.Service; // Marks the class as a Spring service, making it eligible for Spring's component scanning and dependency injection.

import java.util.List;

@Service // Defines this class as a Spring service, making it a Spring-managed bean. It handles business logic for user login.
public class UserLoginService {

    @Autowired // This tells Spring to automatically inject an instance of UserLoginRepository at runtime.
    private UserLoginRepository userLoginRepository;

    // Finds a user in the database by their 6-digit login code.
    public UserLogin findByLoginCode(String loginCode) {
        // Uses the repository method to fetch a user based on the provided login code.
        return userLoginRepository.findByLoginCode(loginCode);
    }

    // Saves or updates the user's JWT token in the database.
    public void saveUserWithToken(UserLogin userLogin, String jwtToken) {
        // Sets the JWT token for the user to be stored in the database.
        userLogin.setJwtToken(jwtToken);
        // Saves or updates the user record with the new token.
        userLoginRepository.save(userLogin);
    }

    // Fetch all users from the database
    public List<UserLogin> findAll() {
        return userLoginRepository.findAll(); // Assuming UserLoginRepository extends JpaRepository or similar
    }
    // Save a new user to the database.
    public void saveUser(UserLogin userLogin) {
        userLoginRepository.save(userLogin); // Save the new user login details to the database.
    }

    // Method to check if the generated login code already exists in the database.
    public boolean isDuplicateGeneratedCode(String loginCode) {
        return userLoginRepository.existsByLoginCode(loginCode);
    }


    public void deleteByCompanyEmail(String companyEmail) {
        UserLogin userLogin = userLoginRepository.findByCompanyEmail(companyEmail);
        if (userLogin != null) {
            userLoginRepository.delete(userLogin);
        }
    }

    // Checks if a company name or email already exists in the database, used to avoid creating duplicate entries.
    public boolean isDuplicate(String companyName, String companyEmail, String companyCVR, String phoneNumber) {
        // Queries the repository to see if either the company name or company email already exists in the database.
        return userLoginRepository.existsByCompanyName(companyName) ||
                userLoginRepository.existsByCompanyEmail(companyEmail) || userLoginRepository.existsByCompanyCVR(companyCVR) || userLoginRepository.existsByPhoneNumber(phoneNumber);
    }

    // Finds a user in the database by their company email, often used for admin login or user lookup by email.
    public UserLogin findByCompanyEmail(String companyEmail) {
        // Uses the repository to fetch a user based on the provided company email.
        return userLoginRepository.findByCompanyEmail(companyEmail);
    }

    // Creates the admin user in the database if they don't already exist. This ensures that an admin account is always available.
    //MAINLY CREATED BEACUSE we store the token in dzatabase for the users even if its an admin
    public void createAdminIfNotExists() {
        // Checks if an admin user with the company name "Syllesis Fabrik" already exists.
        if (!userLoginRepository.existsByCompanyName("Syllesis Fabrik")) {
            // If not, create a new UserLogin object for the admin user with default login details.
            UserLogin adminUser = new UserLogin("REMOVED_FOR_SECURITY","Syllesis Fabrik", "admin@syllesisfabrik.com", "REMOVED_FOR_SECURITY", "special", null, null, null, null, null);

            // Save the new admin user to the database.
            userLoginRepository.save(adminUser);
        }
    }

    public UserLogin findByCompanyName(String companyName) {
        return userLoginRepository.findByCompanyName(companyName);
    }
    public void save(UserLogin userLogin) {
        userLoginRepository.save(userLogin); // Spring Data MongoDB handles the persistence
    }

    public boolean existsByCompanyCVRAndIdNot(String companyCVR, String id) {
        return userLoginRepository.existsByCompanyCVRAndIdNot(companyCVR, id);
    }

    public boolean existsByCompanyEmailAndIdNot(String companyEmail, String id) {
        return userLoginRepository.existsByCompanyEmailAndIdNot(companyEmail, id);
    }

    public boolean existsByCompanyNameAndIdNot(String companyName, String id) {
        return userLoginRepository.existsByCompanyNameAndIdNot(companyName, id);
    }

    public boolean existsByPhoneNumberAndIdNot(String phoneNumber, String id) {
        return userLoginRepository.existsByPhoneNumberAndIdNot(phoneNumber, id);
    }
}
