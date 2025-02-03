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

function closeModal() {
    document.getElementById('infoModal').style.display = "none";
}

window.onclick = function(event) {
    const modal = document.getElementById('infoModal');
    if (event.target === modal) {
        modal.style.display = "none";
    }
};

function calculatePrice(inputElement) {
    const pricePerLiter = parseFloat(inputElement.getAttribute('data-price'));
    const stockInLiters = parseFloat(inputElement.getAttribute('data-quantity'));
    let liters = parseFloat(inputElement.value) || 0;

    // Ensure the input does not exceed available stock
    if (liters > stockInLiters) {
        liters = stockInLiters;
        inputElement.value = stockInLiters;  // Reset input to max stock if exceeded
    }

    // Find the nearest sibling with data-total-price
    const totalPriceElement = inputElement.closest('tr').querySelector('[data-total-price]');

    if (liters >= 0 && liters <= stockInLiters) {
        const totalPrice = (liters * pricePerLiter).toFixed(2);
        totalPriceElement.innerText = totalPrice + " DKK";

    } else {
        totalPriceElement.innerText = "0 DKK";
    }
}

function switchImage(container, activeIndex) {
    const images = container.querySelectorAll('img');
    images.forEach((img, index) => {
        img.style.display = index === activeIndex ? 'block' : 'none';
    });
}
