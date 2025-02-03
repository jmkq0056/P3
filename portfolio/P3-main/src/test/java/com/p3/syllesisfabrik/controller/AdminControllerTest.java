/*


package com.p3.syllesisfabrik.controller;

import com.p3.syllesisfabrik.model.UserLogin;
import com.p3.syllesisfabrik.service.EmailService;
import com.p3.syllesisfabrik.service.UserLoginService;
import com.p3.syllesisfabrik.util.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.ui.Model;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.*;

public class AdminControllerTest {

    @Mock
    private JwtUtil jwtUtil; // Mocked JwtUtil to simulate token validation

    @Mock
    private EmailService emailService; // Mocked EmailService to prevent real email sending

    @Mock
    private UserLoginService userLoginService; // Mocked UserLoginService to avoid database interaction

    @Mock
    private Model model; // Mocked Model to simulate adding attributes to the view

    @InjectMocks
    private AdminController adminController; // AdminController instance with mocks injected

    @BeforeEach
    public void setup() {
        MockitoAnnotations.openMocks(this); // Initialize mocks before each test
    }

    @Test
    public void testShowAdminHomePage_WithValidToken() {
        // Arrange: Set up mock behavior and test data
        String token = "valid_token";
        when(jwtUtil.validateToken(token, "admin")).thenReturn(true); // Simulate valid token

        // Create a mock list of companies
        List<UserLogin> mockCompanies = new ArrayList<>();
        mockCompanies.add(new UserLogin("Company A", "email@example.com", "123456", "normal"));
        when(userLoginService.findAll()).thenReturn(mockCompanies); // Mock finding all companies

        // Act: Call the method being tested
        String viewName = adminController.showAdminHomePage(token, model);

        // Assert: Verify results
        assertEquals("admin_home", viewName); // Check if view name is correct

        // Verify model attributes are set as expected
        verify(model).addAttribute("companies", mockCompanies);
        verify(model).addAttribute("token", token);

        // Verify interactions with mocked services
        verify(jwtUtil, times(1)).validateToken(token, "admin");
        verify(userLoginService, times(1)).findAll();
    }

    @Test
    public void testShowAdminHomePage_WithInvalidToken() {
        // Arrange: Set up an invalid token scenario
        String token = "invalid_token";
        when(jwtUtil.validateToken(token, "admin")).thenReturn(false); // Simulate invalid token

        // Act: Call the method with an invalid token
        String viewName = adminController.showAdminHomePage(token, model);

        // Assert: Verify results
        assertEquals("login", viewName); // Expect to redirect to login page

        // Verify model attributes contain the correct error message
        verify(model).addAttribute("error", "Access denied. Please log in with a valid token.");

        // Verify interactions
        verify(jwtUtil, times(1)).validateToken(token, "admin");
        verify(userLoginService, never()).findAll(); // Ensure no database call for invalid token
    }

    @Test
    public void testDeleteCompany_Success() {
        // Arrange: Set up a valid email and token for deletion
        String companyEmail = "email@example.com";
        String token = "valid_token";

        // Act: Call the deleteCompany method
        String viewName = adminController.deleteCompany(companyEmail, token, model);

        // Assert: Verify redirection to the admin home page
        assertEquals("redirect:/admin/home?token=" + token, viewName);

        // Verify that deleteByCompanyEmail was called
        verify(userLoginService, times(1)).deleteByCompanyEmail(companyEmail);

        // Verify success message in the model
        verify(model).addAttribute("message", "Company deleted successfully.");
    }

    @Test
    public void testDeleteCompany_Failure() {
        // Arrange: Set up a scenario where deletion fails (simulate an exception)
        String companyEmail = "nonexistent@example.com";
        String token = "valid_token";
        doThrow(new RuntimeException("Deletion failed")).when(userLoginService).deleteByCompanyEmail(companyEmail);

        // Act: Attempt to delete a nonexistent company
        String viewName = adminController.deleteCompany(companyEmail, token, model);

        // Assert: Verify redirection to admin home page
        assertEquals("redirect:/admin/home?token=" + token, viewName);

        // Verify error message is added to the model
        verify(model).addAttribute("error", "Failed to delete company.");

        // Verify interactions
        verify(userLoginService, times(1)).deleteByCompanyEmail(companyEmail);
    }

    @Test
    public void testCreateLoginCode_WhenCompanyExists() {
        // Arrange: Simulate duplicate company scenario
        String companyName = "Company A";
        String companyEmail = "email@example.com";
        String token = "valid_token";

        when(userLoginService.isDuplicate(companyName, companyEmail)).thenReturn(true); // Mock duplicate check

        // Create a mock list of companies for the model
        List<UserLogin> mockCompanies = new ArrayList<>();
        when(userLoginService.findAll()).thenReturn(mockCompanies);

        // Act: Attempt to create a login code for an existing company
        String viewName = adminController.createLoginCode(companyName, companyEmail, token, model);

        // Assert: Verify that it stays on the admin_home page
        assertEquals("admin_home", viewName);

        // Verify error message in the model
        verify(model).addAttribute("error", "Company name or email is already registered.");

        // Verify model attribute for company list
        verify(model).addAttribute("companies", mockCompanies);

        // Verify interactions
        verify(userLoginService, times(1)).isDuplicate(companyName, companyEmail);
        verify(userLoginService, times(1)).findAll();
    }

    @Test
    public void testCreateLoginCode_NewCompany() {
        // Arrange: Simulate a scenario where the company is new
        String companyName = "New Company";
        String companyEmail = "newemail@example.com";
        String token = "valid_token";

        when(userLoginService.isDuplicate(companyName, companyEmail)).thenReturn(false); // Mock non-duplicate check

        // Mock list of companies
        List<UserLogin> mockCompanies = new ArrayList<>();
        when(userLoginService.findAll()).thenReturn(mockCompanies);

        // Mock email and save operations
        doNothing().when(emailService).sendUserInfo(anyString(), anyString(), anyString());
        doNothing().when(userLoginService).saveUser(any(UserLogin.class));

        // Act: Call createLoginCode for a new company
        String viewName = adminController.createLoginCode(companyName, companyEmail, token, model);

        // Assert: Verify it returns to the admin_home page
        assertEquals("admin_home", viewName);

        // Verify model attributes are correctly set
        verify(model).addAttribute(eq("message"), contains("Email successfully sent to " + companyEmail));
        verify(model).addAttribute("companyName", companyName);
        verify(model).addAttribute("companyEmail", companyEmail);
        verify(model).addAttribute("companies", mockCompanies);
        verify(model).addAttribute("token", token);

        // Verify interactions with mocked services
        verify(userLoginService, times(1)).isDuplicate(companyName, companyEmail);
        verify(userLoginService, times(1)).saveUser(any(UserLogin.class));
        verify(emailService, times(1)).sendUserInfo(eq(companyEmail), eq(companyName), anyString());
    }
}
*/