const express = require('express');
const router = express.Router();
const { getBeats, getBeatById } = require('../controllers/beatController');

router.get('/', async (req, res) => {
    console.log('[BEATS][GET /] Fetching all beats');
    try {
        await getBeats(req, res);
        console.log('[BEATS][GET /] Successfully fetched beats');
    } catch (err) {
        console.error('[BEATS][GET /] Error fetching beats:', err);
        res.status(500).send('Error fetching beats.');
    }
});

router.get('/:id', async (req, res) => {
    console.log(`[BEATS][GET /:id] Fetching beat by id: ${req.params.id}`);
    try {
        await getBeatById(req, res);
        console.log(`[BEATS][GET /:id] Successfully fetched beat: ${req.params.id}`);
    } catch (err) {
        console.error(`[BEATS][GET /:id] Error fetching beat: ${req.params.id}`, err);
        res.status(500).send('Error fetching beat.');
    }
});

module.exports = router; 