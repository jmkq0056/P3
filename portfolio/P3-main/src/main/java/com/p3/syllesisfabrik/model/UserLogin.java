package com.p3.syllesisfabrik.model;

import org.springframework.data.annotation.Id; // Annotation that marks this field as the unique identifier for the MongoDB document.
import org.springframework.data.mongodb.core.mapping.Document; // Indicates that this class is a MongoDB document.
    //model/UserLogin.java Snippet Start
@Document(collection = "userLogins") // Specifies that this class represents a document in the MongoDB collection named "userLogins".
public class UserLogin {

    @Id // Marks the `id` field as the primary identifier for this document in MongoDB.
    private String id;

    private String companyCVR; // The name of the company associated with this user login.
    private String companyName; // The name of the company associated with this user login.
    private String companyEmail; // The email address for the company.
    private String loginCode; // The login code (either a 6-digit or a special 15-character code).
    private String codeType; // Identifies whether the code is "normal" (6-digit) or "special" (15-character).
    private String jwtToken; // Field for storing the JWT token issued to the user after login.
    private String phoneNumber; // New field for storing the company's phone number
    private String streetName; // New field for street name
    private String streetNumber; // New field for street number
    private String postcode; // New field for postcode
    private String city; // New field for city
    // Default constructor, required by frameworks such as Spring when instantiating objects.
    public UserLogin() {}

    // Parameterized constructor, used to easily create a `UserLogin` object with the provided details.
    public UserLogin(String companyCVR, String companyName, String companyEmail, String loginCode, String codeType, String phoneNumber, String streetName, String streetNumber, String postcode, String city) {
        this.companyCVR = companyCVR;
        this.companyName = companyName;
        this.companyEmail = companyEmail;
        this.loginCode = loginCode;
        this.codeType = codeType;
        this.phoneNumber = phoneNumber;
        this.streetName = streetName;
        this.streetNumber = streetNumber;
        this.postcode = postcode;
        this.city = city;
    }
    //model/UserLogin.java Snippet End
    // Add getters and setters for adress
    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }

    public String getStreetName() { return streetName; }
    public void setStreetName(String streetName) { this.streetName = streetName; }

    public String getStreetNumber() { return streetNumber; }
    public void setStreetNumber(String streetNumber) { this.streetNumber = streetNumber; }

    public String getPostcode() { return postcode; }
    public void setPostcode(String postcode) { this.postcode = postcode; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    // Getter and setter for the `jwtToken` field, which is used to store and retrieve the JWT token associated with this user.
    public String getJwtToken() {
        return jwtToken;
    }

    public void setJwtToken(String jwtToken) {
        this.jwtToken = jwtToken;
    }

    // Getter and setter for the `id` field. The `id` is the unique identifier for this document in MongoDB.
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getCompanyCVR() {
        return companyCVR;
    }
    public void setCompanyCVR(String companyCVR) {this.companyCVR = companyCVR;}
    // Getter and setter for the `companyName` field, which stores the company name.
    public String getCompanyName() {
        return companyName;
    }

    public void setCompanyName(String companyName) {
        this.companyName = companyName;
    }

    // Getter and setter for the `companyEmail` field, which stores the company's email address.
    public String getCompanyEmail() {
        return companyEmail;
    }

    public void setCompanyEmail(String companyEmail) {
        this.companyEmail = companyEmail;
    }

    // Getter and setter for the `loginCode` field, which stores the 6-digit or 15-character login code.
    public String getLoginCode() {
        return loginCode;
    }

    public void setLoginCode(String loginCode) {
        this.loginCode = loginCode;
    }

    // Getter and setter for the `codeType` field, which identifies whether the code is "normal" (6-digit) or "special" (15-character).
    public String getCodeType() {
        return codeType;
    }

    public void setCodeType(String codeType) {
        this.codeType = codeType;
    }

    public String getToken() {
        return jwtToken;
    }

    public void setToken(String token) {
        this.jwtToken = token;
    }
}
