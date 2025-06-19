require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');
const authRoutes = require('./routes/authRoutes');
const beatRoutes = require('./routes/beatRoutes');
const adminRoutes = require('./routes/adminRoutes');
const app = express();
const path = require('path');

connectDB();
app.use(cors());
app.use(express.json());

// Set EJS as the view engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Middleware
app.use(express.urlencoded({ extended: true })); // For form data
app.use(express.static(path.join(__dirname, 'public')));

app.use('/api/auth', authRoutes);
app.use('/beats', beatRoutes);
app.use('/admin', adminRoutes);

// Add this after all your routes:
app.use((err, req, res, next) => {
    console.error('Global error handler:', err.stack || err);
    res.status(500).send('Something went wrong!');
});

const PORT = process.env.PORT || 5001;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));