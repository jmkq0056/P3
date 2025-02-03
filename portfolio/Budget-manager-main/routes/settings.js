let express = require('express');
let router = express.Router();
const budgetInfo = require("../scripts/budgetInfo.js");
const controller = require("../controllers/settingsController");

const setBudgetInfo = async (req, res, next) => {
    const { availableMonthly, availableWeekly, currentlyAllocated, remainingAvailable, currentlySpent, previouslySpent, incomeMonthly, billsMonthly, recommendedSavings } = await budgetInfo();
    res.locals.availableMonthly = availableMonthly;
    res.locals.availableWeekly = availableWeekly;
    res.locals.currentlyAllocated = currentlyAllocated;
    res.locals.remainingAvailable = remainingAvailable;
    res.locals.currentlySpent = currentlySpent;
    res.locals.previouslySpent = previouslySpent;
    res.locals.incomeMonthly = incomeMonthly;
    res.locals.billsMonthly = billsMonthly;
    res.locals.recommendedSavings = recommendedSavings;
    next();
};

router.use(setBudgetInfo);


// GET settings page
router.get("/", controller.settings);

// MAIN GOAL AND SAVINGS //
router.get("/main-goal/:id/update", controller.goal_update_get);
router.post("/main-goal/:id/update", controller.goal_update_post);


/// BILL ROUTES ///

// GET list of bills
router.get("/bills", controller.bill_list);

// GET and POST bill create form
router.get("/bills/create", controller.bill_create_get);
router.post("/bills/create", controller.bill_create_post);

// GET and POST bill update form
router.get("/bills/:id/update", controller.bill_update_get);
router.post("/bills/:id/update", controller.bill_update_post);

// GET and POST bill delete
router.get('/bills/:id/delete', controller.bill_delete_get)
router.post("/bills/:id/delete", controller.bill_delete_post);

// POST bill update-paid
router.post('/bills/update-paid', controller.updatePaid);


/// INCOME ROUTES ///

// GET list of income
router.get("/income", controller.income_list);

// GET and POST income create
router.get("/income/create", controller.income_create_get);
router.post("/income/create", controller.income_create_post);

// GET and POST income update
router.get("/income/:id/update", controller.income_update_get);
router.post("/income/:id/update", controller.income_update_post);

// GET and POST income delete
router.get('/income/:id/delete', controller.income_delete_get)
router.post("/income/:id/delete", controller.income_delete_post);


/// EXPENSE ROUTES ///

//GET and POST expense create
router.get("/expense/create", controller.expense_create_get);
router.post("/expense/create", controller.expense_create_post);

//GET and POST expense update
router.get("/expense/:id/update", controller.expense_update_get);
router.post("/expense/:id/update", controller.expense_update_post);

//GET and POST expense delete
router.get("/expense/:id/delete", controller.expense_delete_get);
router.post("/expense/:id/delete", controller.expense_delete_post);

/// EXPORT ROUTER ///
module.exports = router;