const mongoose = require('mongoose');
const connectDB = async () => {
  console.log('Connecting to MongoDB:', process.env.MONGO_URI);
  await mongoose.connect(process.env.MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true });
  console.log('MongoDB connected');
};
module.exports = connectDB; 