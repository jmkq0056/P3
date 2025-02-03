
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

function toggleSection(sectionId) {
    // Updated section IDs to match the new structure
    const sections = ['currentOrdersSection', 'toBeDelivered', 'completedOrders'];

    // Check if the selected section is already visible
    if (document.getElementById(sectionId).style.display === "block") {
        return;
    }

    // Hide all sections and show the selected one
    sections.forEach(id => {
        document.getElementById(id).style.display = "none";
    });
    document.getElementById(sectionId).style.display = "block";
}

// Hide all sections on page load
window.onload = function() {
    // Updated section IDs
    const sections = ['currentOrdersSection', 'toBeDelivered', 'completedOrders'];

    // Hide all sections initially
    sections.forEach(id => {
        document.getElementById(id).style.display = "none";
    });
};
