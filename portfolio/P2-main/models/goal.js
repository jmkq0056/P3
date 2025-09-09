const mongoose = require("mongoose");

const Schema = mongoose.Schema;

const GoalSchema = new Schema({
    name: { type: String, maxLength: 100, required: true},
    cost: { type: Number, min: 0, required: true},
    allocated: { type: Number, default: 0 },
    saved: { type: Number, default: 0 },
    is_fulfilled: { type: Boolean, default: false },
    is_main_goal: { type: Boolean, default: false }
});

GoalSchema.virtual("percentage_saved").get(function () {
    return (this.saved / this.cost) * 100;
});

// Export model
module.exports = mongoose.model("Goal", GoalSchema);