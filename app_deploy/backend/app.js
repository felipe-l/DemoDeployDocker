// app.js
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
    res.send('Hello, Docker! More developing less deploying :D! Seriously this time!');
});

app.get('/secret', (req, res) => {
    res.send('You found a new secret!');
});

app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
