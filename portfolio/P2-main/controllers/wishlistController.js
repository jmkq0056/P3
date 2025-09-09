const asyncHandler = require("express-async-handler");
const Goal = require("../models/goal");

// Display Settings page on GET
exports.wishlist = asyncHandler(async (req, res, next) => {
    try {
        // Fetch all goals from the database, sorted by priority in descending order
        const goals = await Goal.find().sort({is_main_goal: -1});

        // Render the wish_list view, passing necessary and unnecessary goals as variables
        res.render('wishlist', {
            title: 'Wishlist',
            goals
        });
    } catch (err) {
        return next(err);
    }
});

// Display Goal detail on GET
exports.goal_detail = asyncHandler(async (req, res, next) => {
    //Find goal from request parameters
    const goal = await Goal.findById(req.params.id);
    console.log(goal.is_fulfilled + "goal.is_fulfilled")
    res.render('goal_detail', {
        title: goal.name,
        goal
    });
});

// Display Goal create form on GET.
exports.goal_create_get = asyncHandler(async (req, res, next) => {
    res.render('goal_form', {
        title: 'Create a goal',
        name: '',
        cost: '',
        saved: '',
        action: '/wishlist/goal/create'
    });
});

// Handle Goal create on POST.
exports.goal_create_post = asyncHandler(async (req, res, next) => {
    try {
        // Create a new goal instance
        const goal = new Goal({
            name: req.body.name,
            cost: req.body.cost,
        });

        //If only goal, set to main
        const goals = await Goal.findOne();
        if (!goals) {
            goal.is_main_goal = true;
            console.log(`${goal.name} is the only goal, so main goal set to ${goal.is_main_goal}`);
        }

        // Save the new goal to the database
        await goal.save();

        //Redirect to wishlist
        res.redirect('/wishlist');
    } catch (err) {
        return next(err);
    }
});

exports.goal_update_get = asyncHandler(async (req, res, next) => {
    try {
        // Find goal from request parameters
        const goal = await Goal.findById(req.params.id);

        // Render the update form with the goal data
        res.render('goal_form', {
            title: 'Update goal',
            name: goal.name,
            cost: goal.cost,
            saved: goal.saved,
            goal,
            action: `/wishlist/goal/${goal._id}/update`
        });
    } catch (err) {
        return next(err);
    }
});

// Handle Goal update on POST.
exports.goal_update_post = asyncHandler(async (req, res, next) => {
    try {
        const goal = await Goal.findByIdAndUpdate(req.params.id, {
            name: req.body.name,
            cost: req.body.cost,
            saved: req.body.saved,
            is_fulfilled: req.body.saved >= req.body.cost
        });

        // Redirect to wishlist
        res.redirect(`/wishlist/`);
    } catch (err) {
        return next(err);
    }
});

// Display Goal delete form on GET.
exports.goal_delete_get = asyncHandler(async (req, res, next) => {

    const goal = await Goal.findById(req.params.id);

    res.render('goal_delete', {
        title: 'Confirm Goal Deletion',
        goal
    });
});

// Handle Goal delete on POST.
exports.goal_delete_post = asyncHandler(async (req, res, next) => {
    try {

        const goal = await Goal.findById(req.params.id);
        if (goal.is_main_goal) {
            const newMainGoal = await Goal.findOne({is_main_goal: false});
            if (newMainGoal) {
                newMainGoal.is_main_goal = true;
                await newMainGoal.save();
            }
        }
        // Delete the goal from the database
        await Goal.findByIdAndDelete(req.params.id);

        // Redirect to wishlist
        res.redirect('/wishlist/');
    } catch (err) {
        return next(err);
    }
});

// Handle priority update on POST
exports.update_main_goal =  asyncHandler(async (req, res, next) => {
    try {
        // Extract goalId from the request body
        const {goalId} = req.body;
        let newMainGoal = await Goal.findById(goalId);
        if (!newMainGoal) {
            return res.status(404).json({success: false, message: 'New main goal not found'});
        }
        console.log(`New main goal is ${newMainGoal.is_main_goal}`);
        if (newMainGoal.is_main_goal === false) {
            console.log('New main goal!');
            const formerMainGoal = await Goal.findOne({is_main_goal: true});
            if (formerMainGoal) {
                formerMainGoal.is_main_goal = false;
                await formerMainGoal.save();
                console.log(`Former main goal is ${formerMainGoal.is_main_goal}`);
            }
        }

        newMainGoal.is_main_goal = true;
        await newMainGoal.save();
        console.log(`New main goal ${newMainGoal.name} is ${newMainGoal.is_main_goal}`);

        // Send back the updated goals list along with the success message
        res.status(200).json({
            message: 'Main goal updated successfully'
        });
    } catch (error) {
        // Handle errors, log them, and send a 500 response
        console.error('Error updating main goal:', error);
        res.status(500).json({success: false, message: 'Internal server error'});
    }
});