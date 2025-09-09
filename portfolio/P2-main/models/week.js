const mongoose = require("mongoose");

const Schema = mongoose.Schema;

const WeekSchema = new Schema({
    year: { type: Number, required: true },
    month: { type: Number, required: true },
    week_number: { type: Number, required: true },
    weeks_in_month: { type: 'array', items: { type: Number }, default: [] },
    dates_in_week: { type: 'array', items: { type: Date }, required: true },
    spent: { type: Number, default: 0 },
    allocated: { type: Number, default: 0 },
    is_current_week: { type: Boolean, default: false }
});

WeekSchema.virtual("date_range").get(function () {
    const startDate = this.dates_in_week[0], endDate = this.dates_in_week[6];
    const startMonth = startDate.toLocaleString('en-us', { month: 'long' });
    const endMonth = endDate.toLocaleString('en-us', { month: 'long' });
    const dates = [startDate.getDate(), endDate.getDate()];
    for (let i = 0; i < dates.length; i++) {
        let ordinal;
        const currentDate = dates[i];
        switch (currentDate % 10) {
            case 1:
                ordinal = "st"; break;
            case 2:
                ordinal = "nd"; break;
            case 3:
                ordinal = "rd"; break;
            default:
                ordinal = "th";
        }
        //Specifically for 11-13, the ordinal will still be 'th'
        if(11 <= currentDate && currentDate <= 13) {
            ordinal = "th";
        }
        //Put the formatted date back in the array
        dates[i] = `${currentDate + ordinal}`;
    }
    return `${dates[0]} of ${startMonth} - ${dates[1]} of ${endMonth}`
});

// Export model
module.exports = mongoose.model("Week", WeekSchema);