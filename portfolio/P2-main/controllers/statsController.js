const asyncHandler = require("express-async-handler");

//Display home page
exports.stats = asyncHandler(async (req, res) => {
    res.render("stats", {
        title: 'Stats'
    });
});