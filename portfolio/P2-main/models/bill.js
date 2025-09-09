const mongoose = require("mongoose");

const Schema = mongoose.Schema;

const BillSchema = new Schema({
    name: { type: String, maxLength: 100, required: true},
    cost: { type: Number, min: 0, required: true},
    is_paid: { type: Boolean, default: false }
});

// Export model
module.exports = mongoose.model("Bill", BillSchema);