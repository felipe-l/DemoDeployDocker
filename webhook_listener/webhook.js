const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const port = process.env.PORT || 8080;

// Get the expected repository URL from environment variables
const expectedRepoUrl = process.env.REPO_URL;

// Parse incoming JSON requests
app.use(express.json());

// GitHub Webhook listener endpoint
app.post('/webhook', (req, res) => {
    const payload = req.body;

    // Ensure it's a push event
    if (payload && payload.ref && payload.ref === 'refs/heads/main') {
        console.log('Received push event. Triggering deployment...');

        // Check if the repository URL from the payload matches the expected REPO_URL
        const incomingRepoUrl = payload.repository.url + '.git'; // Adjust this path based on the actual structure of your webhook payload

        if (incomingRepoUrl === expectedRepoUrl) {
            console.log('Repository URL matches. Proceeding with deployment.');

            // Construct the command to trigger the deploy.sh script via the named pipe using a relative path
            const deployCommand = `sh ../app_deploy/deploy.sh`;
            
            // Path to your named pipe
            const pipePath = path.join(__dirname, '../hostpipe/mypipe');  // Adjust based on your mount point

            const wstream = fs.createWriteStream(pipePath);
            
            // Optional: Write a debug command to check the current directory
            wstream.write("pwd" + "\n", (err) => {
                if (err) {
                    console.error(`Error writing to pipe: ${err.message}`);
                }
            });

            // Write the deployment command to the named pipe
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
            console.log(`Repository URL mismatch: expected ${expectedRepoUrl}, got ${incomingRepoUrl}.`);
            return res.status(403).send('Repository URL does not match. Deployment aborted.');
        }
    } else {
        console.log('Not a push event or wrong branch.');
        return res.status(400).send('Not a push event.');
    }
});

app.listen(port, () => {
    console.log(`Listening for webhooks on port ${port}`);
});
