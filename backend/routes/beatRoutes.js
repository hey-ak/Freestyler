const express = require('express');
const router = express.Router();
const { getBeats, getBeatById } = require('../controllers/beatController');
router.get('/', getBeats);
router.get('/:id', getBeatById);
module.exports = router; 