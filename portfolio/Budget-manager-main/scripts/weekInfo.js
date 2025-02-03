const Week = require("../models/week");
const Expense = require("../models/expense");
const Purchase = require("../models/purchase");
const Bill = require('../models/bill')
const Goal = require('../models/goal');
const { weekNumber: calculateWeekNumber } = require('weeknumber');

const weekInfo = async () => {
    let today = new Date();
    const year = today.getFullYear();
    const weekNumber = calculateWeekNumber(today);

    // Try to find Week model for current week
    let currentWeek = await Week.findOne({ year: year, week_number: weekNumber });
    if (!currentWeek) {
        await setupYear(year);
        // Try to find current week again
        currentWeek = await Week.findOne({ year: year, week_number: weekNumber });
    }

    // Handle week change
    if (currentWeek.is_current_week === false) {
        console.log('New week!');
        const previousWeek = await Week.findOne({ is_current_week: true });
        if (previousWeek) {
            console.log('Previous week: ' + previousWeek)

            // Everything earmarked for savings and main goal is "spent"
            const savings = await Expense.findOne({ is_savings: true });
            previousWeek.spent += savings.allocated;
            console.log('added savings of ' + savings.allocated + ' to week spent, totalling: ' + previousWeek.spent);
            const mainGoal = await Goal.findOne({ is_main_goal: true });
            previousWeek.spent += mainGoal.allocated;
            console.log('added main goal of ' + mainGoal.allocated + ' to week spent, totalling: ' + previousWeek.spent);
            mainGoal.saved += mainGoal.allocated; // Money spent on main goal added to its amount
            await mainGoal.save();
            console.log('added main goal of ' + mainGoal.allocated + ' to main goal saved, totalling: ' + mainGoal.saved);

            // Delete all purchases and remove is_current_week flag
            await Purchase.deleteMany();
            console.log('Purchases deleted?');
            previousWeek.is_current_week = false;
            await previousWeek.save();
            console.log(`Previous week ${previousWeek.week_number} is ${previousWeek.is_current_week}`);
            //Mark all bills as unpaid if month changes
            if (currentWeek.month !== previousWeek.month) {
                const bills = await Bill.find();
                bills.forEach(bill => {
                    bill.is_paid = false;
                    bill.save();
                    console.log('Bill unpaid: ' + bill.name);
                });
            }
        }

        // Mark current week as current week
        currentWeek.is_current_week = true;
        await currentWeek.save();
        console.log(`Current week ${currentWeek.week_number} is ${currentWeek.is_current_week}`);
    }

    const goals = await Goal.find();

    // Loop through each goal
    for (const goal of goals) {
        // Check if saved_amount is greater than or equal to cost
        if (goal.saved_amount >= goal.cost) {
            goal.is_fulfilled = true;
        } else {
            goal.is_fulfilled = false;
        }

        // Save the updated goal
        await goal.save();
    }
    // Update current week with allocated and spent amounts
    const expenses = await Expense.find();
    let currentlyAllocated = 0;
    let currentlySpent = 0;
    expenses.forEach((expense) => {
        currentlyAllocated += expense.allocated;
        currentlySpent += expense.spent;
    });
    const mainGoal = await Goal.findOne({ is_main_goal: true });
    if (mainGoal) {
        currentlyAllocated += mainGoal.allocated;
    }

    console.log('HERE:' + currentWeek.allocated);
    currentWeek.allocated = currentlyAllocated;
    currentWeek.spent = currentlySpent;
    await currentWeek.save();


    // Find current goalAchievedBy
    let goalAchievedBy = 'No allocated amount';
    if (mainGoal) {
        console.log("mainGoal.cost" + (mainGoal.cost))
        console.log("mainGoal.saved" + (mainGoal.saved))

        const remainingAmount = mainGoal.cost - mainGoal.saved;
        console.log("Remaining Amount" + (remainingAmount))
        // Only if allocated amount > 0!!
        if (mainGoal.allocated > 0) {
            console.log("mainGoal.allocated" + mainGoal.allocated)
            const weeksLeft = Math.ceil(remainingAmount / mainGoal.allocated);
            console.log("weeksLeft" + weeksLeft)
            let yearAchieved = year;
            let weekAchieved = weekNumber + weeksLeft;
            if (weekAchieved > 52) {
                yearAchieved += Math.floor(weekAchieved / 52);
                weekAchieved = weekAchieved % 52 || 52;
            }
            console.log("Info", weekAchieved, yearAchieved )
            const goalAchievedByDate = getStartDateOfWeek(weekAchieved, yearAchieved);

            if (yearAchieved === 2024) {
                goalAchievedBy = formatDate(goalAchievedByDate);
            } else {
                goalAchievedBy = formatDate(goalAchievedByDate) + " " + yearAchieved;
            }
        }
    }

    return {
        today,
        weekNumber,
        dateRange: currentWeek.date_range,
        week: currentWeek.dates_in_week,
        goalAchievedBy
    };
};


const setupYear = async (year) => {
    //Initialize global variables
    let month = 0, //January
        dayTracker = 1; //Tracks day of year numerically
    let start = new Date(year, month, 1); //First day of year
    let weekday = start.getDay() || 7; //Weekday of this day (1 = Monday, 2 = Tuesday etc.)

    //Handle if first day of year is not Monday
    if (weekday !== 1) {
        start.setDate(start.getDate() - weekday + 1); //set start date to previous Monday
    }

    console.log(`Start date of ${year}: ${start}`);

    //Get amount of days in first month.
    // (Will always be 31 for Jan and Dec, but feels wrong to hard code)
    let daysInMonth = new Date(year, month +1, 0).getDate();
    let dates_in_week = [];
    let weeks_in_month = [];

    //Iterate through days of year
    for(let d = start; d.getFullYear() <= year; d.setDate(d.getDate() + 1)) {
        //Date added to current year
        let date = new Date(d);
        dates_in_week.push(date);

        //Every Sunday (multiples of 7), save week info to database
        if(dayTracker % 7 === 0) {
            //Calculate week number from dayTracker
            let week_number = dayTracker/7;
            console.log(`Week ${week_number} ended on ${date}. Month: ${date.getMonth()}`);
            //Week number added to current month
            weeks_in_month.push(week_number);

            //Save current week as Week model
            const currentWeek = new Week({
                year,
                month,
                week_number,
                dates_in_week
            });
            await currentWeek.save();

            //Reset dates in week
            dates_in_week = [];
        }

        //On last day of each month (excluding overlap week from December of previous year)
        if (date.getDate() === daysInMonth && date.getFullYear() === year) {
            console.log(`Last day of month: ${date.toLocaleString()}`);

            //Find Week models for month (if any) and save week numbers in them
            let weeks = await Week.find({month: month, year: year});
            if (weeks) {
                weeks.forEach((week) => {
                    week.weeks_in_month = weeks_in_month;
                    week.save();
                });
                weeks_in_month = [];
            }
            //Set month to new month and find new amount of days in said month
            console.log(`Previous month: ${month}`);
            month++;
            console.log(`New month: ${month}`);
            daysInMonth = new Date(year, month +1, 0).getDate();
        }
        //Increment day tracker
        dayTracker++;
    }
}

function formatDate (d) {
    const month = d.toLocaleString('en-us', { month: 'long' });
    const date = d.getDate();
    let ordinal;
    switch (date % 10) {
        case 1:
            ordinal = "st";
            break;
        case 2:
            ordinal = "nd";
            break;
        case 3:
            ordinal = "rd";
            break;
        default:
            ordinal = "th";
    }
    //Specifically for 11-13, the ordinal will still be 'th'
    if(11 <= date && date <= 13) {
        ordinal = "th";
    }
    return `${date + ordinal} of ${month}`
}

function getStartDateOfWeek(weekNumber, year) {
    console.log("weekNumber: " + weekNumber);
    console.log("year: " + year);

    let januaryFirst = new Date(year, 0, 1);
    let daysOffset = (januaryFirst.getDay() + 6) % 7; // Days to subtract to get to the first Monday of the year
    let firstMondayOfYear = new Date(year, 0, 1 - daysOffset);

    let startDate = new Date(firstMondayOfYear);
    startDate.setDate(startDate.getDate() + (weekNumber - 1) * 7); // Add days to get to the start of the desired week
    console.log("startDate" + startDate)
    return startDate;
}


module.exports = weekInfo;