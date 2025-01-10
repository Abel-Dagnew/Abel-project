const express = require('express');
const path = require('path');
const app = express();

// Set EJS as the view engine
app.set('view engine', 'ejs');

// Serve static files (e.g., images) from the "public" directory
app.use(express.static(path.join(__dirname, 'public')));

// Route for the main page
app.get('/', (req, res) => {
    res.render('index', {
        githubLink: 'https://github.com/your-repo-link',
        architectureImage: '/images/architecture.png'
    });
});

// Route to download the image
app.get('/download', (req, res) => {
    const file = path.join(__dirname, 'public/images/architecture.png');
    res.download(file, 'architecture.png');
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
