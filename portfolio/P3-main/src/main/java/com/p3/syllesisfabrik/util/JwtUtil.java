package com.p3.syllesisfabrik.util;

import com.auth0.jwt.JWT; // Library for creating and decoding JWT tokens.
import com.auth0.jwt.algorithms.Algorithm; // Defines the encryption algorithm used to sign the JWT.
import com.auth0.jwt.exceptions.JWTVerificationException; // Exception thrown when token validation fails.
import com.auth0.jwt.interfaces.DecodedJWT; // Represents a decoded JWT (allows extracting claims).
import com.auth0.jwt.interfaces.JWTVerifier; // Verifier object to validate the JWT signature and claims.
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import com.p3.syllesisfabrik.model.UserLogin;
import com.p3.syllesisfabrik.service.UserLoginService;
import java.util.Date;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
@Component // Marks this class as a Spring-managed bean, allowing it to be injected elsewhere.
public class JwtUtil {

    // The secret key used to sign and verify JWT tokens. This should be kept secure and long enough (at least 256 bits) for HMAC algorithms.
    private final String SECRET_KEY = "u8J!mC2z*QeR^pA1$sD5wF7#hG9iT&xL";
    @Autowired
    private UserLoginService userLoginService;  // Inject UserLoginService to handle token removal

    // Generates a JWT token for the provided username. The token is signed using HMAC256 and includes an expiration date.
    public String generateToken(String username) {
        return JWT.create() // Begins building the JWT.
                .withSubject(username) // Adds the username as the token's subject (who the token is about).
                .withIssuedAt(new Date()) // Adds the current timestamp as the issue date.
                .withExpiresAt(new Date(System.currentTimeMillis() + 1000 * 60 * 60)) // Token will expire in 1 hour.
                .sign(Algorithm.HMAC256(SECRET_KEY)); // Signs the token using the HMAC256 algorithm with the secret key.
    }

    //util/JwtUtil.java Snippet Start
    // Validates the token by verifying its signature and ensuring the username matches.
    public boolean validateToken(String token, String username) {
        try {
            // Creates a JWTVerifier object to validate the token against the secret key and check the subject.
            JWTVerifier verifier = JWT.require(Algorithm.HMAC256(SECRET_KEY)) // Uses the same secret and algorithm to verify the token.
                    .withSubject(username) // Ensures the token is for the provided username (subject).
                    .build(); // Builds the verifier.

            // Verifies the token (decodes it and checks signature/claims).
            DecodedJWT decodedJWT = verifier.verify(token);
            // Check if the token has expired

            // Returns true if the token is not expired and the subject matches the provided username.
            return decodedJWT.getSubject().equals(username) && !isTokenExpired(decodedJWT);
        } catch (JWTVerificationException e) {
            // If verification fails (e.g., signature mismatch or token tampered with), return false.
            return false;
        }
    }
    //util/JwtUtil.java Snippet End
    public boolean invalidateToken(String token) {
        Logger logger = LoggerFactory.getLogger(JwtUtil.class);

        try {
            // Extract the username from the token
            String username = extractUsername(token);

            // Log the username extraction
            logger.info("Attempting to invalidate token for user: {}", username);

            // Special case: If the token is for admin, match the admin's companyName in the database
            String searchName = username.equals("admin") ? "Syllesis Fabrik" : username;

            // Find the user by the appropriate username or companyName
            UserLogin userLogin = userLoginService.findByCompanyName(searchName);

            if (userLogin != null) {
                // Set the user's token to null in the database
                userLogin.setToken(null);
                userLoginService.save(userLogin);

                // Log success
                logger.info("Successfully invalidated token for user: {}", username);
                return true;
            } else {
                // Log if user not found
                logger.error("User with companyName '{}' not found while invalidating token.", searchName);
            }
        } catch (Exception e) {
            // Log the exception with stack trace
            logger.error("Error occurred while invalidating token for user: {}", token, e);
        }

        // Log failure
        logger.error("Failed to invalidate token: {}", token);
        return false; // Return false if the token couldn't be invalidated
    }

    // Helper method to check if the token is expired by comparing the expiration time to the current time.
    private boolean isTokenExpired(DecodedJWT decodedJWT) {
        return decodedJWT.getExpiresAt().before(new Date()); // Returns true if the expiration date is before the current date/time (meaning the token has expired).
    }

    // Extracts the username (subject) from the JWT token without verifying it.
    public String extractUsername(String token) {
        return JWT.decode(token).getSubject(); // Decodes the JWT and retrieves the subject (username) without validating the token.
    }
}
