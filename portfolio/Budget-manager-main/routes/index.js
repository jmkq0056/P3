const express = require('express');
const router = express.Router();

// GET redirect to home page
router.get("/", function (req, res) {
  res.redirect("/home");
});


/// EXPORT ROUTER ///
module.exports = router;