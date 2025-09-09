const express = require("express");
const router = express.Router();
const controller = require("../controllers/homeController");

//GET home page
router.get("/",  controller.home);


/// EXPENSE ROUTES ///

// GET detail page for expenses
router.get("/expense/:id", controller.expense_detail);


/// PURCHASE ROUTES ///

// GET list of purchases
router.get("/purchases", controller.purchase_create_get);

// GET and POST purchase create
router.get("/expense/:id/purchase/create", controller.purchase_create_get);
router.post("/expense/:id/purchase/create", controller.purchase_create_post);

// GET and POST purchase update
router.get("/purchase/:id/update", controller.purchase_update_get);
router.post("/purchase/:id/update", controller.purchase_update_post);

//GET and POST purchase delete
router.get("/purchase/:id/delete", controller.purchase_delete_get);
router.post("/purchase/:id/delete", controller.purchase_delete_post);


/// EXPORT ROUTER ///
module.exports = router;
