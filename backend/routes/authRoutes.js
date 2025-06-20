const express = require('express');
const router = express.Router();
const { signup, login, getProfile, updateProfileImage } = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure the profile_images directory exists
const profileImagesDir = path.join(__dirname, '../public/profile_images');
if (!fs.existsSync(profileImagesDir)) {
    fs.mkdirSync(profileImagesDir, { recursive: true });
}

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, profileImagesDir);
    },
    filename: function (req, file, cb) {
        // Sanitize filename
        let base = file.originalname
            .toLowerCase()
            .replace(/\s+/g, '_')
            .replace(/[^a-z0-9._-]/g, '');
        let finalName = base;
        let counter = 1;
        while (fs.existsSync(path.join(profileImagesDir, finalName))) {
            const ext = path.extname(base);
            const name = path.basename(base, ext);
            finalName = `${name}_${counter}${ext}`;
            counter++;
        }
        cb(null, finalName);
    }
});
const upload = multer({ storage: storage });

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
router.post('/profile/image', authMiddleware, upload.single('profileImage'), updateProfileImage);
module.exports = router; 