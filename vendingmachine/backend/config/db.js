const mongoose = require('mongoose');

const connectDB = async () => {
    try {
        mongoose.set('strictQuery', false);
        await mongoose.connect(process.env.MONGO_URI);
        console.log("MongoDB connected successfully");
    }
    catch (err) {
        console.log(err);
        process.exit(1); // Exit the process with failure
    }
};

module.exports = connectDB;
