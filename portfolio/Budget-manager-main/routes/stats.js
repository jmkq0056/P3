const express = require("express");
const router = express.Router();
const controller = require('../controllers/statsController');

// GET stats page
router.get("/", controller.stats);


/// EXPORT ROUTER ///
module.exports = router;