package com.p3.syllesisfabrik.service;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
    //service/imageUploadService.java Snippet Start
@Service
public class ImageUploadService {

    private static final String UPLOAD_DIR = "src/main/resources/static/uploads/menu-items/";

    public List<String> uploadImages(MultipartFile[] images, String menuItemTitle) throws IOException {
        List<String> imagePaths = new ArrayList<>();

        // Ensure the upload directory exists
        File uploadDir = new File(UPLOAD_DIR);
        if (!uploadDir.exists()) {
            uploadDir.mkdirs();
        }

        for (int i = 0; i < images.length; i++) {
            MultipartFile image = images[i];
            if (!image.isEmpty()) {
                // Create a sanitized file name using the menu item title and image index
                String sanitizedTitle = menuItemTitle.replaceAll("[^a-zA-Z0-9]", "_"); // Replace non-alphanumeric characters with "_"
                String fileName = sanitizedTitle + "_" + (i + 1) + "_" + System.currentTimeMillis() + ".jpg";

                // Normalize path to prevent duplicate slashes
                Path filePath = Paths.get(UPLOAD_DIR).resolve(fileName).normalize();

                // Save the file to the directory
                Files.write(filePath, image.getBytes());

                // Add the relative web path for static serving (normalize to ensure no duplicate slashes)
                String webPath = "/uploads/menu-items/" + fileName;
                webPath = webPath.replaceAll("/+", "/"); // Ensure no duplicate slashes in the path
                imagePaths.add(webPath);
            }
        }

        return imagePaths;
    }

    //service/imageUploadService.java Snippet End
    public void deleteImages(List<String> imagePaths) throws IOException {
        // Check if the list is null or empty and return early
        if (imagePaths == null || imagePaths.isEmpty()) {
            return; // Nothing to delete
        }

        for (String imagePath : imagePaths) {
            if (imagePath != null && !imagePath.isEmpty()) {
                // Resolve the absolute file path
                Path fileToDelete = Paths.get(UPLOAD_DIR + imagePath.replace("/uploads/menu-items/", ""));
                if (Files.exists(fileToDelete)) {
                    Files.delete(fileToDelete);
                }
            }
        }
    }

}