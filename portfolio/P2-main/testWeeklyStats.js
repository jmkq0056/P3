#! /usr/bin/env node

console.log(
    'This script populates some test weeklyStats to the database.'
);

//require models
const WeeklyStats = require("./models/week");

//Empty arrays to hold created models
const stats = [];

//Set up mongoDB
const mongoose = require("mongoose");
mongoose.set("strictQuery", false);

const mongoDB = "mongodb+srv://gruppe9:iEUFbkQ3Iv5JgR5i@budgetcluster.vcdnwdn.mongodb.net/?retryWrites=true&w=majority&appName=BudgetCluster";
//Main
main().catch((err) => console.log(err));

async function main() {
    console.log("Debug: About to connect");
    await mongoose.connect(mongoDB);
    console.log("Debug: Should be connected?");
    await createWeeklyStats();
    console.log("Debug: Closing mongoose");
    await mongoose.connection.close();
}

// Create weeklyStats from required fields.
// Save expense to mongoDB and add it to expense array at selected index, log to console when completed.
async function statsCreate(index, month, week_number, spent, allocated) {
    const weeklyStats = new WeeklyStats({
        month,
        week_number,
        spent,
        allocated
    });

    await weeklyStats.save();
    stats[index] = weeklyStats;
    console.log(`Added weeklyStats for week ${week_number} in month ${month} with ${spent} spent out of ${allocated}`);
}

async function addWeeks(weekNumber) {
    const weeklyStats = await WeeklyStats.find();
    weeklyStats.forEach((weeklyStat) => {
        weeklyStat.weeks_in_month.push(weekNumber);
    });
}

async function createWeeklyStats() {
    console.log("Adding Stats");
    await Promise.all([
        statsCreate(0, 0, 1, 200, 300),
        statsCreate(1, 2, 15, 150, 300),
        statsCreate(2, 4, 23, 350, 300),
    ]);
    await Promise.all([
        addWeeks(2),
        addWeeks(3)
    ]);
}