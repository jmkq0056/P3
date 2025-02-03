package com.p3.syllesisfabrik.controller;

import com.p3.syllesisfabrik.model.CartItem;
import com.p3.syllesisfabrik.model.MenuItem;
import com.p3.syllesisfabrik.model.UserLogin;
import com.p3.syllesisfabrik.model.Order;
import com.p3.syllesisfabrik.service.*;
import com.p3.syllesisfabrik.util.JwtUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;

@Controller
@RequestMapping("/user")
public class UserController {

    private static final Logger logger = LoggerFactory.getLogger(UserController.class);

    @Autowired
    private MenuItemService menuItemService;

    @Autowired
    private CartItemService cartItemService;

    @Autowired
    private EmailService emailService;

    @Autowired
    private UserLoginService userLoginService;

    @Autowired
    private OrderService orderService;

    @Autowired
    private JwtUtil jwtUtil;


    //contoller/UserController.java Snippet Start
    private String validateToken(String token, Model model) {
        if (token == null) {
            logger.error("Access denied. Token is null.");
            model.addAttribute("error", "Access denied. Please log in with a valid token.");
            return null;
        }

        // Extract username from the token
        String username = jwtUtil.extractUsername(token);

        // Validate the token
        if (!jwtUtil.validateToken(token, username)) {
            logger.error("Access denied. Invalid or expired token for user: {}", username);
            model.addAttribute("error", "Access denied. Invalid or expired token.");
            return null;
        }

        // Fetch user from the database
        UserLogin userLogin = userLoginService.findByCompanyName(username);
        if (userLogin == null) {
            logger.error("Access denied. User not found in the database for username: {}", username);
            model.addAttribute("error", "Access denied. User not found, or the company name has changed. Please log in again.");
            return null;
        }

        // Compare token in database with the provided token
        if (!token.equals(userLogin.getToken())) {
            logger.error("Access denied. Token mismatch for user: {}. Token does not match the one stored in the database.", username);
            model.addAttribute("error", "Access denied. Invalid token.");
            return null;
        }

        logger.info("Token validation successful for user: {}", username);
        return username; // Return the username if the token is valid
    }


    // GET method for displaying the user's home page with token validation.
    @GetMapping("/home")
    public String showUserHome(@RequestParam("token") String token, Model model) {
        // Extract username (or company name) from the JWT token.
        String companyName = jwtUtil.extractUsername(token);

        // Validate the token, ensuring it is valid and not expired.
        if (jwtUtil.validateToken(token, companyName)) {
            logger.info("Valid token, rendering user home for: " + companyName);
            model.addAttribute("companyName", companyName);  // Pass the company name to the view.
            model.addAttribute("token", token);
            return "user_home";  // Render user_home.html page if the token is valid.
        } else {
            // If the token is invalid or expired, log the error and return an error message.
            logger.error("Invalid or expired token.");
            model.addAttribute("error", "Invalid or expired token.");
            return "login";  // Redirect back to the login page if the token is invalid.
        }
    }

    @GetMapping("/place/order")
    public String renderPlaceOrderPage(@RequestParam("token") String token, Model model) {
        String companyName = validateToken(token, model);
        if (companyName == null) {
            return "login"; // Redirect to login if token is invalid
        }

        logger.info("Rendering place_order page for: " + companyName);

        List<MenuItem> menuItems = menuItemService.findAll();
        menuItems.forEach(menuItem -> {
            if (menuItem.getImagePaths() != null && menuItem.getImagePaths().isEmpty()) {
                menuItem.setImagePaths(null); // Set to null if empty
            }
        });
        model.addAttribute("menuItems", menuItems);
        model.addAttribute("companyName", companyName);
        model.addAttribute("token", token);

        return "place_order"; // Render the place_order.html page if token is valid
    }

    //contoller/UserController.java Snippet End

    //contoller/UserController.java Snippet Start
    @PostMapping("/add-to-cart")
    public String addToCart(@RequestParam("menuItemId") String menuItemId,
                            @RequestParam("desiredQuantity") int desiredQuantity,
                            @RequestParam("token") String token, RedirectAttributes redirectAttributes,
                            Model model) {

        String companyName = validateToken(token, model);
        if (companyName == null) {
            return "login"; // Redirect to login if token is invalid
        }

        // Check for zero or negative quantity
        if (desiredQuantity <= 0) {
            redirectAttributes.addFlashAttribute("error", "Quantity must be greater than zero.");
            return "redirect:/user/place/order?token=" + token;
        }

        UserLogin company = userLoginService.findByCompanyName(companyName);
        if (company == null) {
            redirectAttributes.addFlashAttribute("error", "Company not found.");
            return "redirect:/user/place/order?token=" + token;
        }

        Optional<MenuItem> menuItemOptional = menuItemService.findById(menuItemId);
        if (!menuItemOptional.isPresent()) {
            redirectAttributes.addFlashAttribute("error", "Menu item not found.");
            return "redirect:/user/place/order?token=" + token;
        }

        MenuItem menuItem = menuItemOptional.get();

        // Find cart items where the company has the menu item and ordered = false
        List<CartItem> existingCartItems = cartItemService.findItemsByCompanyAndMenuItemAndOrderedFalse(company, menuItem);
        double currentCartQuantity = existingCartItems.stream().mapToDouble(CartItem::getDesiredQuantity).sum();
        double totalDesiredQuantity = currentCartQuantity + desiredQuantity;

        // Check if total quantity exceeds available stock
        if (totalDesiredQuantity > menuItem.getQuantity()) {
            redirectAttributes.addFlashAttribute("error", "You already have " + menuItem.getTitle() + " in your cart. Adding this quantity would exceed the available stock.");
            return "redirect:/user/place/order?token=" + token;
        }

        // Calculate total cost
        double totalCost = desiredQuantity * menuItem.getPricePerLiter();

        // Create and save the CartItem with a reference to the company
        CartItem cartItem = new CartItem(menuItem, company, desiredQuantity, totalCost);
        cartItemService.save(cartItem);

        // Success message
        redirectAttributes.addFlashAttribute("message",  menuItem.getTitle() + " variant added to cart successfully!");

        // Redirect back to place order page
        return "redirect:/user/place/order?token=" + token;
    }
    //contoller/UserController.java Snippet End


    @GetMapping("/order/history")
    public String orderHistory(@RequestParam("token") String token, Model model) {
        String companyName = validateToken(token, model);
        if (companyName == null) {
            return "login"; // Redirect to login if token is invalid
        }

        UserLogin company = userLoginService.findByCompanyName(companyName);
        if (company == null) {
            logger.error("Company not found: " + companyName);
            model.addAttribute("error", "Company not found.");
            return "order_history";
        }

        // Fetch all orders
        List<Order> allCurrentOrders = orderService.fetchCurrentOrders();
        List<Order> allUnshippedOrders = orderService.fetchReadyToBeShippedOrders();
        List<Order> allDeliveredOrders = orderService.fetchCustomerCompletedOrders();

        // Filter orders by company name
        List<Order> currentOrders = allCurrentOrders.stream()
                .filter(order -> order.getCompany().getCompanyName().equalsIgnoreCase(companyName))
                .toList();

        List<Order> unshippedOrders = allUnshippedOrders.stream()
                .filter(order -> order.getCompany().getCompanyName().equalsIgnoreCase(companyName))
                .toList();

        List<Order> deliveredOrders = allDeliveredOrders.stream()
                .filter(order -> order.getCompany().getCompanyName().equalsIgnoreCase(companyName))
                .toList();

        // Add data to the model
        model.addAttribute("companyName", companyName);
        model.addAttribute("token", token);
        model.addAttribute("currentOrders", currentOrders);
        model.addAttribute("unshippedOrders", unshippedOrders);
        model.addAttribute("deliveredOrders", deliveredOrders);

        return "order_history";
    }

    @GetMapping("/edit/profile")
    public String editProfile(@RequestParam("token") String token, Model model) {
        String companyName = validateToken(token, model);
        if (companyName == null) {
            return "login"; // Redirect to login if token is invalid
        }

        UserLogin company = userLoginService.findByCompanyName(companyName);
        if (company == null) {
            logger.error("Company not found: " + companyName);
            model.addAttribute("error", "Company not found.");
            return "edit_profile";
        }

        // Add all company details to the model
        model.addAttribute("companyName", company.getCompanyName());
        model.addAttribute("companyEmail", company.getCompanyEmail());
        model.addAttribute("phoneNumber", company.getPhoneNumber());
        model.addAttribute("streetName", company.getStreetName());
        model.addAttribute("streetNumber", company.getStreetNumber());
        model.addAttribute("postcode", company.getPostcode());
        model.addAttribute("city", company.getCity());
        model.addAttribute("cvr", company.getCompanyCVR());
        model.addAttribute("token", token);

        return "edit_profile";
    }


    @PostMapping("/edit/profile/make-changes")
    public String updateProfile(
            @RequestParam String companyCVR,
            @RequestParam String companyName,
            @RequestParam String companyEmail,
            @RequestParam String phoneNumber,
            @RequestParam String streetName,
            @RequestParam String streetNumber,
            @RequestParam String postcode,
            @RequestParam String city,
            @RequestParam String token,
            RedirectAttributes redirectAttributes,
            Model model) {

        // Validate the token and get the company name
        String validatedCompanyName = validateToken(token, model);
        if (validatedCompanyName == null) {
            return "login"; // Redirect to login if the token is invalid
        }

        // Fetch the existing company profile using the validated name
        UserLogin company = userLoginService.findByCompanyName(validatedCompanyName);
        if (company == null) {
            redirectAttributes.addFlashAttribute("error", "Your session has expired or the company name has changed. Please log in again.");
            return "redirect:/login"; // Redirect to the login page
        }

        // Validate input fields
        if (companyCVR.length() != 8 || !companyCVR.matches("\\d+")) {
            redirectAttributes.addFlashAttribute("error", "Company CVR must be exactly 8 numeric digits.");
            return "redirect:/user/edit/profile?token=" + token;
        }

        if (!phoneNumber.matches("\\d{8}")) {
            redirectAttributes.addFlashAttribute("error", "Phone number must consist of exactly 8 digits.");
            return "redirect:/user/edit/profile?token=" + token;
        }

        if (!postcode.matches("\\d+")) {
            redirectAttributes.addFlashAttribute("error", "Postcode must consist of numeric digits only.");
            return "redirect:/user/edit/profile?token=" + token;
        }

        if (city.matches("\\d+")) {
            redirectAttributes.addFlashAttribute("error", "City name cannot be numeric.");
            return "redirect:/user/edit/profile?token=" + token;
        }

        if (streetName.matches(".*\\d.*")) {
            redirectAttributes.addFlashAttribute("error", "Street name cannot contain any digits.");
            return "redirect:/user/edit/profile?token=" + token;
        }

        // Check for uniqueness of companyCVR, companyEmail, companyName, phoneNumber, and loginCode
        if (userLoginService.existsByCompanyCVRAndIdNot(companyCVR, company.getId())) {
            redirectAttributes.addFlashAttribute("error", "Company CVR already exists.");
            return "redirect:/user/edit/profile?token=" + token;
        }

        if (userLoginService.existsByCompanyEmailAndIdNot(companyEmail, company.getId())) {
            redirectAttributes.addFlashAttribute("error", "Company email already exists.");
            return "redirect:/user/edit/profile?token=" + token;
        }

        if (userLoginService.existsByCompanyNameAndIdNot(companyName, company.getId())) {
            redirectAttributes.addFlashAttribute("error", "Company name already exists.");
            return "redirect:/user/edit/profile?token=" + token;
        }

        if (userLoginService.existsByPhoneNumberAndIdNot(phoneNumber, company.getId())) {
            redirectAttributes.addFlashAttribute("error", "Phone number already exists.");
            return "redirect:/user/edit/profile?token=" + token;
        }

        // Update the company's profile
        try {
            company.setCompanyCVR(companyCVR);
            company.setCompanyName(companyName);
            company.setCompanyEmail(companyEmail);
            company.setPhoneNumber(phoneNumber);
            company.setStreetName(streetName);
            company.setStreetNumber(streetNumber);
            company.setPostcode(postcode);
            company.setCity(city);

            // Save the updated company profile
            userLoginService.saveUser(company);

            redirectAttributes.addFlashAttribute("message", "Profile updated successfully.");
        } catch (Exception e) {
            logger.error("Error updating profile for company: " + validatedCompanyName, e);
            redirectAttributes.addFlashAttribute("error", "Failed to update profile: " + e.getMessage());
        }

        // Redirect back to the edit profile page with the token
        return "redirect:/user/edit/profile?token=" + token;
    }




    @GetMapping("/view-cart")
    public String viewCart(@RequestParam("token") String token, Model model) {
        String companyName = validateToken(token, model);
        if (companyName == null) {
            return "login"; // Redirect to login if token is invalid
        }

        UserLogin company = userLoginService.findByCompanyName(companyName);
        if (company == null) {
            logger.error("Company not found: " + companyName);
            model.addAttribute("error", "Company not found.");
            return "place_order";
        }

        List<CartItem> cartItems = cartItemService.findUnorderedItemsByCompany(company);

        model.addAttribute("cartItems", cartItems);
        model.addAttribute("companyName", companyName);
        model.addAttribute("token", token);

        return "view_cart"; // Renders view_cart.html page
    }

    @PostMapping("/remove-from-cart")
    public String removeFromCart(@RequestParam("cartItemId") String cartItemId,
                                 @RequestParam("token") String token,
                                 Model model) {

        String companyName = validateToken(token, model);
        if (companyName == null) {
            return "login"; // Redirect to login if token is invalid
        }

        cartItemService.deleteById(cartItemId);

        logger.info("Removed item from cart: " + cartItemId + " for company: " + companyName);

        // Redirect back to the view cart page
        return "redirect:/user/view-cart?token=" + token;
    }
    //contoller/UserController.java Snippet Start
    @PostMapping("/checkout")
    public String checkout(@RequestParam("token") String token, RedirectAttributes redirectAttributes, Model model) {
        // Validate the token and get the username (company name)
        String companyName = validateToken(token, model);
        if (companyName == null) {
            return "login";
        }

        // Retrieve the UserLogin object by company name
        UserLogin userLogin = userLoginService.findByCompanyName(companyName);
        if (userLogin == null) {
            model.addAttribute("error", "Company not found.");
            return "view_cart";
        }

        // Get all unordered items (where isOrdered is false) in the cart for this user
        List<CartItem> cartItems = cartItemService.findUnorderedItemsByCompany(userLogin);

        // Check if cart items are empty (i.e., no unordered items)
        if (cartItems.isEmpty()) {
            // If there are no unordered items, redirect back to the cart page with an error message
            redirectAttributes.addFlashAttribute("error", "No order made. Cart is empty.");
            return "redirect:/user/view-cart?token=" + token;
        }

        // Calculate the total cost of the order
        double totalOrderCost = cartItems.stream().mapToDouble(CartItem::getTotalCost).sum();

        // Create a new Order object with the user's information
        Order order = new Order();
        order.setCompany(userLogin); // Using UserLogin object for company information
        order.setCartItems(cartItems);
        order.setTotalPrice(totalOrderCost);

        // Get current time and format it before saving
        LocalDateTime currentDateTime = LocalDateTime.now();
        order.setOrderDate(currentDateTime);  // Store raw LocalDateTime in the database

        // Format the date for display
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
        String formattedDate = currentDateTime.format(formatter);
        order.setFormattedOrderDate(formattedDate);  // Store formatted date as a string for frontend display

        // Set other fields
        order.setApproved(false);
        order.setProcessing(true);
        order.setShipped(false);
        order.setInvoiced(false);
        order.setExpectedDeliveryDate("Unknown");

        // Save the order with both raw and formatted date
        orderService.save(order);

        // Update cart items to mark them as ordered
        cartItemService.updateOrderedStatus(cartItems, true);

        // Send an order confirmation email to the company
        emailService.sendOrderProcessingEmail(userLogin.getCompanyEmail(), cartItems, totalOrderCost);

        model.addAttribute("success", "Order placed successfully!");
        return "order_confirmation";
    }
    //contoller/UserController.java Snippet End

    /**
     * Logs out the user by invalidating the JWT token and setting it to null in the database.
     */
    @PostMapping("/logout")
    public String logout(@RequestParam("token") String token, RedirectAttributes redirectAttributes) {
        // Extract the username from the token
        String username = jwtUtil.extractUsername(token);

        if (username != null && jwtUtil.validateToken(token, username)) {
            jwtUtil.invalidateToken(token); // Invalidate the token
            logger.info("User " + username + " has been logged out successfully.");
            redirectAttributes.addFlashAttribute("message", "You have been logged out successfully.");
        }

        // Redirect to login page after logout
        return "redirect:/login";
    }

}



