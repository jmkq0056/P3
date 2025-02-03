// Function to toggle sections
function toggleSection(sectionId) {
    const sections = ['formModal', 'companyTable', 'menuSection', 'addMenuItemForm', 'currentOrdersSection', 'orderHistorySection', 'salesSection'];
    if (document.getElementById(sectionId).style.display === "block") {
        return;
    }
    sections.forEach(id => {
        document.getElementById(id).style.display = "none";
    });
    document.getElementById(sectionId).style.display = "block";
}

// Function to toggle sections
function toggleSectionSales(sectionId) {
    const sections = ['weeklySalesTable', 'monthlySalesTable', 'yearlySalesTable'];
    if (document.getElementById(sectionId).style.display === "block") {
        return;
    }
    sections.forEach(id => {
        document.getElementById(id).style.display = "none";
    });
    document.getElementById(sectionId).style.display = "block";
}

// Hide all sections on page load
window.onload = function() {
    const sections = ['formModal', 'companyTable', 'menuSection', 'addMenuItemForm', 'currentOrdersSection', 'orderHistorySection', 'salesSection', 'weeklySalesTable', 'monthlySalesTable', 'yearlySalesTable'];
    sections.forEach(id => {
        document.getElementById(id).style.display = "none";
    });

    // File input for adding new menu items
    const addMenuInput = document.querySelector('#addMenuItemForm input[type="file"]');
    if (addMenuInput) {
        addMenuInput.onchange = (event) => previewImages(event.target);
    }
    // File input for editing existing menu items
    const editMenuInput = document.querySelector('#uploadModalFooter input[type="file"]');
    if (editMenuInput) {
        editMenuInput.onchange = (event) => previewImagesUpdate(event.target);
    }
};
function showInfo(button) {
    // Retrieve allergens, description, and image paths from data attributes
    let allergens = button.getAttribute('data-allergens');
    const description = button.getAttribute('data-description');
    let imagePaths = button.getAttribute('data-images');

    // Handle missing or empty image paths
    if (!imagePaths || imagePaths.trim() === '') {
        imagePaths = [];
    } else {

        // Normalize backslashes for compatibility and convert to an array
        imagePaths = imagePaths.replace(/\\/g, '/').replace(/^\[|\]$/g, '').split(',');
    }

    // Remove square brackets and format the allergens list
    allergens = allergens ? allergens.replace(/^\[|\]$/g, '') : 'No allergens listed';

    // Update modal content
    document.getElementById('itemDetails').innerHTML =
        `<strong>Allergens:</strong> ${allergens}<br><br>` +
        `<strong>Description:</strong> ${description || 'No description provided.'}`;

    // Update slideshow container with images
    const slideshowContainer = document.getElementById('slideshowContainer');
    const dotContainer = document.getElementById('dotsContainer');

    slideshowContainer.innerHTML = ''; // Clear previous images
    dotContainer.innerHTML = ''; // Clear previous dots

    if (imagePaths.length > 0) {
        imagePaths.forEach((path, index) => {
            // Create an image element
            const img = document.createElement('img');
            img.src = path.trim();
            img.alt = `Image ${index + 1}`;
            img.style.display = index === 0 ? 'block' : 'none'; // Show the first image by default
            img.style.width = '100%'; // Ensure the images fill the container
            img.style.height = '200px'; // Fix height for consistency
            img.style.objectFit = 'cover'; // Maintain aspect ratio
            slideshowContainer.appendChild(img);

            // Create a dot for navigation
            const dot = document.createElement('div');
            dot.classList.add('dot');
            if (index === 0) dot.classList.add('active'); // Highlight first dot by default
            dot.onclick = () => {
                switchImage(slideshowContainer, index);
                updateActiveDot(dotContainer, index);
            };
            dotContainer.appendChild(dot);
        });
    } else {
        // If no images are available, display a placeholder or message
        slideshowContainer.innerHTML = '<p>No images available for this item.</p>';
    }

    // Display the modal
    document.getElementById('infoModal').style.display = 'block';
}






function switchImage(container, activeIndex) {
    const images = container.querySelectorAll('img');
    images.forEach((img, index) => {
        img.style.display = index === activeIndex ? 'block' : 'none';
    });
}

function updateActiveDot(dotContainer, activeIndex) {
    const dots = dotContainer.querySelectorAll('.dot');
    dots.forEach((dot, index) => {
        dot.classList.toggle('active', index === activeIndex);
    });
}


// Function to open modal with order items
function showOrderData(button) {
    // Get the hidden content inside the clicked button
    let itemsContent = button.querySelector('.order-items').innerHTML;

    // Insert the hidden content into the modal
    document.getElementById('infoContent').innerHTML = itemsContent;

    // Display the modal
    document.getElementById('infoModal').style.display = "block";
}




// Function to close the modal
function closeModal() {
    document.getElementById('infoModal').style.display = "none";
}

function showEditModal(button) {
    const id = button.getAttribute('data-item-id');
    const title = button.getAttribute('data-title');
    const description = button.getAttribute('data-description');
    const allergens = button.getAttribute('data-allergens')
        ?.replace(/^\[|\]$/g, '') // Remove brackets
        .split(',') // Split into an array
        .map(allergen => allergen.trim()) // Trim each allergen
        .join(', '); // Join back into a string
    const stockInLiters = button.getAttribute('data-quantity');
    const pricePerLiter = button.getAttribute('data-price-per-liter');
    const available = button.getAttribute('data-is-available') === 'true';
    let imagePaths = button.getAttribute('data-images');

    const imageStack = []; // Stack to hold existing image paths

    if (imagePaths && imagePaths.trim()) {
        imagePaths = imagePaths.replace(/\\/g, '/').replace(/^\[|\]$/g, '').split(',');
        imagePaths.forEach(path => imageStack.push(path)); // Initialize the stack with existing paths
    }

    // Populate the form fields with the existing values
    document.getElementById('editItemId').value = id;
    document.getElementById('editTitle').value = title;
    document.getElementById('editDescription').value = description;
    document.getElementById('editAllergens').value = allergens || ''; // Set cleaned-up allergens
    document.getElementById('editQuantity').value = stockInLiters;
    document.getElementById('editPricePerLiter').value = pricePerLiter;
    document.getElementById('editIsAvailable').checked = available;

    // Function to render the slideshow
    const renderSlideshow = () => {
        const slideshowContainer = document.getElementById('editSlideshowContainer');
        const dotContainer = document.getElementById('editDotsContainer');
        const uploadFooter = document.getElementById('uploadModalFooter');
        const imagePathInput = document.getElementById('imagepath');

        // Show or hide containers based on the presence of existing images
        if (imageStack.length > 0) {
            // Show the slideshow container and hide the upload container
            slideshowContainer.style.display = 'block';
            dotContainer.style.display = 'block';
            uploadFooter.style.display = 'none';

            slideshowContainer.innerHTML = ''; // Clear previous images
            dotContainer.innerHTML = ''; // Clear previous dots

            // Render existing images in the slideshow
            imageStack.forEach((path, index) => {
                const img = document.createElement('img');
                img.src = path.trim(); // Ensure correct path
                img.alt = `Image ${index + 1}`;
                img.style.display = index === 0 ? 'block' : 'none';
                img.style.width = '100%';
                img.style.height = '200px';
                img.style.objectFit = 'cover';
                slideshowContainer.appendChild(img);

                // Create navigation dots
                const dot = document.createElement('div');
                dot.classList.add('dot');
                if (index === 0) dot.classList.add('active');
                dot.onclick = () => {
                    switchImage(slideshowContainer, index);
                    updateActiveDot(dotContainer, index);
                };
                dotContainer.appendChild(dot);
            });
        } else {
            // If no images, hide the slideshow and show the upload container
            slideshowContainer.style.display = 'none';
            dotContainer.style.display = 'none';
            uploadFooter.style.display = 'block';
        }

        // Update the hidden input field for imagePaths
        imagePathInput.value = imageStack.length > 0 ? JSON.stringify(imageStack) : null;
    };

    // Function to delete all images
    const deleteAllImages = () => {
        imageStack.length = 0; // Clear all images
        renderSlideshow(); // Re-render the slideshow to reflect the changes
    };

    // Initial rendering of the slideshow
    renderSlideshow();

    // Add the "Delete All Images" button functionality
    const modalFooter = document.getElementById('modalFooter');
    modalFooter.innerHTML = ''; // Clear previous buttons
    const deleteButton = document.createElement('button');
    deleteButton.type = 'button';
    deleteButton.textContent = 'Delete All Images';
    deleteButton.style.backgroundColor = 'red';
    deleteButton.style.color = 'white';
    deleteButton.style.border = 'none';
    deleteButton.style.padding = '10px 20px';
    deleteButton.style.cursor = 'pointer';
    deleteButton.onclick = deleteAllImages;

    modalFooter.appendChild(deleteButton);

    // Show the modal
    document.getElementById('editModal').style.display = 'block';
}






// Function to toggle stock based on checkbox
function toggleStock() {
    const stockField = document.getElementById('editQuantity');
    const availableCheckbox = document.getElementById('editIsAvailable');
    const errorMessage = document.getElementById('availabilityError');

    if (!availableCheckbox.checked) {
        // If unchecked, set stock to 0
        stockField.value = 0;
        errorMessage.style.display = "none"; // Hide error message if stock is set to 0
    } else {
        // If trying to check "Available", validate stock
        if (parseFloat(stockField.value) === 0) {
            // Display error if stock is 0 and "Available" is checked
            errorMessage.style.display = "block";
            availableCheckbox.checked = false; // Prevent checkbox from being checked
        } else {
            errorMessage.style.display = "none"; // Hide error if stock is sufficient
        }
    }
}

// Attach the toggleStock function to the checkbox on change
document.getElementById('editIsAvailable').addEventListener('change', toggleStock);

// Function to close the edit modal
function closeEditModal() {
    document.getElementById('editModal').style.display = "none";
    document.getElementById('availabilityError').style.display = "none"; // Reset error message when closing modal
}
// Function to open the approval modal and set the data
function openApprovalModal(button) {
    // Retrieve the orderId and token from the button's data attributes
    const orderId = button.getAttribute('data-order-id');
    const token = button.getAttribute('data-token');

    // Set the orderId and token in the hidden fields of the form
    document.getElementById('orderId').value = orderId;
    document.getElementById('token').value = token;

    // Show the approval modal
    document.getElementById('approvalModal').style.display = "block";
}

// Function to open the approval modal and set the data
function openDeliveryListForm(button) {
    const token = button.getAttribute('data-token');
    document.getElementById('token4').value = token;
    const modal = document.getElementById('deliveryListForm');
    modal.style.display = "block";
}

// Function to close the approval modal
function closeDeliveryListForm() {
    const modal = document.getElementById('deliveryListForm');
    modal.style.display = "none";
}

// Function to close the approval modal
function closeApprovalModal() {
    document.getElementById('approvalModal').style.display = "none";
}

// Function to open the disapproval modal and populate order ID and token
function openDisapprovalModal(button) {
    var orderId = button.getAttribute('data-order-id');
    var token = button.getAttribute('data-token');

    // Set the order ID and token values in the form
    document.getElementById('orderId2').value = orderId;  // Updated ID for orderId
    document.getElementById('token2').value = token;      // Updated ID for token

    // Display the modal
    document.getElementById('disapprovalModal').style.display = 'block';
}

// Function to close the disapproval modal
function closeDisapprovalModal() {
    document.getElementById('disapprovalModal').style.display = 'none';
}

// Preview and Slideshow Functionality
function previewImages(input) {
    const container = document.getElementById('imagePreviewContainer');
    const dotContainer = document.getElementById('dotContainer');

    container.innerHTML = ''; // Clear previous previews
    dotContainer.innerHTML = ''; // Clear previous dots

    const files = input.files;

    if (files.length > 3) {
        alert('You can upload a maximum of 3 images.');
        input.value = ''; // Clear the file input
        return;
    }

    const imageElements = [];
    for (let i = 0; i < files.length; i++) {
        const file = files[i];

        // Create an image element for preview
        const img = document.createElement('img');
        img.src = URL.createObjectURL(file);
        img.alt = `Image ${i + 1}`;
        img.style.display = i === 0 ? 'block' : 'none'; // Show the first image, hide others
        container.appendChild(img);
        imageElements.push(img);

        // Create a dot for navigation
        const dot = document.createElement('div');
        dot.classList.add('dot');
        if (i === 0) dot.classList.add('active'); // Make the first dot active
        dot.onclick = () => {
            // Switch images on dot click
            imageElements.forEach((img, index) => {
                img.style.display = index === i ? 'block' : 'none';
            });
            updateActiveDot(i);
        };
        dotContainer.appendChild(dot);
    }

    // Update the active dot
    function updateActiveDot(activeIndex) {
        const dots = dotContainer.getElementsByClassName('dot');
        Array.from(dots).forEach((dot, index) => {
            dot.classList.toggle('active', index === activeIndex);
        });
    }
}
function previewImagesUpdate(input) {
    const updateContainer = document.getElementById('imagePreviewContainerUpdate');
    const updateDotContainer = document.getElementById('dotContainerUpdate');

    updateContainer.innerHTML = ''; // Clear previous previews
    updateDotContainer.innerHTML = ''; // Clear previous dots

    const updateFiles = input.files;

    if (updateFiles.length > 3) {
        alert('You can upload a maximum of 3 images.');
        input.value = ''; // Clear the file input
        return;
    }

    const imageElements = [];
    for (let i = 0; i < updateFiles.length; i++) {
        const file = updateFiles[i];

        // Create an image element for preview
        const updateImg = document.createElement('img');
        updateImg.src = URL.createObjectURL(file); // Create a blob URL for the image
        updateImg.alt = `Image ${i + 1}`;
        updateImg.style.display = i === 0 ? 'block' : 'none'; // Show the first image, hide others
        updateImg.style.width = '100%';
        updateImg.style.height = '200px';
        updateImg.style.objectFit = 'cover';

        updateContainer.appendChild(updateImg);
        imageElements.push(updateImg);

        // Create a dot for navigation
        const updateDot = document.createElement('div');
        updateDot.classList.add('dot');
        if (i === 0) updateDot.classList.add('active'); // Make the first dot active
        updateDot.onclick = () => {
            // Switch images on dot click
            imageElements.forEach((img, index) => {
                img.style.display = index === i ? 'block' : 'none';
            });
            updateActiveDot(updateDotContainer, i);
        };
        updateDotContainer.appendChild(updateDot);
    }

    // Update the active dot
    function updateActiveDot(dotContainer, activeIndex) {
        const dots = dotContainer.querySelectorAll('.dot');
        dots.forEach((dot, index) => {
            dot.classList.toggle('active', index === activeIndex);
        });
    }


}

//src/main/resources/static/js/admin-home.js Snippet Start
async function fetchCSV() {
    const form = document.getElementById('deliveryListDate');
    const token = document.getElementById('token4').value;
    const date = document.getElementById('downloadDate').value;

    if (!date) {
        alert("Please select a delivery date!");
        return;
    }

    try {
        const response = await fetch('/admin/order/fetch-csv', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: new URLSearchParams({
                token: token,
                desiredDownloadDate: date
            })
        });

        if (response.ok) {
            const blob = await response.blob();
            const url = window.URL.createObjectURL(blob);

            // Create a hidden link and trigger the download
            const a = document.createElement('a');
            a.style.display = 'none';
            a.href = url;
            a.download = 'orders.csv';
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);

            alert('CSV file has been downloaded successfully.');
        } else {
            const errorText = await response.text();
            alert(`Failed to fetch CSV: ${errorText}`);
        }
    } catch (error) {
        console.error("Error fetching CSV file:", error);
        alert("An error occurred while fetching the CSV file.");
    }
}
//src/main/resources/static/js/admin-home.js Snippet End
document.querySelectorAll('.expanding-input').forEach((textarea) => {
    textarea.addEventListener('input', function () {
        this.style.height = 'auto'; // Reset height to auto to shrink when needed
        this.style.height = this.scrollHeight + 'px'; // Adjust height based on content
    });
});
