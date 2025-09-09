const asyncHandler = require("express-async-handler");

const Income = require("../models/income");
const Bill = require("../models/bill");
const Expense = require("../models/expense");
const Purchase = require('../models/purchase');
const Goal = require('../models/goal');

exports.settings = asyncHandler(async (req, res, next) => {
    const expenses = await Expense.find({name: {$ne : 'Savings'}}); //all expenses but savings
    const mainGoal = await Goal.findOne({is_main_goal: true});
    const savings = await Expense.findOne({name: 'Savings'});
    const incomes = await Income.find();
    const isAnyIncome  = (incomes.length > 0);
    console.log("isAnyIncome = " + isAnyIncome)

    console.log(mainGoal);
    console.log(savings);


    const availableWeekly = res.locals.availableWeekly
    const currentlyAllocated = res.locals.currentlyAllocated
    const remainingAvailable = res.locals.remainingAvailable;
    console.log (currentlyAllocated + "currentlyAllocated");
    console.log("remainingAvailable" + remainingAvailable)
    console.log("availableWeekly" + availableWeekly)

    if (remainingAvailable < 0 ){

        res.render('settings', {
            title: 'Settings',
            expenses,
            mainGoal,
            savings,
            remainingAvailable,
            isAnyIncome,
            error: 'Fix your budget: You have exceeded your weekly budget'
        });
    } else {
        res.render('settings', {
            title: 'Settings',
            expenses,
            mainGoal,
            savings,
            isAnyIncome
        });
    }

});

exports.goal_update_get = asyncHandler(async (req, res, next) => {
    const mainGoal = await Goal.findById(req.params.id);
    const availableWeekly = res.locals.availableWeekly
    if (!mainGoal) {
        // Handle the case where no goal is found
        return res.status(404).send('Goal not found');
    }
    const mainGoalId = mainGoal._id
    res.render('main_goal_form', {
        mainGoal: mainGoal,
        mainGoalId: mainGoalId,
        availableWeekly,
        action: `/settings/main-goal/${mainGoalId}/update`
    })
});


exports.goal_update_post = asyncHandler(async (req, res, next) => {
        // Retrieve the expense ID from request parameters
        const mainGoalId = req.params.id;

        console.log(req.body.allocated);
        console.log('HERE: ' + mainGoalId);

        await Goal.findByIdAndUpdate(mainGoalId, {
            name: req.body.name,
            allocated: req.body.allocated
        });

        // Redirect to settings
        res.redirect(`/settings/`);

});

// Handle GET request to display the expense creation popup
exports.expense_create_get = asyncHandler(async (req, res, next) => {
    availableMonthly = res.locals.availableMonthly;
    availableWeekly = res.locals.availableWeekly;
    previouslySpent = res.locals.previouslySpent;
    currentlyAllocated = res.locals.currentlyAllocated;
    console.log("available : " + availableMonthly )

    res.render('expense_form', {
        title: 'Create Expense',
        expense: {},
        name: '',
        allocated: '',
        action: '/settings/expense/create',
        availableMonthly,
        availableWeekly,
        previouslySpent,
        currentlyAllocated,

    });
});

// Handle POST request to create a new expense
exports.expense_create_post = asyncHandler(async (req, res, next) => {
    availableMonthly = res.locals.availableMonthly;
    availableWeekly = res.locals.availableWeekly;


    try {

        console.log("name "+ req.body.name)
        const existingExpense = await Expense.findOne({ name: req.body.name });
        console.log(existingExpense + "existingExpense")

        // If an expense with the same name exists, prevent creating a duplicate
        if (req.body.name === "savings" || existingExpense ) {
            return res.render('expense_form', {
                title: 'Create Expense',
                name: 'Savings',
                allocated: '',
                action: '/settings/expense/create',
                availableWeekly,
                error: 'Expense with this name already exists'
            });
        } else if(req.body.allocated > availableMonthly){
            return res.render('expense_form', {
                title: 'Create Expense',
                name: '',
                allocated: '',
                action: '/settings/expense/create',

                availableWeekly,
                error: 'You\'re exceeding monthly budget'
            });
        }

        // Create a new expense and save to the database
        const expense = new Expense({
            name: req.body.name,
            allocated: req.body.allocated
        });

        // Save the expense, unless it's a duplicate of "Savings"
            await expense.save();


        // Redirect to settings
        res.redirect('/settings/');
    } catch (err) {
        // Handle errors
        return next(err);
    }
});

// Display Expense update form on GET
exports.expense_update_get = asyncHandler(async (req, res, next) => {
    const { availableMonthly, availableWeekly, previouslySpent, currentlyAllocated } = res.locals;

    try {
        // Retrieve the expense from the database
        const expense = await Expense.findById(req.params.id);
        if (!expense) {
            const err = new Error('Expense not found');
            err.status = 404;
            return next(err);
        }
        const expenseId = expense._id;
        console.log(expenseId + "expenseId")
        // Render the expense update form with the retrieved expense data

        res.render('expense_form', {
            title: 'Update ' + expense.name,
            expense,
            expenseId,
            action: `/settings/expense/${expenseId}/update`,
            availableWeekly
        });
    } catch (err) {
        // Handle errors
        return next(err);
    }
});

// Handle Expense update on POST
exports.expense_update_post = asyncHandler(async (req, res, next) => {
    const { availableMonthly, availableWeekly } = res.locals;
    const expenseId = req.params.id;

    try {
        // Retrieve the existing expense from the database
        const expense = await Expense.findById(expenseId);
        if (!expense) {
            const err = new Error('Expense not found');
            err.status = 404;
            return next(err);
        }

        const expenseName = expense.name;

        // Check if an expense with the new name already exists (excluding the current expense)
        const existingExpense = await Expense.findOne({ name: req.body.name });

        // Log the request body for debugging
        console.log(`Requested name: ${req.body.name}`);
        console.log(`Requested allocated amount: ${req.body.allocated}`);
        console.log(`Existing expense ID: ${existingExpense ? existingExpense._id.toString() : 'none'}`);
        console.log(`Current expense ID: ${expenseId.toString()}`);

        // Validate the new name
        if (req.body.name === "savings") {
            return res.render('expense_form', {
                title: 'Update ' + expenseName,
                expense,
                action: `/settings/expense/${expenseId}/update`,
                availableWeekly,
                error: 'The name "savings" is reserved and cannot be used.'
            });
        }

        // Validate the allocated amount
        if (req.body.allocated > availableMonthly) {
            return res.render('expense_form', {
                title: 'Update ' + expenseName,
                expense,
                action: `/settings/expense/${expenseId}/update`,
                availableWeekly,
                error: 'You are exceeding the monthly budget.'
            });
        }

        // Validate if the new name is already used by another expense
        if (existingExpense && existingExpense._id.toString() !== expenseId.toString()) {
            return res.render('expense_form', {
                title: 'Update ' + expenseName,
                expense,
                action: `/settings/expense/${expenseId}/update`,
                availableWeekly,
                error: 'An expense with this name already exists.'
            });
        }

        // Update the expense if validations pass
        await Expense.findByIdAndUpdate(expenseId, {
            name: req.body.name,
            allocated: req.body.allocated
        });

        // Redirect to settings
        res.redirect('/settings/');
    } catch (err) {
        return next(err);
    }
});




// Display Expense delete form on GET.
exports.expense_delete_get = asyncHandler(async (req, res, next) => {

    const expense = await Expense.findById(req.params.id);

    res.render('expense_delete', {
        title: 'Confirm Expense Deletion',
        expense
    });
});


exports.expense_delete_post = asyncHandler(async (req, res, next) => {
    try {
        // Get the expense ID from the request parameters
        const expenseId = req.params.id;

        // Delete all purchases related to the expense and the expense itself
        await Purchase.deleteMany({ expense: expenseId });
        await Expense.findByIdAndDelete(expenseId);

        // Redirect to settings
        res.redirect('/settings/');
    } catch (error) {
        console.error('Error deleting expense and related purchases:', error);
        res.status(500).send('Error deleting expense and related purchases. Please try again later.');
    }
});

// Display list of all Bills
exports.bill_list = asyncHandler(async (req, res, next) => {
    const bills = await Bill.find().sort({is_paid: -1});

    const availableMonthly = res.locals.availableMonthly

    const unpaidBills = bills.some(bill => !bill.is_paid);

    if (unpaidBills) {
        // Render the bill_list template with an error message indicating that all bills must be paid
        res.render('bill_list', {
            title: 'Bills',
            bills,
            error: `You haven't paid your bills.`
        });
    } else if (availableMonthly < 0) {
        // Render the bill_list template with an error message indicating insufficient funds
        res.render('bill_list', {
            title: 'Bills',
            bills,
            error: `Insufficient funds. Your Monthly Available is ${availableMonthly}.`
        });
    } else {
        res.render('bill_list', {
            title: 'Bills',
            bills,
        });
    }


});

// Display Bill create form on GET
exports.bill_create_get = asyncHandler(async (req, res, next) => {
    try {
        res.render('bill_form', {
            title: 'Add Bill',
            name: '',
            cost: '',
            action: '/settings/bills/create'
        });
    } catch (err) {
        return next(err);
    }
});

// Handle Bill create on POST
exports.bill_create_post = asyncHandler(async (req, res, next) => {
    try {
        // Create a new expense instance
        const bill = new Bill({
            name: req.body.name,
            cost: req.body.cost
        });

        // Save the new expense to the database
        await bill.save();

        res.redirect('/settings/bills'); // Redirect to bill_list after successful creation
    } catch (err) {
        // Handle errors, such as validation errors or database errors
        return next(err);
    }
});

// Display Bill update form on GET
exports.bill_update_get = asyncHandler(async (req, res, next) => {
    try {

        const bill = await Bill.findById(req.params.id);

        res.render('bill_form', {
            title: 'Edit Bill',
            bill,
            name: bill.name,
            cost: bill.cost,
            action: `/settings/bills/${bill._id}/update`
        })
    } catch (err) {
        return next(err);
    }
});

// Handle Bill update on POST
exports.bill_update_post = asyncHandler(async (req, res, next) => {
    try {
        // Find bill from request parameters and update with data from request body
        await Bill.findByIdAndUpdate(req.params.id, {
            name: req.body.name,
            cost: req.body.cost,
        });

        // Redirect to the bill_list
        res.redirect('/settings/bills');
    } catch (err) {
        return next(err);
    }
});

// Display Bill delete form on GET
exports.bill_delete_get = asyncHandler(async (req, res, next) => {

    const bill = await Bill.findById(req.params.id);

    res.render('bill_delete', {
        title: 'Confirm Bill Deletion',
        bill
    });
});

// Handle Bill delete on POST
exports.bill_delete_post = asyncHandler(async (req, res, next) => {
    try {
        // Find bill from request parameters and delete it from the database
        await Bill.findByIdAndDelete(req.params.id);

        // Redirect to bill list
        res.redirect('/settings/bills');
    } catch (err) {
        return next(err);
    }
});

// Update the paid status of a bill
exports.updatePaid = asyncHandler(async (req, res, next) => {
    try {
        // Find the bill from request body
        const bill = await Bill.findById(req.body.billId);

        if (!bill) {
            return res.status(404).json({ message: 'Bill not found' });
        }

        // Set the paid status of the bill to the inverse
        bill.is_paid = !bill.is_paid;

        await bill.save();

        res.status(200).json({ message: 'Bill paid status updated successfully', bill: bill });
    } catch (error) {
        console.error('Error updating bill paid status:', error);
        res.status(500).json({ message: 'Internal Server Error', error: error.message });
    }
});

// Display list of all income
exports.income_list = asyncHandler(async (req, res, next) => {
    const incomes = await Income.find()

    const availableWeekly = res.locals.availableWeekly
    const currentlyAllocated = res.locals.currentlyAllocated
    const remainingAvailable = availableWeekly - currentlyAllocated;
    if (remainingAvailable < 0) {
        // Render the bill_list template with an error message indicating insufficient funds
        res.render('income_list', {
            title: 'Income',
            incomes,
            error: `Adjust income. Insufficient funds for Week: ${remainingAvailable}.`
        });
    }
    res.render('income_list', {
        title: 'Income',
        incomes
    });
});

// Display Income create form on GET
exports.income_create_get = asyncHandler(async (req, res, next) => {
    try {
        res.render('income_form', {
            title: 'Add Income',
            name: '',
            amount: '',
            action: '/settings/income/create'
        })
    } catch (err) {
        return next(err);
    }
});

// Handle Income create on POST
exports.income_create_post = asyncHandler(async (req, res, next) => {
    try {
        // Create a new income instance
        const income = new Income({
            name: req.body.name,
            amount: req.body.amount,
        });

        // Save the new expense to the database
        await income.save();

        res.redirect('/settings/income'); // Redirect to the home page after successful creation
    } catch (err) {
        // Handle errors, such as validation errors or database errors
        return next(err);
    }
});

// Display Income update form on GET
exports.income_update_get = asyncHandler(async (req, res, next) => {
    try {
        const income = await Income.findById(req.params.id);
        res.render('income_form', {
            title: 'Edit Income',
            income,
            name: income.name,
            amount: income.amount,
            action: `/settings/income/${income._id}/update`
        })
    } catch (err) {
        return next(err);
    }
});

// Handle Income update on POST
exports.income_update_post = asyncHandler(async (req, res, next) => {
    try {
        // Find income from request parameters and update with data from request body
        await Income.findByIdAndUpdate(req.params.id, {
            name: req.body.name,
            amount: req.body.amount,
        });

        // Redirect to the income_list
        res.redirect('/settings/income');
    } catch (err) {
        return next(err);
    }
});

// Display Income delete form on GET
exports.income_delete_get = asyncHandler(async (req, res, next) => {

    const income = await Income.findById(req.params.id);

    res.render('income_delete', {
        title: 'Confirm Income Deletion',
        income
    });
});

// Handle Income delete on POST
exports.income_delete_post = asyncHandler(async (req, res, next) => {
    try {
        // Find income from request parameters and delete it from the database
        await Income.findByIdAndDelete(req.params.id);

        // Redirect to income list
        res.redirect('/settings/income');
    } catch (err) {
        return next(err);
    }
});