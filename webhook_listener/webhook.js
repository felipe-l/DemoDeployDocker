const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const port = process.env.PORT || 8080;

// Parse incoming JSON requests
app.use(express.json());

// GitHub Webhook listener endpoint
app.post('/webhook', (req, res) => {
    const payload = req.body;

    // Ensure it's a push event
    if (payload && payload.ref && payload.ref === 'refs/heads/main') {
        console.log('Received push event. Triggering deployment...');

        // Construct the command to trigger the deploy.sh script via the named pipe
        const deployCommand = `sh ../app_deploy/deploy.sh`;
        
        // Path to your named pipe
        const pipePath = path.join(__dirname, '../hostpipe/mypipe');  // Adjust based on your mount point

        const wstream = fs.createWriteStream(pipePath);
        
        wstream.write("echo hello" + "\n", (err) => {
            
        })
        wstream.write(deployCommand + '\n', (err) => {
            if (err) {
                console.error(`Error writing to pipe: ${err.message}`);
                return res.status(500).send('Deployment failed.');
            }
            wstream.end();  // Close the stream

            console.log('Deployment command sent to the pipe.');
            return res.status(200).send('Deployment triggered.');
        });
    } else {
        console.log('Not a push event or wrong branch.');
        return res.status(400).send('Not a push event.');
    }
});

app.listen(port, () => {
    console.log(`Listening for webhooks on port ${port}`);
});
