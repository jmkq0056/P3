const asyncHandler = require("express-async-handler");

const Expense = require("../models/expense");
const Purchase = require('../models/purchase');
const Goal = require("../models/goal");
const Week = require('../models/week')

//Display home page
exports.home = asyncHandler(async (req, res) => {
    const expenses = await Expense.find({ is_savings: false });
    const mainGoal = await Goal.findOne({ is_main_goal: true });
    res.render("home", {
        title: 'Home',
        expenses,
        mainGoal
    });
});

// Display detail page for a specific Expense.
exports.expense_detail = asyncHandler(async (req, res, next) => {
    try {
        const expense = await Expense.findById(req.params.id);

        if (!expense) {
            return res.status(404).send('Expense not found');
        }

        // Fetch purchases related to the expense
        const purchases = await Purchase.find({expense: req.params.id});

        // Calculate the total amount spent
        let spentInExpense = 0;
        purchases.forEach(purchase => { spentInExpense += purchase.spent; });

        // Update the total_amount field in the Expense model
        expense.spent = spentInExpense;

        // Check if expense budget is exceeded
        expense.is_overspent = expense.spent > expense.allocated;

        // Save the updated expense to the database
        await expense.save();

        // Render the expense_detail page
        res.render('expense_detail', {
            title: expense.name,
            expense,
            purchases
        });
    } catch (error) {
        return next(error);
    }
});

// Route handler for displaying the purchase creation form
exports.purchase_create_get = asyncHandler(async (req, res, next) => {
    try {
        // Find the expense by ID from the URL parameters
        const expense = await Expense.findById(req.params.id);

        if (!expense) {

            return res.status(404).send('Expense not found');
        }

        res.render('purchase_form', {
            title: 'Create Purchase',
            expense: expense,
            spent: '',
            action: `/home/expense/${expense._id}/purchase/create`
        });
    } catch (err) {
        console.error(err);
        return next(err);
    }
});


exports.purchase_create_post = asyncHandler(async (req, res, next) => {
    try {
        // Find the expense with the ID retrieved from request parameters
        const expense = await Expense.findById(req.params.id);

        if (!expense) {
            return res.status(404).json({message: 'Expense not found', error: 'Expense with provided ID not found'});
        }

        // Create a new purchase object
        const purchase = new Purchase({
            expense: expense, // Assign the retrieved expense object
            date: req.body.date,
            spent: req.body.spent
        });

        // Save the purchase object to the database
        await purchase.save();

        // Redirect back to expense_detail
        res.redirect(`/home/expense/${expense._id}`);
    } catch (error) {
        console.error(error);
        res.status(500).render('error', {message: 'Internal Server Error', error: error.message});
    }
});

exports.purchase_update_get = asyncHandler(async (req, res, next) => {
    try {
        const purchase = await Purchase.findById(req.params.id);
        if (!purchase) {
            return res.status(404).send('Purchase not found');
        }
        const expense = await Expense.findById(purchase.expense._id);

        // Render the Purchase update form with the purchase data and expense ID
        res.render('purchase_form', {
            title: 'Edit Purchase',
            purchase,
            spent: purchase.spent,
            expense,
            action: `/home/purchase/${purchase._id}/update`
        });
    } catch (error) {
        console.error('Error fetching purchase:', error);
        res.status(500).send('Error fetching purchase');
    }
});

exports.purchase_update_post = asyncHandler(async (req, res, next) => {
    try {
        // Extract purchase ID from request parameters and find the purchase
        //const purchaseId = req.params.id;
        const purchase = await Purchase.findById(req.params.id);

        purchase.date = req.body.date;
        purchase.spent = req.body.spent;

        // Find the purchase by ID and update its data
        const updatedPurchase = await purchase.save();

        if (!updatedPurchase) {
            return res.status(404).send('Purchase not found');
        }

        // Redirect back to expense_detail
        res.redirect(`/home/expense/${purchase.expense._id}`);
    } catch (error) {
        console.error('Error updating purchase:', error);
        res.status(500).send('Error updating purchase');
    }
});

// Display Purchase delete form on GET.
exports.purchase_delete_get = asyncHandler(async (req, res, next) => {
    try {
        // Find the purchase by ID
        const purchase = await Purchase.findById(req.params.id);
        const expense = await Expense.findById(req.params.id);
        if (!purchase) {
            return res.status(404).send('Purchase not found');
        }

        res.render('purchase_delete', {
            title: 'Confirm Purchase Deletion',
            purchase,
            expense
        });
    } catch (err) {
        next(err);
    }
});


// Handle Purchase delete on POST.
exports.purchase_delete_post = asyncHandler(async (req, res, next) => {
    try {
        // Get the purchase ID from the request parameters
        const purchaseId = req.params.id;

        // Find the purchase by ID
        const purchase = await Purchase.findById(purchaseId);

        if (!purchase) {
            // Handle case where purchase is not found
            return res.status(404).send('Purchase not found');
        }

        // Delete the purchase
        await Purchase.findByIdAndDelete(purchaseId);

        // Redirect back to expense_detail
        res.redirect(`/home/expense/${purchase.expense._id}`);
    } catch (error) {
        console.error('Error deleting purchase:', error);
        res.status(500).send('Error deleting purchase. Please try again later.');
    }
});