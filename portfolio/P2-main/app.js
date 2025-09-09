const createError = require('http-errors');
const express = require('express');
const path = require('path');
const cookieParser = require('cookie-parser');
const logger = require('morgan');
const debug = require('debug')('myapp:server');

const indexRouter = require('./routes/index');
const homeRouter = require('./routes/home');
const wishlistRouter= require('./routes/wishlist');
const settingsRouter= require('./routes/settings');
const statsRouter = require('./routes/stats');

const app = express();

// Set up mongoose connection
const mongoose = require("mongoose");
mongoose.set("strictQuery", false);
const mongoDB = "";
main().catch((err) => console.log(err));
async function main() {
  await mongoose.connect(mongoDB);
}

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'pug');

app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

const weekInfo = require("./scripts/weekInfo");

const setCurrentWeek = async (req, res, next) => {
  const { today, weekNumber, dateRange, week, goalAchievedBy } = await weekInfo();
  res.locals.today = today;
  res.locals.weekNumber = weekNumber;
  res.locals.dateRange = dateRange;
  res.locals.week = week;
  res.locals.goalAchievedBy = goalAchievedBy;
  next();
};

app.use(setCurrentWeek);

app.use('/', indexRouter);
app.use('/home', homeRouter);
app.use('/wishlist', wishlistRouter);
app.use('/settings', settingsRouter);
app.use('/stats', statsRouter);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});

module.exports = app;