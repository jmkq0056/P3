package com.p3.syllesisfabrik.controller;


import com.p3.syllesisfabrik.model.UserLogin;
import com.p3.syllesisfabrik.service.UserLoginService;
import com.p3.syllesisfabrik.util.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.ui.Model;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.*;

public class LoginControllerTest {

    @Mock
    private UserLoginService userLoginService;

    @Mock
    private JwtUtil jwtUtil;

    @Mock
    private Model model;

    @InjectMocks
    private LoginController loginController;

    private final String ADMIN_PASSCODE = "A1b2C3d4E5f6G7!";

    @BeforeEach
    public void setup() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    public void testShowLoginPage() {
        // Arrange
        doNothing().when(userLoginService).createAdminIfNotExists();

        // Act
        String viewName = loginController.showLoginPage();

        // Assert
        assertEquals("login", viewName);
        verify(userLoginService, times(1)).createAdminIfNotExists();
    }

    @Test
    public void testValidateLogin_AdminLogin_Success() {
        // Arrange
        String loginCode = ADMIN_PASSCODE;
        String expectedToken = "adminToken";
        UserLogin adminUser = new UserLogin();
        adminUser.setCompanyEmail("admin@syllesisfabrik.com");

        when(jwtUtil.generateToken("admin")).thenReturn(expectedToken);
        when(userLoginService.findByCompanyEmail("admin@syllesisfabrik.com")).thenReturn(adminUser);
        doNothing().when(userLoginService).saveUserWithToken(adminUser, expectedToken);

        // Act
        String viewName = loginController.validateLogin(loginCode, model);

        // Assert
        assertEquals("redirect:/admin/home?token=" + expectedToken, viewName);
        verify(jwtUtil, times(1)).generateToken("admin");
        verify(userLoginService, times(1)).saveUserWithToken(adminUser, expectedToken);
    }

    @Test
    public void testValidateLogin_UserLogin_Success() {
        // Arrange
        String loginCode = "userCode";
        String expectedToken = "userToken";
        UserLogin userLogin = new UserLogin();
        userLogin.setLoginCode(loginCode);
        userLogin.setCompanyName("UserCompany");

        when(userLoginService.findByLoginCode(loginCode)).thenReturn(userLogin);
        when(jwtUtil.generateToken("UserCompany")).thenReturn(expectedToken);
        doNothing().when(userLoginService).saveUserWithToken(userLogin, expectedToken);

        // Act
        String viewName = loginController.validateLogin(loginCode, model);

        // Assert
        assertEquals("redirect:/login/user/home?token=" + expectedToken, viewName);
        verify(jwtUtil, times(1)).generateToken("UserCompany");
        verify(userLoginService, times(1)).saveUserWithToken(userLogin, expectedToken);
    }

    @Test
    public void testValidateLogin_InvalidLoginCode() {
        // Arrange
        String loginCode = "invalidCode";
        when(userLoginService.findByLoginCode(loginCode)).thenReturn(null);

        // Act
        String viewName = loginController.validateLogin(loginCode, model);

        // Assert
        assertEquals("login", viewName);
        verify(model, times(1)).addAttribute("error", "Invalid login code.");
    }

    @Test
    public void testShowUserHome_ValidToken() {
        // Arrange
        String token = "validToken";
        String companyName = "ValidCompany";

        when(jwtUtil.extractUsername(token)).thenReturn(companyName);
        when(jwtUtil.validateToken(token, companyName)).thenReturn(true);

        // Act
        String viewName = loginController.showUserHome(token, model);

        // Assert
        assertEquals("user_home", viewName);
        verify(model, times(1)).addAttribute("companyName", companyName);
    }

    @Test
    public void testShowUserHome_InvalidToken() {
        // Arrange
        String token = "invalidToken";
        String companyName = "InvalidCompany";

        when(jwtUtil.extractUsername(token)).thenReturn(companyName);
        when(jwtUtil.validateToken(token, companyName)).thenReturn(false);

        // Act
        String viewName = loginController.showUserHome(token, model);

        // Assert
        assertEquals("login", viewName);
        verify(model, times(1)).addAttribute("error", "Invalid or expired token.");
    }
}
