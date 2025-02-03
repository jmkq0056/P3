const express = require('express');
const router = express.Router();
const controller = require("../controllers/wishlistController");

// Route for /wishlist
router.get("/", controller.wishlist);


/// GOAL ROUTES ///

// GET and POST goal create form (MUST BE BEFORE ALL OTHERS! Otherwise, 'create' will be interpreted as an incorrect id cast)
router.get("/goal/create", controller.goal_create_get);
router.post("/goal/create", controller.goal_create_post);

//GET goal detail page
router.get("/goal/:id", controller.goal_detail);

// GET and POST goal update form
router.get("/goal/:id/update", controller.goal_update_get);
router.post("/goal/:id/update", controller.goal_update_post);

// GET and POST goal delete form
router.get("/goal/:id/delete", controller.goal_delete_get);
router.post("/goal/:id/delete", controller.goal_delete_post);

// POST update priority of goal
router.post('/goal/update-main-goal', controller.update_main_goal);


/// EXPORT ROUTER ///
module.exports = router;
