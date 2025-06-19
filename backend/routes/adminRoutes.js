const express = require('express');
const router = express.Router();
const path = require('path');
const multer = require('multer');
const Beat = require('../models/Beat');
const fs = require('fs');

// Ensure the beats directory exists
const beatsDir = path.join(__dirname, '../public/beats');
if (!fs.existsSync(beatsDir)) {
    fs.mkdirSync(beatsDir, { recursive: true });
}

// Set up multer for file uploads
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, beatsDir);
    },
    filename: function (req, file, cb) {
        // Sanitize filename: lowercase, replace spaces with underscores, remove special characters except dot and underscore
        let base = file.originalname
            .toLowerCase()
            .replace(/\s+/g, '_')
            .replace(/[^a-z0-9._-]/g, '');
        let finalName = base;
        let counter = 1;
        // Ensure unique filename if file exists
        while (fs.existsSync(path.join(beatsDir, finalName))) {
            const ext = path.extname(base);
            const name = path.basename(base, ext);
            finalName = `${name}_${counter}${ext}`;
            counter++;
        }
        cb(null, finalName);
    }
});
const upload = multer({ storage: storage });

// GET: Show upload form and list beats with optional scale filter
router.get('/beats', async (req, res) => {
    const selectedScale = req.query.scale || '';
    let filter = {};
    if (selectedScale) {
        filter.scale = selectedScale;
        console.log(`[ADMIN][GET /beats] Filtering beats by scale: ${selectedScale}`);
    } else {
        console.log('[ADMIN][GET /beats] Fetching all beats');
    }
    try {
        const beats = await Beat.find(filter);
        // Get unique scales for the filter dropdown
        const scales = await Beat.distinct('scale');
        console.log(`[ADMIN][GET /beats] Found ${beats.length} beats, scales:`, scales);
        res.render('admin/uploadBeat', { beats, scales, selectedScale });
    } catch (err) {
        console.error('[ADMIN][GET /beats] Error fetching beats:', err);
        res.status(500).send('Error fetching beats.');
    }
});

// POST: Handle beat upload
router.post('/beats', upload.single('beatFile'), async (req, res) => {
    const { beatName, scale, bpm, category } = req.body;
    const file = req.file;
    console.log('[ADMIN][POST /beats] Incoming upload:', { beatName, scale, bpm, category, file: file ? file.originalname : null });
    if (!file) {
        console.warn('[ADMIN][POST /beats] No file uploaded.');
        return res.status(400).send('No file uploaded.');
    }
    try {
        const fileUrl = `/beats/${file.filename}`;
        console.log('[ADMIN][POST /beats] Saving beat to DB:', { beatName, scale, bpm, category, fileUrl });
        const newBeat = new Beat({
            name: beatName,
            scale,
            bpm: Number(bpm),
            category,
            fileUrl
        });
        await newBeat.save();
        console.log('[ADMIN][POST /beats] Beat saved successfully:', newBeat);
        res.redirect('/admin/beats');
    } catch (err) {
        console.error('[ADMIN][POST /beats] Error saving beat to database:', err);
        res.status(500).send('Error saving beat to database.');
    }
});

module.exports = router; 