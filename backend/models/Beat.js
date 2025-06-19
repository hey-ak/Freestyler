const mongoose = require('mongoose');
const beatSchema = new mongoose.Schema({
  name: String,
  scale: String,
  bpm: Number,
  fileUrl: String, // URL to S3/Cloudinary/Firebase
  category: String // New field for beat category
});
module.exports = mongoose.model('Beat', beatSchema); 