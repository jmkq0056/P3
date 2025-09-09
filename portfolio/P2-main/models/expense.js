const mongoose = require("mongoose");

const Schema = mongoose.Schema;

const ExpenseSchema = new Schema({
    name: { type: String, maxLength: 100, required: true},
    allocated: { type: Number, min: 0, required: true},
    spent: { type: Number, default: 0 },
    is_overspent: { type: Boolean, default: false },
    is_savings: { type: Boolean, default: false },
});

ExpenseSchema.virtual("percentage_spent").get(function () {
    return (this.spent / this.allocated) * 100;
});

module.exports = mongoose.model("Expense", ExpenseSchema);