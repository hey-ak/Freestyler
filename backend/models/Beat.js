const mongoose = require('mongoose');
const beatSchema = new mongoose.Schema({
  name: String,
  scale: String,
  bpm: Number,
  fileUrl: String // URL to S3/Cloudinary/Firebase
});
module.exports = mongoose.model('Beat', beatSchema); 