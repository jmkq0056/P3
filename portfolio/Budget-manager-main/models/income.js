const mongoose = require("mongoose");

const Schema = mongoose.Schema;

const IncomeSchema = new Schema({
    name: { type: String, maxLength: 100, required: true},
    amount: { type: Number, min: 0, required: true},
});

// Export model
module.exports = mongoose.model("Income", IncomeSchema);