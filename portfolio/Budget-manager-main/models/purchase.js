const mongoose = require('mongoose');

const Schema = mongoose.Schema;

const PurchaseSchema = new Schema({
    expense: { type: Schema.Types.ObjectId, ref: "Expense", required: true },
    date: { type: Date, required: true },
    spent: { type: Number, min: 0, required: true },
});

// Returns date formatted as a weekday
PurchaseSchema.virtual("weekday").get(function () {
    return this.date.toLocaleString('en-us', {  weekday: 'long' });
});

module.exports = mongoose.model("Purchase", PurchaseSchema);