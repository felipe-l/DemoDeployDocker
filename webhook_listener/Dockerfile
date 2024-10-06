# Use official Node.js image as base
FROM node:14

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json for dependency installation
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application files
COPY . .

# Define the environment variable for the port (default to 8080)
ENV PORT 8080

# Expose the port specified in the environment variable
EXPOSE ${PORT}

# Run the application
CMD ["node", "index.js"]
