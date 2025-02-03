package com.p3.syllesisfabrik.controller;

import com.p3.syllesisfabrik.model.UserLogin; // Importing the UserLogin model to retrieve user details like login code.
import com.p3.syllesisfabrik.service.EmailService; // Service that handles sending emails, such as sending the passcode.
import com.p3.syllesisfabrik.service.UserLoginService; // Service for interacting with the UserLoginRepository to find users by email.
import org.springframework.beans.factory.annotation.Autowired; // Autowired annotation allows Spring to inject dependencies automatically.
import org.springframework.stereotype.Controller; // Marks this class as a Spring MVC controller that handles HTTP requests.
import org.springframework.ui.Model; // Model is used to pass data to the view (e.g., success or error messages).
import org.springframework.web.bind.annotation.*; // Importing Spring annotations to handle HTTP requests like @GetMapping and @PostMapping.

@Controller // Defines this class as a controller in the Spring MVC framework.
@RequestMapping("/forget/passcode") // Base URL mapping for handling requests related to forgetting a passcode.
public class ForgetPasscodeController {

    @Autowired // Automatically injects the UserLoginService bean, which interacts with the repository to find user data.
    private UserLoginService userLoginService;

    @Autowired // Automatically injects the EmailService bean, which handles sending passcode emails.
    private EmailService emailService;

    // GET method to render the "forget passcode" page where users can enter their email to receive their passcode.
    @GetMapping
    public String showForgetPasscodePage() {
        return "forget_passcode";  // Returns the forget_passcode.html template to the user.
    }

    // POST method that handles the form submission when the user enters their email to receive the passcode.
    @PostMapping("/send")
    public String sendPasscode(@RequestParam String companyEmail, Model model) {
        // Find the user by the company email entered in the form.
        UserLogin userLogin = userLoginService.findByCompanyEmail(companyEmail);

        if (userLogin != null) {
            // If a user with the provided email exists, send the passcode via email.
            emailService.sendPasscodeEmail(companyEmail, userLogin.getLoginCode());
            model.addAttribute("message", "Passcode sent to your email!"); // Success message shown on the page.
        } else {
            // If no user is found, return an error message.
            model.addAttribute("error", "No account found with this email!"); // Error message shown on the page.
        }

        return "forget_passcode";  // Render the same forget_passcode.html page with the appropriate message.
    }
}
