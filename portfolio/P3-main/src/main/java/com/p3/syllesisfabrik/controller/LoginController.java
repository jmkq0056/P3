package com.p3.syllesisfabrik.controller;

import com.p3.syllesisfabrik.model.UserLogin; // Importing the UserLogin model to interact with user login data in the database.
import com.p3.syllesisfabrik.service.UserLoginService; // Service for interacting with UserLoginRepository to manage user data.
import com.p3.syllesisfabrik.util.JwtUtil; // Utility class for generating and validating JWT tokens.
import org.springframework.beans.factory.annotation.Autowired; // Autowired annotation for injecting dependencies automatically.
import org.springframework.stereotype.Controller; // Marks this class as a Spring MVC controller that handles HTTP requests.
import org.springframework.ui.Model; // Model is used to pass data from controller to the view (HTML pages).
import org.springframework.web.bind.annotation.*; // Importing Spring annotations to handle HTTP requests (GET and POST).
import org.slf4j.Logger; // Logger for logging information and errors.
import org.slf4j.LoggerFactory; // Factory for creating logger instances.

@Controller // Marks this class as a controller in the Spring MVC framework.
@RequestMapping("/login") // Base URL mapping for all requests related to login.
public class LoginController {

    private static final Logger logger = LoggerFactory.getLogger(LoginController.class); // Logger for logging actions and errors.
    private static final String ADMIN_PASSCODE = "A1b2C3d4E5f6G7!"; // Hardcoded admin passcode for simplified admin login.

    @Autowired // Automatically injects the UserLoginService to interact with user login data.
    private UserLoginService userLoginService;

    @Autowired // Automatically injects JwtUtil for generating and validating JWT tokens.
    private JwtUtil jwtUtil;

    // GET method for rendering the login page.
    @GetMapping
    public String showLoginPage() {
        logger.info("Rendering login page");

        // Ensure that the admin user exists in the database, creates one if not.
        userLoginService.createAdminIfNotExists();

        return "login";  // Return the login.html view (make sure this template exists in the templates folder).
    }

    // POST method to validate the login code entered by the user.
    @PostMapping("/validate")
    public String validateLogin(@RequestParam String loginCode, Model model) {
        logger.info("Received login code: " + loginCode);

        // Check if the login code matches the hardcoded admin passcode.
        if (ADMIN_PASSCODE.equals(loginCode)) {
            logger.info("Admin logged in successfully");

            // Generate JWT token for admin.
            String jwtToken = jwtUtil.generateToken("admin");

            // Find the admin user and save the JWT token.
            UserLogin adminUser = userLoginService.findByCompanyEmail("admin@syllesisfabrik.com");
            userLoginService.saveUserWithToken(adminUser, jwtToken);

            // Redirect to the admin home page with the token as a URL parameter.
            return "redirect:/admin/home?token=" + jwtToken;
        }

        // Check if the login code exists in the database for a normal user.
        UserLogin userLogin = userLoginService.findByLoginCode(loginCode);
        if (userLogin != null) {
            logger.info("User logged in successfully with company: " + userLogin.getCompanyName());

            // Generate JWT token for the user.
            String jwtToken = jwtUtil.generateToken(userLogin.getCompanyName());
            userLoginService.saveUserWithToken(userLogin, jwtToken);

            // Redirect to the user home page with the token as a URL parameter.
            return "redirect:/user/home?token=" + jwtToken;
        } else {
            // If the login code is invalid, log the error and return an error message.
            logger.error("Invalid login code");
            model.addAttribute("error", "Invalid login code.");
            return "login"; // Stay on the login page if the login code is invalid.
        }
    }



}
