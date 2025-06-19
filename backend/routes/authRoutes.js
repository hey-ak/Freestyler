const express = require('express');
const router = express.Router();
const { signup, login, getProfile } = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');
router.post('/signup', (req, res, next) => {
    console.log('[AUTH][POST /signup] Signup attempt:', req.body.email);
    next();
}, signup);
router.post('/login', (req, res, next) => {
    console.log('[AUTH][POST /login] Login attempt:', req.body.email);
    next();
}, login);
router.get('/me', authMiddleware, (req, res, next) => {
    console.log('[AUTH][GET /me] Profile fetch for user:', req.user ? req.user.id : 'unknown');
    next();
}, getProfile);
module.exports = router; 