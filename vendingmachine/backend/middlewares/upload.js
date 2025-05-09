const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Make sure the uploads directory exists
const uploadDir = 'backend/uploads/';
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Set storage engine
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname.replace(/\s+/g, '-')}`);
  }
});

// Check file type
const fileFilter = (req, file, cb) => {
  // Debug file information
  console.log('File upload attempt:');
  console.log('Original name:', file.originalname);
  console.log('Mimetype:', file.mimetype);
  
  // Accept common image mimetypes
  const allowedMimetypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
  
  // Check extension as well (as a fallback)
  const extension = path.extname(file.originalname).toLowerCase();
  const validExtension = ['.jpg', '.jpeg', '.png', '.gif'].includes(extension);
  
  if (allowedMimetypes.includes(file.mimetype) || validExtension) {
    // Valid image file
    return cb(null, true);
  } else {
    // Not a valid image
    console.log(`Rejected file: ${file.originalname} (${file.mimetype}) with extension ${extension}`);
    return cb(new Error('Images only! Please upload an image file (jpeg, jpg, png, gif)'));
  }
};

// Initialize upload middleware with increased file size limit
const upload = multer({
  storage: storage,
  limits: { fileSize: 15 * 1024 * 1024 }, // Increased to 15MB limit
  fileFilter: fileFilter
});

module.exports = upload;