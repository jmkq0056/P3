#! /usr/bin/env node

console.log(
    'This script populates some test expenses to the database.'
);

// Get arguments passed on command line
const userArgs = process.argv.slice(2);

//require models
const Expense = require("./models/expense");
const Purchase = require("./models/purchase");
const Goal= require("./models/goal");
const Bill= require("./models/bill");
//Empty arrays to hold created models
const expenses = [];
const purchases = [];

//Set up mongoDB
const mongoose = require("mongoose");
mongoose.set("strictQuery", false);

const mongoDB = userArgs[0];
//Main
main().catch((err) => console.log(err));

async function main() {
    console.log("Debug: About to connect");
    await mongoose.connect(mongoDB);
    console.log("Debug: Should be connected?");
    await createExpenses();
    await createPurchases();
    await createGoals()
    await createBills()
    console.log("Debug: Closing mongoose");
    await mongoose.connection.close();
}

// Create an expense from required fields.
// Save expense to mongoDB and add it to expense array at selected index, log to console when completed.
async function expenseCreate(index, name, allocated) {
    const expense = new Expense({
        name: name,
        allocated: allocated,
    });

    await expense.save();
    expenses[index] = expense;
    console.log(`Added expense: ${name} with ${allocated} DKK allocated`);
}

// Create a purchase from required fields. Expense field ties purchase to expense category.
// Save purchase to mongoDB and add it to purchase array at selected index, log to console when completed.
async function purchaseCreate(index, expense, date, spent) {

    const purchase = new Purchase({
        expense: expense,
        date: date,
        spent: spent
    });

    await  purchase.save();
    purchases[index] = purchase;

    console.log(`Added purchase in ${expense} of ${amount} DKK. It is ${purchase.weekday}`);
}

async function goalCreate(index, name, cost, is_necessity,
                          is_fulfilled,
                          is_priority) {
    const goal = new Goal({
        name: name,
        cost: cost,
        is_necessity: is_necessity,
        is_fulfilled: is_fulfilled,
        is_priority: is_priority
    });

    await goal.save();
    goal[index] = goal;
    console.log(`Added goal: ${name} with ${cost} DKK`);
}

async function billCreate(index, name, amount,due, paid) {
    const bill = new Bill({
        name: name,
        cost: amount,
        is_paid: paid
    });

    await bill.save();
   bill[index] = bill;
    console.log(`Added bill: ${name} of ${amount} DKK`);
}


async function createExpenses() {
    console.log("Adding Expenses");
    await Promise.all([
        expenseCreate(0, "Food", 400),
        expenseCreate(1, "Clothes", 150),
        expenseCreate(2, "Leisure", 200),
    ]);
}

//Create some default purchases. The purchases are tied to their expense object.
async function createPurchases() {
    console.log("Adding purchases");
    await Promise.all([
        purchaseCreate(0, expenses[0], 'April 5, 2024 12:15:30', 180),
        purchaseCreate(1, expenses[0], 'April 4, 2024 12:15:30', 149),
        purchaseCreate(2, expenses[0], 'April 3, 2024 12:15:30', 50),
        purchaseCreate(3, expenses[2], 'April 2, 2024 12:15:30', 145),
        purchaseCreate(4, expenses[2], 'April 5, 2024 12:15:30', 15),
    ]);
}


//Create some default goals with some being for wishlist and some for neccesity
async function createGoals() {
    console.log("Adding Goals");
    await Promise.all([
        goalCreate(0, "Macbook", 7500, false, false,true),
        goalCreate(1, "phone case", 6520, true),
        goalCreate(2, "Iphone2", 5620),
    ]);
}



//Create some default goals with some being for wishlist and some for neccesity
async function createBills() {
    console.log("Adding Bills");
    await Promise.all([
        billCreate(0, "Husleje", 7500, 'April 11, 2024 12:15:30', true),
        billCreate(1, "Netflix", 123, 'April 17, 2024 12:15:30', true),
        billCreate(2, "Ubisoft AC", 521, 'April 18, 2024 12:15:30'),
    ]);
}

