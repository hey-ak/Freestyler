const Beat = require('../models/Beat');

exports.getBeats = async (req, res) => {
  const { scale, bpm } = req.query;
  const filter = {};
  if (scale) filter.scale = scale;
  if (bpm) filter.bpm = Number(bpm);
  const beats = await Beat.find(filter);
  res.json(beats);
};

exports.getBeatById = async (req, res) => {
  const beat = await Beat.findById(req.params.id);
  if (!beat) return res.status(404).json({ error: 'Beat not found' });
  res.json(beat);
}; 