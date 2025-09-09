const Week = require("../models/week");
const Income = require('../models/income');
const Bill = require('../models/bill');
const Goal = require('../models/goal')

const budgetInfo = async () => {
    // Calculate total income amount
    const incomes = await Income.find();
    let incomeMonthly = 0;
    incomes.forEach((income) => {
        incomeMonthly += income.amount;
    });

    // Calculate total bill amount
    const bills = await Bill.find();
    let billsMonthly = 0;
    bills.forEach((bill) => {
        billsMonthly += bill.cost;
    });

    //Available monthly:
    let availableMonthly = incomeMonthly - billsMonthly;

    // AVAILABLE WEEKLY:
    //Find an even distribution of available amount across the year:
    let daysInYear = 365;
    if (new Date().setMonth(2, 0) === 29) {
        daysInYear++; //Adds February 29th if this year is a leap year
    }
    const availableYearly = availableMonthly * 12;
    const availableDaily = availableYearly / daysInYear;
    let availableWeekly = availableDaily * 7;
    availableWeekly = Math.floor(availableWeekly / 10) * 10; //Rounded down to nearest 10

    // CURRENTLY ALLOCATED:
    let currentWeek = await Week.findOne({is_current_week: true});
    const mainGoal = await Goal.findOne({is_main_goal: true});
    const currentlyAllocated = currentWeek.allocated;

    // CURRENTLY SPENT:
    const currentlySpent = currentWeek.spent;

    // REMAINING AVAILABLE:
    const remainingAvailable = availableWeekly - currentlyAllocated;

    // PREVIOUSLY SPENT:
    const weeksInMonth = currentWeek.weeks_in_month;
    //Remove week numbers from weeks array until only those previous to current week remain
    while(weeksInMonth[weeksInMonth.length - 1] >= currentWeek.week_number) {
        const removedWeek = weeksInMonth.pop();
    }
    //Find previous weeks in month and sum spent amounts
    let previouslySpent = 0;
    if (weeksInMonth.length > 0) { //TODO: could just be 'if (weeksInMonth)' maybe?
        const min = weeksInMonth[0], max = weeksInMonth.pop();
        const previousWeeks = await Week.find({ $and: [{ week_number: { $gte: min } }, { week_number: { $lte: max } }] })
        previousWeeks.forEach(week => {
            previouslySpent += week.spent;
        });
    }

    // RECOMMENDED SAVINGS:
    const monthlySavings = incomeMonthly * 0.1;
    let recommendedSavings = monthlySavings * 12 / daysInYear * 7;
    recommendedSavings = Math.floor(recommendedSavings / 10) * 10;

    return {
        availableMonthly,
        availableWeekly,
        currentlyAllocated,
        remainingAvailable,
        currentlySpent,
        previouslySpent,
        incomeMonthly,
        billsMonthly,
        recommendedSavings
    }
}

module.exports = budgetInfo;