const Beat = require('../models/Beat');

exports.getBeats = async (req, res) => {
  const { scale, bpm } = req.query;
  const filter = {};
  if (scale) filter.scale = scale;
  if (bpm) filter.bpm = Number(bpm);
  const beats = await Beat.find(filter);
  const appUrl = process.env.APP_URL || (req.protocol + '://' + req.get('host'));
  const beatsWithFullUrl = beats.map(beat => {
    let fileUrl = beat.fileUrl;
    // If fileUrl is not a full URL, prepend appUrl
    if (fileUrl && !/^https?:\/\//i.test(fileUrl)) {
      // Remove leading slash if present
      fileUrl = fileUrl.replace(/^\/+/, '');
      fileUrl = `${appUrl}/${fileUrl}`;
    }
    return {
      ...beat.toObject(),
      fileUrl
    };
  });
  res.json(beatsWithFullUrl);
};

exports.getBeatById = async (req, res) => {
  const beat = await Beat.findById(req.params.id);
  if (!beat) return res.status(404).json({ error: 'Beat not found' });
  res.json(beat);
}; 