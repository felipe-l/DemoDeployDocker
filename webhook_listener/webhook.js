const express = require('express');
const { exec } = require('child_process');
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

        // Use a relative path to the deploy.sh script in the app_deploy directory
        const deployScriptPath = path.join(__dirname, '../app_deploy/deploy.sh');

        // Execute the deploy script
        exec(deployScriptPath, (error, stdout, stderr) => {
            if (error) {
                console.error(`Error executing script: ${error.message}`);
                return res.status(500).send('Deployment failed.');
            }

            console.log(`stdout: ${stdout}`);
            console.error(`stderr: ${stderr}`);
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