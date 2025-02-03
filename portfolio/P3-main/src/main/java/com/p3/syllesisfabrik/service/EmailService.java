package com.p3.syllesisfabrik.service;

import org.springframework.beans.factory.annotation.Autowired; // Used to automatically inject JavaMailSender and Environment beans into this service.
import org.springframework.core.env.Environment; // Allows accessing environment variables and properties (like email configuration) in the Spring environment.
import org.springframework.mail.SimpleMailMessage; // A simple class for creating plain text email messages.
import org.springframework.mail.javamail.JavaMailSender; // The interface used to send emails using JavaMail, typically SMTP.
import org.springframework.stereotype.Service; // Marks the class as a service component, making it a Spring-managed bean and part of the service layer.
import java.util.List;
import com.p3.syllesisfabrik.model.CartItem;
import com.p3.syllesisfabrik.model.MenuItem;

@Service // Marks the class as a Spring service so that Spring will manage its lifecycle and enable dependency injection.
public class EmailService {

    @Autowired // Automatically injects an instance of JavaMailSender into this class at runtime.
    private JavaMailSender mailSender;

    @Autowired // Automatically injects the Environment object, which allows access to properties from the Spring configuration (like mail username).
    private Environment env;

    // Method to send a passcode recovery email with a professional format
    public void sendPasscodeEmail(String recipientEmail, String passcode) {
        // Creates a new email message using SimpleMailMessage, which is a helper class for creating emails.
        SimpleMailMessage message = new SimpleMailMessage();

        // Sets the recipient's email address (who will receive this email).
        message.setTo(recipientEmail);

        // Sets the subject line of the email.
        message.setSubject("Your Secure 6-digit Passcode");

        // Formats the body of the email, including the passcode. It uses String.format to inject the passcode into the message.
        String emailContent = String.format(
                "Dear User,\n\n" +
                        "We have received a request to recover your passcode.\n" +
                        "Please use the following secure 6-digit passcode to access your account:\n\n" +
                        "Passcode: %s\n\n" +
                        "If you did not request this, please contact our support team immediately.\n\n" +
                        "Best regards,\n" +
                        "Sylles Isfabrik", passcode);

        // Sets the content of the email message.
        message.setText(emailContent);

        // Sets the "from" address for the email using the configured email address from the environment properties.
        message.setFrom(env.getProperty("spring.mail.username"));

        // Sends the email using the injected JavaMailSender instance.
        mailSender.send(message);
    }

    //EmailService.java Snippet Start
    // Method to send a welcome email when the user logs in for the first time
    public void sendUserInfo(String recipientEmail, String companyCVR, String companyName, String loginCode, String phoneNumber, String streetName, String streetNumber, String postcode, String city) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(recipientEmail);
        message.setSubject("Welcome to Syllesisfabrik Portal");

        String emailContent = String.format(
                "Dear %s,\n\n" +
                        "Welcome to the Syllesisfabrik Portal! You can access the portal using your unique 6-digit login code:\n\n" +
                        "CVR: %s\n\n" +
                        "Login Code: %s\n\n" +
                        "Company Contact Information:\n" +
                        "Phone Number: %s\n" +
                        "Address: %s %s, %s %s\n\n" +
                        "Best regards,\n" +
                        "Sylles Isfabrik", companyName, companyCVR, loginCode, phoneNumber, streetName, streetNumber, postcode, city);

        message.setText(emailContent);
        message.setFrom(env.getProperty("spring.mail.username"));
        mailSender.send(message);
    }
    //EmailService.java Snippet End
    public void sendOrderProcessingEmail(String recipientEmail, List<CartItem> cartItems, double totalOrderCost) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(recipientEmail);
        message.setSubject("Order Confirmation - Syllesisfabrik");

        // Build the order details content
        StringBuilder orderDetails = new StringBuilder("Dear Customer,\n\n")
                .append("Thank you for your order! Your order is now being processed. Below are the details:\n\n");

        for (CartItem item : cartItems) {
            MenuItem menuItem = item.getMenuItem();
            orderDetails.append("Item: ")
                    .append(menuItem.getTitle()) // Access title instead of name
                    .append("\nQuantity: ")
                    .append(item.getDesiredQuantity())
                    .append(" liters") // Assuming quantity is in liters
                    .append("\nLiter Price: ")
                    .append(menuItem.getPricePerLiter())
                    .append(" DKK per liter")
                    .append("\nTotal: ")
                    .append(item.getTotalCost())
                    .append(" DKK\n\n");
        }

        orderDetails.append("Total Order Cost: ")
                .append(totalOrderCost)
                .append(" DKK\n\nThank you for choosing Syllesisfabrik!\n\nBest regards,\nSylles Isfabrik");

        message.setText(orderDetails.toString());
        message.setFrom(env.getProperty("spring.mail.username"));

        mailSender.send(message);
    }

    //service/EmailService.java Snippet Start
    public void sendOrderConfirmationEmail(String recipientEmail, List<CartItem> cartItems, double totalOrderCost, String expectedDeliveryDate, String companyName, String address) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(recipientEmail);
        message.setSubject("Order Confirmation - Syllesisfabrik");

        // Build the order confirmation content
        StringBuilder orderDetails = new StringBuilder("Dear Customer,\n\n")
                .append("We are pleased to confirm that your order has been received and is now confirmed. Below are the details:\n\n");

        // Adding expected delivery date before the order items
        orderDetails.append("Expected Delivery Date: ")
                .append(expectedDeliveryDate)
                .append("\n\n");

        // Adding delivery address
        orderDetails.append("Delivery Address:\n")
                .append(companyName)
                .append("\n")
                .append(address)
                .append("\n\n");

        // Adding order items to the email
        for (CartItem item : cartItems) {
            MenuItem menuItem = item.getMenuItem();
            orderDetails.append("Item: ")
                    .append(menuItem.getTitle()) // Access title instead of name
                    .append("\nQuantity: ")
                    .append(item.getDesiredQuantity())
                    .append(" liters") // Assuming quantity is in liters
                    .append("\nLiter Price: ")
                    .append(menuItem.getPricePerLiter())
                    .append(" DKK per liter")
                    .append("\nTotal: ")
                    .append(item.getTotalCost())
                    .append(" DKK\n\n");
        }

        // Add total order cost
        orderDetails.append("Total Order Cost: ")
                .append(totalOrderCost)
                .append(" DKK\n\n");

        // Final note
        orderDetails.append("Thank you for choosing Syllesisfabrik!\n\nBest regards,\nSylles Isfabrik");

        message.setText(orderDetails.toString());
        message.setFrom(env.getProperty("spring.mail.username"));

        mailSender.send(message);
    }
    //service/EmailService.java Snippet End
    public void sendDisapprovalEmail(String recipientEmail, String companyName, String disapprovalReason, List<CartItem> cartItems, double totalOrderCost) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(recipientEmail);
        message.setSubject("Order Disapproval - Syllesisfabrik");

        // Build the email content
        StringBuilder emailContent = new StringBuilder("Dear " + companyName + ",\n\n") // Using the company name here
                .append("We regret to inform you that your order has been disapproved. Below are the details of your order:\n\n");

        // Add the disapproval reason if provided
        if (disapprovalReason != null && !disapprovalReason.isEmpty()) {
            emailContent.append("Reason for Disapproval: ").append(disapprovalReason).append("\n\n");
        } else {
            emailContent.append("Unfortunately, we are unable to process your order at this time.\n\n");
        }

        // Add the order details (items and total cost)
        emailContent.append("Order Details:\n");
        for (CartItem item : cartItems) {
            MenuItem menuItem = item.getMenuItem();
            emailContent.append("Item: ")
                    .append(menuItem.getTitle())
                    .append("\nQuantity: ")
                    .append(item.getDesiredQuantity())
                    .append(" liters")
                    .append("\nLiter Price: ")
                    .append(menuItem.getPricePerLiter())
                    .append(" DKK per liter")
                    .append("\nTotal: ")
                    .append(item.getTotalCost())
                    .append(" DKK\n\n");
        }

        emailContent.append("Total Order Cost: ")
                .append(totalOrderCost)
                .append(" DKK\n\n")
                .append("Thank you for your understanding.\n\nBest regards,\nSylles Isfabrik");

        message.setText(emailContent.toString());
        message.setFrom(env.getProperty("spring.mail.username"));

        mailSender.send(message);
    }

    public void sendShippedOrderEmail(String recipientEmail, List<CartItem> cartItems, double totalOrderCost, String companyName) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(recipientEmail);
        message.setSubject("Order Delivered - Syllesisfabrik");

        // Build the order shipped email content
        StringBuilder orderDetails = new StringBuilder("Dear ").append(companyName).append(",\n\n")
                .append("We are pleased to inform you that your order has been delivered to you.\n\n");

        // Adding order details (cart items)
        orderDetails.append("Here are the details of your order:\n\n");

        for (CartItem item : cartItems) {
            MenuItem menuItem = item.getMenuItem();
            orderDetails.append("Item: ")
                    .append(menuItem.getTitle())  // Item title
                    .append("\nQuantity: ")
                    .append(item.getDesiredQuantity())
                    .append(" liters\n")
                    .append("Liter Price: ")
                    .append(menuItem.getPricePerLiter())
                    .append(" DKK per liter\n")
                    .append("Total: ")
                    .append(item.getTotalCost())
                    .append(" DKK\n\n");
        }

        // Adding total order cost
        orderDetails.append("Total Order Cost: ")
                .append(totalOrderCost)
                .append(" DKK\n\n");

        // Add shipping notification
        orderDetails.append("Thank you for your purchase!\n\n")
                .append("Best regards,\n")
                .append("Sylles Isfabrik\n\n");

        // Set the email content
        message.setText(orderDetails.toString());
        message.setFrom(env.getProperty("spring.mail.username"));

        // Send the email
        mailSender.send(message);
    }


}
