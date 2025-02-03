package com.p3.syllesisfabrik.controller;

import com.p3.syllesisfabrik.model.*;
import com.p3.syllesisfabrik.service.*;
import com.p3.syllesisfabrik.util.JwtUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.PrintWriter;
import java.util.List;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.*;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;

@Controller
@RequestMapping("/admin")
public class AdminController {

    private static final Logger logger = LoggerFactory.getLogger(AdminController.class);

    @Autowired
    private MenuItemService menuItemService;

    @Autowired
    private OrderService orderService;

    @Autowired
    private CartItemService cartItemService;


    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private EmailService emailService;

    @Autowired
    private ImageUploadService imageUploadService;


    @Autowired
    private UserLoginService userLoginService;

    private boolean validateAdminToken(String token, Model model) {
        if (token == null) {
            logger.error("Access denied. Token is null.");
            model.addAttribute("error", "Access denied. Please log in with a valid token.");
            return false;
        }

        // Validate the token and check if it is associated with "admin"
        if (!jwtUtil.validateToken(token, "admin")) {
            logger.error("Access denied. Invalid or expired token for admin.");
            model.addAttribute("error", "Access denied. Invalid or expired token.");
            return false;
        }

        // Fetch the admin user from the database
        UserLogin adminUser = userLoginService.findByCompanyName("Syllesis Fabrik");
        if (adminUser == null) {
            logger.error("Access denied. Admin user not found in the database.");
            model.addAttribute("error", "Access denied. Admin user not found.");
            return false;
        }

        // Compare token in the database with the provided token
        if (!token.equals(adminUser.getToken())) {
            logger.error("Access denied. Token mismatch for admin. Token does not match the one stored in the database.");
            model.addAttribute("error", "Access denied. Invalid token.");
            return false;
        }

        logger.info("Token validation successful for admin.");
        return true; // Return true if the token is valid and matches the database
    }



    //controller/adminController.java Snippet Start

    // Helper method to create a SalesByRange
    private SalesByRange createSalesByRange(String rangeLabel, LocalDate startDate, LocalDate endDate, List<Order> allOrders) {
        List<Order> filteredOrders = allOrders.stream()
                .filter(order -> {
                    LocalDate orderDate = order.getOrderDate().toLocalDate();
                    return !orderDate.isBefore(startDate) && !orderDate.isAfter(endDate);
                })
                .toList();

        double totalRevenue = filteredOrders.stream()
                .mapToDouble(Order::getTotalPrice)
                .sum();

        int totalOrders = filteredOrders.size();

        List<String> topSellingProducts = filteredOrders.stream()
                .flatMap(order -> order.getCartItems().stream())
                .map(cartItem -> cartItem.getMenuItem().getTitle())
                .distinct()
                .toList();

        return new SalesByRange(rangeLabel, startDate, endDate, totalRevenue, totalOrders, topSellingProducts);
    }
    @GetMapping("/home")
    public String showAdminHomePage(@RequestParam(value = "token", required = false) String token, Model model) {
        if (!validateAdminToken(token, model)) {
            return "login";
        }

        List<UserLogin> companies = userLoginService.findAll();
        List<MenuItem> menuItems = menuItemService.findAll();
        menuItems.forEach(menuItem -> {
            if (menuItem.getImagePaths() != null && menuItem.getImagePaths().isEmpty()) {
                menuItem.setImagePaths(null); // Set to null if empty
            }
        });
        // Fetch the current orders (with necessary filters for processing, not approved, and not shipped)
        List<Order> currentOrders = orderService.fetchCurrentOrders(); // You need to ensure this method fetches orders with companies
        List<Order> orderReadyToBeInvoiced = orderService.orderReadyToBeInvoiced();
        List<Order> orderCompleted = orderService.fetchCompletedOrders();
        // Print the current orders to the console (backend) for debugging
        // Fetch orders ready to be shipped (isApproved = true, isProcessing = false, isShipped = false)
        List<Order> orderReadyToBeShipped = orderService.fetchReadyToBeShippedOrders(); // New method for orders ready to be shipped

        // Add the necessary attributes to the model for rendering in the view
        model.addAttribute("currentOrders", currentOrders);
        model.addAttribute("menuItems", menuItems);
        model.addAttribute("companies", companies);
        model.addAttribute("token", token);

        logger.info("Admin access granted, displaying companies and menu items.");
        model.addAttribute("currentOrders", currentOrders);
        model.addAttribute("orderReadyToBeShipped", orderReadyToBeShipped);
        model.addAttribute("orderReadyToBeInvoiced", orderReadyToBeInvoiced);
        model.addAttribute("orderCompleted", orderCompleted);
        model.addAttribute("menuItems", menuItems);
        model.addAttribute("companies", companies);
        model.addAttribute("token", token);

        // Current date
        LocalDate now = LocalDate.now();
        List<Order> allOrders = orderService.findAllCompletedOrders();

        // Current date
        // Weekly sales
        List<SalesByRange> weeklySales = new ArrayList<>();
        LocalDate startOfYear = now.withDayOfYear(1);
        for (LocalDate date = startOfYear; !date.isAfter(now); date = date.plusWeeks(1)) {
            LocalDate startOfWeek = date.with(java.time.DayOfWeek.MONDAY);
            LocalDate endOfWeek = date.with(java.time.DayOfWeek.SUNDAY);
            String weekLabel = "Week " + startOfWeek.get(java.time.temporal.WeekFields.ISO.weekOfYear()) + ", " + startOfWeek.getYear();
            weeklySales.add(createSalesByRange(weekLabel, startOfWeek, endOfWeek, allOrders));
        }

        // Monthly sales
        List<SalesByRange> monthlySales = new ArrayList<>();
        for (int month = 1; month <= 12; month++) {
            LocalDate startOfMonth = now.withMonth(month).withDayOfMonth(1);
            LocalDate endOfMonth = startOfMonth.withDayOfMonth(startOfMonth.lengthOfMonth());

            // Use getDisplayName() to get the month name in title case
            String monthLabel = startOfMonth.getMonth()
                    .getDisplayName(java.time.format.TextStyle.FULL, Locale.ENGLISH)
                    + " " + now.getYear();
            monthlySales.add(createSalesByRange(monthLabel, startOfMonth, endOfMonth, allOrders));
        }

        // Yearly sales
        String yearLabel = "Year " + now.getYear();
        SalesByRange yearlySales = createSalesByRange(yearLabel, startOfYear, now, allOrders);

        // Total sales (all time)
        double totalSalesAllTime = allOrders.stream()
                .mapToDouble(Order::getTotalPrice)
                .sum();

        // Add to model
        model.addAttribute("weeklySales", weeklySales);
        model.addAttribute("monthlySales", monthlySales);
        model.addAttribute("yearlySales", yearlySales);
        model.addAttribute("totalSalesAllTime", totalSalesAllTime);

        logger.info("Admin access granted, displaying companies and menu items.");
        return "admin_home";
    }
    //controller/adminController.java Snippet End

    @PostMapping("/delete/company")
    public String deleteCompany(@RequestParam String companyEmail, @RequestParam String token, RedirectAttributes redirectAttributes, Model model) {
        if (!validateAdminToken(token, model)) {
            return "login";
        }

        logger.info("Deleting company with email: " + companyEmail);

        try {
            // Fetch the company by email
            UserLogin company = userLoginService.findByCompanyEmail(companyEmail);
            if (company == null) {
                redirectAttributes.addFlashAttribute("error", "Company not found.");
                return "redirect:/admin/home?token=" + token;
            }

            // Delete all cart items associated with the company
            cartItemService.deleteByCompany(company);

            // Delete all orders associated with the company
            orderService.deleteByCompany(company);

            // Delete the company itself
            userLoginService.deleteByCompanyEmail(companyEmail);

            redirectAttributes.addFlashAttribute("message", "Company and associated data deleted successfully.");
        } catch (Exception e) {
            logger.error("Error deleting company with email: " + companyEmail, e);
            redirectAttributes.addFlashAttribute("error", "Failed to delete company.");
        }

        return "redirect:/admin/home?token=" + token;
    }


    @PostMapping("/delete/icecream")
    public String deleteIceCream(@RequestParam String iceCreamId, @RequestParam String token, RedirectAttributes redirectAttributes, Model model) {
        if (!validateAdminToken(token, model)) {
            return "login";
        }

        logger.info("Deleting ice cream item with ID: {}", iceCreamId);

        try {
            // Fetch the menu item to confirm its existence
            Optional<MenuItem> menuItemOptional = menuItemService.findById(iceCreamId);

            if (menuItemOptional.isEmpty()) {
                redirectAttributes.addFlashAttribute("error", "Ice cream item not found.");
                return "redirect:/admin/home?token=" + token;
            }

            MenuItem menuItem = menuItemOptional.get();

            // Delete associated cart items
            List<CartItem> cartItems = cartItemService.findByMenuItem(menuItem);
            for (CartItem cartItem : cartItems) {
                cartItemService.delete(cartItem);
                logger.info("Deleted cart item with ID: {}", cartItem.getId());
            }

            // Delete associated orders that contain this menu item
            List<Order> orders = orderService.findAllOrders();
            for (Order order : orders) {
                boolean orderContainsItem = order.getCartItems().stream()
                        .anyMatch(cartItem -> cartItem.getMenuItem().equals(menuItem));
                if (orderContainsItem) {
                    orderService.deleteOrder(order);
                    logger.info("Deleted order with ID: {}", order.getId());
                }
            }

            // Finally, delete the menu item itself
            menuItemService.deleteById(iceCreamId);
            logger.info("Deleted ice cream item with ID: {}", iceCreamId);

            redirectAttributes.addFlashAttribute("message", "Ice cream item and associated data deleted successfully.");
        } catch (Exception e) {
            logger.error("Error deleting ice cream item with ID: {}", iceCreamId, e);
            redirectAttributes.addFlashAttribute("error", "Failed to delete ice cream item and associated data.");
        }

        return "redirect:/admin/home?token=" + token;
    }

    //controller/adminController.java Snippet Start
    private String generateUniqueLoginCode() {
        Random random = new Random();
        String loginCode;
        do {
            loginCode = String.valueOf(100000 + random.nextInt(900000));
        } while (userLoginService.isDuplicateGeneratedCode(loginCode));
        return loginCode;
    }

    @PostMapping("/create-code")
    public String createLoginCode(
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

        if (!validateAdminToken(token, model)) {
            return "login";
        }

        // Validate company CVR
        if (companyCVR.length() != 8 || !companyCVR.matches("\\d+")) {
            redirectAttributes.addFlashAttribute("error", "Company CVR must be exactly 8 numeric digits.");
            return "redirect:/admin/home?token=" + token;
        }

        // Check for duplicate company information
        if (userLoginService.isDuplicate(companyName, companyEmail, companyCVR, phoneNumber)) {
            redirectAttributes.addFlashAttribute("error", "Company name, CVR, Phone Number,  or email is already registered.");
            return "redirect:/admin/home?token=" + token;
        }

        // Validate phone number (must be digits only and not exceed 8 digits)
        if (!phoneNumber.matches("\\d{8}")) {
            redirectAttributes.addFlashAttribute("error", "Phone number must consist of exactly 8 digits.");
            return "redirect:/admin/home?token=" + token;
        }

        // Validate postcode (must be digits only)
        if (!postcode.matches("\\d+")) {
            redirectAttributes.addFlashAttribute("error", "Postcode must consist of numeric digits only.");
            return "redirect:/admin/home?token=" + token;
        }

        // Validate city (must not be numeric)
        if (city.matches("\\d+")) {
            redirectAttributes.addFlashAttribute("error", "City name cannot be numeric.");
            return "redirect:/admin/home?token=" + token;
        }

        if (streetName.matches(".*\\d.*")) {
            redirectAttributes.addFlashAttribute("error", "Street name cannot contain any digits.");
            return "redirect:/user/edit/profile?token=" + token;
        }


        String loginCode = generateUniqueLoginCode();
        UserLogin newUser = new UserLogin(
                companyCVR,
                companyName, companyEmail, loginCode, "normal",
                phoneNumber, streetName, streetNumber, postcode, city);


            // Save the new user
            userLoginService.saveUser(newUser);

            // Send an email with the user information
            emailService.sendUserInfo(
                    companyEmail, companyCVR, companyName, loginCode, phoneNumber,
                    streetName, streetNumber, postcode, city);
            redirectAttributes.addFlashAttribute("message", "Email successfully sent to " + companyEmail);


        return "redirect:/admin/home?token=" + token;
    }
    //controller/adminController.java Snippet End



    //controller/adminController.java Snippet Start
    @PostMapping("/menu/add")
    public String addMenuItem(
            @RequestParam String title,
            @RequestParam int size,
            @RequestParam String description,
            @RequestParam String allergens,
            @RequestParam int quantity,
            @RequestParam double pricePerLiter,
            @RequestParam("images") MultipartFile[] images,
            @RequestParam String token,
            RedirectAttributes redirectAttributes,
            Model model) {

        if (!validateAdminToken(token, model)) {
            return "login";
        }

        // Validate inputs
        if (title == null || title.trim().isEmpty()) {
            redirectAttributes.addFlashAttribute("error", "Title cannot be empty.");
            return "redirect:/admin/home?token=" + token;
        }

        if (size <= 0) {
            redirectAttributes.addFlashAttribute("error", "Size must be a positive number.");
            return "redirect:/admin/home?token=" + token;
        }

        if (description == null || description.trim().isEmpty()) {
            redirectAttributes.addFlashAttribute("error", "Description cannot be empty.");
            return "redirect:/admin/home?token=" + token;
        }

        if (pricePerLiter <= 0) {
            redirectAttributes.addFlashAttribute("error", "Price must be a positive number.");
            return "redirect:/admin/home?token=" + token;
        }

        if (quantity < 0) {
            redirectAttributes.addFlashAttribute("error", "Quantity cannot be negative.");
            return "redirect:/admin/home?token=" + token;
        }

        try {
            // Parse allergens
            List<String> allergenList = Arrays.asList(allergens.split(",\\s*"));

            // Build the variant string
            String variant = title + ", " + size + "L";

            // Determine availability
            boolean menuItemIsAvailable = quantity > 0;

            // Upload images if provided
            List<String> imagePaths = null;
            if (images != null && images.length > 0) {
                imagePaths = imageUploadService.uploadImages(images, title); // Upload images
            }

            // Create and save the menu item
            MenuItem menuItem = new MenuItem(variant, description, allergenList, quantity, menuItemIsAvailable, pricePerLiter, imagePaths);
            menuItemService.saveMenuItem(menuItem);

            redirectAttributes.addFlashAttribute("message", "Menu item successfully added.");
        } catch (IOException e) {
            redirectAttributes.addFlashAttribute("error", "Failed to handle images: " + e.getMessage());
            return "redirect:/admin/home?token=" + token;
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("error", "Failed to add menu item: " + e.getMessage());
            return "redirect:/admin/home?token=" + token;
        }

        return "redirect:/admin/home?token=" + token;
    }
    //controller/adminController.java Snippet End


    @PostMapping("/menu/update")
    public String updateMenuItem(
            @RequestParam String id,
            @RequestParam String title,
            @RequestParam String description,
            @RequestParam String allergens,
            @RequestParam int quantity,
            @RequestParam double pricePerLiter,
            @RequestParam(required = false) MultipartFile[] images, // Accept new image files
            @RequestParam(required = false) String imagepath, // Optional parameter for existing paths
            @RequestParam String token,
            RedirectAttributes redirectAttributes,
            Model model) {

        Logger logger = LoggerFactory.getLogger(this.getClass());
        logger.info("Updating menu item with ID: {}", id);

        // Validate admin token
        if (!validateAdminToken(token, model)) {
            logger.warn("Invalid admin token: {}", token);
            return "login";
        }

        // Input validation
        if (title == null || title.trim().isEmpty()) {
            redirectAttributes.addFlashAttribute("error", "Title cannot be empty.");
            return "redirect:/admin/home?token=" + token;
        }

        if (description == null || description.trim().isEmpty()) {
            redirectAttributes.addFlashAttribute("error", "Description cannot be empty.");
            return "redirect:/admin/home?token=" + token;
        }

        if (pricePerLiter <= 0) {
            redirectAttributes.addFlashAttribute("error", "Price must be a positive number.");
            return "redirect:/admin/home?token=" + token;
        }

        if (quantity < 0) {
            redirectAttributes.addFlashAttribute("error", "Quantity cannot be negative.");
            return "redirect:/admin/home?token=" + token;
        }

        Optional<MenuItem> menuItemOptional = menuItemService.findById(id);

        if (menuItemOptional.isPresent()) {
            MenuItem menuItem = menuItemOptional.get();
            logger.info("Menu item found: {}", menuItem);

            // Update basic fields
            menuItem.setTitle(title);
            menuItem.setDescription(description);
            List<String> allergenList = Arrays.asList(allergens.split(",\\s*"));
            menuItem.setAllergens(allergenList);
            menuItem.setQuantity(quantity);
            menuItem.setPricePerLiter(pricePerLiter);
            menuItem.setAvailable(quantity > 0);

            logger.info("Updated basic fields for menu item with ID: {}", id);

            try {
                if (images != null && images.length > 0) {
                    logger.info("New images uploaded. Deleting old images for menu item ID: {}", id);

                    // Delete old images from server using ImageUploadService
                    imageUploadService.deleteImages(menuItem.getImagePaths());

                    // Upload new images
                    List<String> newImagePaths = imageUploadService.uploadImages(images, title);
                    menuItem.setImagePaths(newImagePaths);
                    logger.info("Updated image paths for menu item ID {}: {}", id, newImagePaths);
                } else if (imagepath == null || imagepath.isEmpty()) {
                    logger.info("No images provided. Clearing image paths for menu item ID: {}", id);

                    // Delete old images from server using ImageUploadService
                    imageUploadService.deleteImages(menuItem.getImagePaths());

                    menuItem.setImagePaths(null);
                } else {
                    // If images are not uploaded but existing paths are provided
                    List<String> updatedImagePaths = Arrays.asList(imagepath.replace("[", "").replace("]", "").split(",\\s*"));
                    menuItem.setImagePaths(updatedImagePaths);
                    logger.info("Retained existing image paths for menu item ID {}: {}", id, updatedImagePaths);
                }
            } catch (IOException e) {
                logger.error("Failed to handle images for menu item ID {}: {}", id, e.getMessage());
                redirectAttributes.addFlashAttribute("error", "Failed to update images: " + e.getMessage());
                return "redirect:/admin/home?token=" + token;
            }

            // Save the updated menu item
            menuItemService.saveMenuItem(menuItem);
            logger.info("Menu item with ID {} updated successfully.", id);
            redirectAttributes.addFlashAttribute("message", "Menu item updated successfully.");
        } else {
            logger.error("Menu item with ID {} not found in the database.", id);
            redirectAttributes.addFlashAttribute("error", "Menu item not found.");
        }

        return "redirect:/admin/home?token=" + token;
    }

    //controller/AdminController.java Snippet Start
    @PostMapping("/order/approve")
    public String approveOrder(
            @RequestParam String orderId,
            @RequestParam String token,
            @RequestParam String expectedDeliveryDate, // New parameter to accept the delivery date
            RedirectAttributes redirectAttributes,
            Model model) {

        // Validate the admin token
        if (!validateAdminToken(token, model)) {
            return "login";
        }

        // Fetch the order by ID
        Optional<Order> orderOptional = orderService.findById(orderId);

        if (!orderOptional.isPresent()) {
            redirectAttributes.addFlashAttribute("error", "Order not found.");
            return "redirect:/admin/home?token=" + token;
        }

        Order order = orderOptional.get();

        // Format the expected delivery date to DD-MM-YY
        SimpleDateFormat inputDateFormat = new SimpleDateFormat("yyyy-MM-dd");  // The expected format from input
        SimpleDateFormat outputDateFormat = new SimpleDateFormat("dd-MM-yy");  // Desired output format
        String formattedDate = null;

        try {
            Date parsedDate = inputDateFormat.parse(expectedDeliveryDate);

            // Check if the expected delivery date is before today's date
            Calendar calendar = Calendar.getInstance();
            calendar.setTime(new Date());
            calendar.set(Calendar.HOUR_OF_DAY, 0);
            calendar.set(Calendar.MINUTE, 0);
            calendar.set(Calendar.SECOND, 0);
            calendar.set(Calendar.MILLISECOND, 0);
            Date today = calendar.getTime();

            if (parsedDate.before(today)) {
                redirectAttributes.addFlashAttribute("error", "Expected delivery date cannot be before today.");
                return "redirect:/admin/home?token=" + token;
            }

            formattedDate = outputDateFormat.format(parsedDate);
            order.setExpectedDeliveryDate(formattedDate);  // Assuming 'expectedDeliveryDate' is a field in the Order model
        } catch (Exception e) {
            logger.error("Error parsing expected delivery date", e);
            redirectAttributes.addFlashAttribute("error", "Invalid date format.");
            return "redirect:/admin/home?token=" + token;
        }

        // Update order status: set isProcessing to false and isApproved to true
        order.setProcessing(false);
        order.setApproved(true);

        try {
            // Create a map to aggregate quantities for each menu item
            Map<String, Integer> menuItemQuantities = new HashMap<>();

            // Loop through cart items and aggregate quantities for each menu item
            for (CartItem cartItem : order.getCartItems()) {
                MenuItem menuItem = cartItem.getMenuItem();
                int orderedQuantity = cartItem.getDesiredQuantity();

                menuItemQuantities.put(menuItem.getId(), menuItemQuantities.getOrDefault(menuItem.getId(),0) + orderedQuantity);
            }

            // Loop through menu items and deduct stock
            for (Map.Entry<String, Integer> entry : menuItemQuantities.entrySet()) { // Ensure this uses Integer
                String menuItemId = entry.getKey();
                int totalOrdered = entry.getValue(); // Correctly assign as int

                // Fetch the MenuItem
                Optional<MenuItem> menuItemOptional = menuItemService.findById(menuItemId);

                if (!menuItemOptional.isPresent()) {
                    logger.error("Menu item not found for ID: " + menuItemId);
                    continue; // Skip if the menu item is not found
                }

                MenuItem menuItem = menuItemOptional.get();
                int currentStock = menuItem.getQuantity(); // Ensure this returns an int

                // Check if there is enough stock available
                if (currentStock >= totalOrdered) {
                    // Deduct the stock
                    menuItem.setQuantity(currentStock - totalOrdered);

                    // If stock is zero or less, set isAvailable to false
                    if (menuItem.getQuantity() <= 0) {
                        menuItem.setAvailable(false);
                    }

                    // Save the updated MenuItem
                    menuItemService.saveMenuItem(menuItem);
                } else {
                    redirectAttributes.addFlashAttribute("error", "Not enough stock available for " + menuItem.getTitle());
                    return "redirect:/admin/home?token=" + token;
                }
            }


            // Save the updated order
            orderService.saveOrder(order);

            // Fetch the necessary details to send in the email
            String companyEmail = order.getCompany().getCompanyEmail(); // Assuming the company has an email
            List<CartItem> cartItems = order.getCartItems();
            double totalOrderCost = order.getTotalPrice();
            String companyName = order.getCompany().getCompanyName();
            String address = order.getCompany().getStreetName() + " " + order.getCompany().getStreetNumber() + ", "
                    + order.getCompany().getPostcode() + " " + order.getCompany().getCity();

            // Send the confirmation email
            emailService.sendOrderConfirmationEmail(companyEmail, cartItems, totalOrderCost, formattedDate, companyName, address);

            redirectAttributes.addFlashAttribute("message", "Order approved successfully. Confirmation email sent.");
        } catch (Exception e) {
            logger.error("Error approving order with ID: " + orderId, e);
            redirectAttributes.addFlashAttribute("error", "Failed to approve the order.");
        }

        // Redirect to admin home page with token and success message
        return "redirect:/admin/home?token=" + token;
    }
    //controller/AdminController.java Snippet End



    @PostMapping("/order/disapprove")
    public String disapproveOrder(
            @RequestParam String orderId,
            @RequestParam String token,
            @RequestParam(required = false) String disapprovalReason, // Optional reason for disapproval
            RedirectAttributes redirectAttributes,
            Model model) {

        // Validate the admin token
        if (!validateAdminToken(token, model)) {
            return "login";
        }

        // Fetch the order by ID
        Optional<Order> orderOptional = orderService.findById(orderId);

        if (!orderOptional.isPresent()) {
            redirectAttributes.addFlashAttribute("error", "Order not found.");
            return "redirect:/admin/home?token=" + token;
        }

        Order order = orderOptional.get();

        // Update the order status: set isProcessing to false, keep isApproved as false
        order.setProcessing(false);
        order.setApproved(false);

        // Save the updated order
        try {
            orderService.saveOrder(order);

            // Send disapproval email
            String companyEmail = order.getCompany().getCompanyEmail();
            String companyName = order.getCompany().getCompanyName();
            List<CartItem> cartItems = order.getCartItems();
            double totalOrderCost = order.getTotalPrice();

            if (disapprovalReason != null && !disapprovalReason.trim().isEmpty()) {
                emailService.sendDisapprovalEmail(companyEmail, companyName, disapprovalReason, cartItems, totalOrderCost);
            } else {
                emailService.sendDisapprovalEmail(companyEmail, companyName, null, cartItems, totalOrderCost);
            }

            redirectAttributes.addFlashAttribute("message", "Order disapproved successfully. Confirmation email sent.");
        } catch (Exception e) {
            logger.error("Error disapproving order with ID: " + orderId, e);
            redirectAttributes.addFlashAttribute("error", "Failed to disapprove the order.");
        }

        // Redirect to admin home page with token and success message
        return "redirect:/admin/home?token=" + token;
    }

    @PostMapping("/order/invoice")
    public String invoiceOrder(@RequestParam String orderId,
                               @RequestParam String token,
                               RedirectAttributes redirectAttributes,
                               Model model) {
        logger.info("Received orderId: {}", orderId);
        logger.info("Received token: {}", token);

        if (!validateAdminToken(token, model)) {

            return "login";
        }

        // Fetch the order by ID
        Optional<Order> orderOptional = orderService.findById(orderId);

        if (!orderOptional.isPresent()) {
            redirectAttributes.addFlashAttribute("error", "Order not found.");
            return "redirect:/admin/home?token=" + token;
        }

        Order order = orderOptional.get();

        order.setInvoiced(true);
        // Save the updated order
        try {
            orderService.saveOrder(order);



            redirectAttributes.addFlashAttribute("message", "Order Marked Invoiced Successfully.");
        } catch (Exception e) {
            logger.error("Error marking order invoiced ID: " + orderId, e);
            redirectAttributes.addFlashAttribute("error", "Failed To Mark The Order Invoiced");
        }
        return "redirect:/admin/home?token=" + token;
    }
    @PostMapping("/order/ship")
    public String shipOrder(
            @RequestParam String orderId,
            @RequestParam String token,
            RedirectAttributes redirectAttributes,
            Model model) {

        // Validate the admin token
        if (!validateAdminToken(token, model)) {
            return "login";
        }

        // Fetch the order by ID
        Optional<Order> orderOptional = orderService.findById(orderId);

        if (!orderOptional.isPresent()) {
            redirectAttributes.addFlashAttribute("error", "Order not found.");
            return "redirect:/admin/home?token=" + token;
        }

        Order order = orderOptional.get();

        // Update the order status: set isShipped to true
        order.setShipped(true);
        Date now = new Date();

        // Format the date to "DD-MM-YY HH:mm:ss"
        SimpleDateFormat dateFormat = new SimpleDateFormat("dd-MM-yy HH:mm:ss");
        String formattedDate = dateFormat.format(now);

        // Set the formatted date to the order
        order.setDeliveredDate(formattedDate);
        try {
            // Save the updated order
            orderService.saveOrder(order);

            // Fetch the necessary details to send in the email
            String companyEmail = order.getCompany().getCompanyEmail(); // Assuming the company has an email
            List<CartItem> cartItems = order.getCartItems();
            double totalOrderCost = order.getTotalPrice();
            String companyName = order.getCompany().getCompanyName();

            // Send the "Shipped" email
            emailService.sendShippedOrderEmail(companyEmail, cartItems, totalOrderCost, companyName);

            redirectAttributes.addFlashAttribute("message", "Order shipped successfully. Email notification sent.");
        } catch (Exception e) {
            logger.error("Error shipping order with ID: " + orderId, e);
            redirectAttributes.addFlashAttribute("error", "Failed to ship the order.");
        }

        // Redirect to admin home page with token and success message
        return "redirect:/admin/home?token=" + token;
    }

    //controller/adminController.java Snippet Start
    @PostMapping("/order/fetch-csv")
    public ResponseEntity<byte[]> fetchCSVByExpectedDelivery(@RequestParam String token,
                                                             @RequestParam String desiredDownloadDate) {
        // Log the request parameters
        logger.info("Received request to fetch CSV");
        logger.info("Token: {}", token);
        logger.info("Desired Download Date (raw): {}", desiredDownloadDate);

        // Parse and transform the date
        String formattedDownloadDate;
        try {
            LocalDate rawDate = LocalDate.parse(desiredDownloadDate); // Assuming the input is in ISO-8601 format (yyyy-MM-dd)
            formattedDownloadDate = rawDate.format(DateTimeFormatter.ofPattern("dd-MM-yy"));
            logger.info("Transformed Desired Download Date: {}", formattedDownloadDate);
        } catch (DateTimeParseException e) {
            logger.error("Invalid date format for Desired Download Date: {}", desiredDownloadDate);
            return ResponseEntity.badRequest().body("Invalid date format. Expected format: yyyy-MM-dd.".getBytes());
        }

        // Fetch the orders
        List<Order> orders = orderService.getOrdersByExpectedDelivery(formattedDownloadDate);
        if (orders.isEmpty()) {
            logger.warn("No orders found for the date: {}", formattedDownloadDate);
        } else {
            logger.info("Number of orders fetched: {}", orders.size());
            orders.forEach(order -> logger.info("Fetched Order: {}", order)); // Ensure `Order` has a meaningful `toString` method
        }

        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        PrintWriter writer = new PrintWriter(outputStream);

        // CSV Header with clear labels and spacing
        writer.println("Company Name      \tCompany CVR     \tCompany Email              \tOrder Date      \tExpected Delivery   \tTotal Price \tItems Ordered");

        // Populate CSV Rows
        for (Order order : orders) {
            // Write the order summary row with consistent spacing
            writer.printf("%-20s\t%-15s\t%-30s\t%-20s\t%-20s\t%-12.2f\t%-5d\n",
                    order.getCompany().getCompanyName(),
                    order.getCompany().getCompanyCVR(),
                    order.getCompany().getCompanyEmail(),
                    order.getFormattedOrderDate(),
                    order.getExpectedDeliveryDate(),
                    order.getTotalPrice(),
                    order.getCartItems().size()
            );

            // Write details of each item with better alignment and clarity
            int itemNumber = 1;
            for (CartItem cartItem : order.getCartItems()) {
                MenuItem menuItem = cartItem.getMenuItem();
                writer.printf("\t\t\t\t\t\t\tItem %d: %-20s %d x %.2f (%.2f each)\n",
                        itemNumber++,
                        menuItem.getTitle(),
                        cartItem.getDesiredQuantity(),
                        cartItem.getDesiredQuantity() * menuItem.getPricePerLiter(),
                        menuItem.getPricePerLiter()
                );
            }

            // Add a blank line for better separation between orders
            writer.println();
        }
        writer.flush();

        HttpHeaders headers = new HttpHeaders();
        headers.add("Content-Disposition", "attachment; filename=orders.csv");

        return new ResponseEntity<>(outputStream.toByteArray(), headers, HttpStatus.OK);
    }
    //controller/adminController.java Snippet End


}