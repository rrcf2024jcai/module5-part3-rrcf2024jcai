#!/bin/bash
# Part 1: Automated Deployment Script
# This script handles idempotency, prerequisites, and deployment.

echo "--- Starting Pre-deployment Checks ---"

# Validate Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is missing! Please install it."
    exit 1
else
    echo "Docker is installed."
fi

# Validate jq is installed for JSON parsing later
if ! command -v jq &> /dev/null; then
    echo "jq is missing! Installing jq now..."
    sudo apt-get update && sudo apt-get install -y jq
else
    echo "jq is already installed."
fi

# Validate docker-compose.yaml exists in this directory
if [ ! -f "docker-compose.yml" ] && [ ! -f "docker-compose.yaml" ]; then
    echo "docker-compose file not found!"
    exit 1
else
    echo "docker-compose file found."
fi

echo "--- Ensuring Idempotency ---"
# Idempotency check: Bring down any existing containers so we don't get errors if we run this twice
echo "Cleaning up old environment if it exists..."
docker compose down -v

echo "--- Building and Deploying ---"
# Build and deploy in detached mode
docker compose up -d --build

echo "Waiting 15 seconds for services to fully start..."
sleep 15

echo "--- Validating Deployment ---"
echo "Listing images:"
docker images

echo "Listing running containers:"
docker ps

echo "--- Performing Health Checks ---"
# Check Backend API (Port 5000)
if curl -s http://localhost:5000 > /dev/null; then
    echo "Backend (Port 5000) is responding!"
else
    echo "Backend might be down."
fi

# Check Transactions API (Port 3000)
if curl -s http://localhost:3000 > /dev/null; then
    echo "Transactions (Port 3000) is responding!"
else
    echo "Transactions might be down."
fi

echo "--- Validating Frontend Render ---"
# Check if the page renders and contains our exact branding text
if curl -s http://localhost:80 | grep -q "Pixel River Financial Bank Application"; then
    echo "Frontend rendered successfully with correct branding!"
else
    echo "Frontend rendering issue or branding missing."
fi

echo "--- Collecting Nginx Data ---"
# Grab the container ID for nginx
NGINX_ID=$(docker ps -q -f "ancestor=nginx:alpine")
echo "Nginx Container ID is: $NGINX_ID"

# Inspect the image and save to a text file named nginx-logs
echo "Saving docker inspect data to nginx-logs..."
docker inspect nginx:alpine > nginx-logs

echo "--- Extracting Data with jq ---"
# Extract specified keys from the log file
echo "RepoTags:"
jq '.[0].RepoTags' nginx-logs

echo "Created:"
jq '.[0].Created' nginx-logs

echo "Os:"
jq '.[0].Os' nginx-logs

echo "Config:"
jq '.[0].Config' nginx-logs

echo "ExposedPorts:"
jq '.[0].Config.ExposedPorts' nginx-logs

echo "--- Deployment Script Finished Successfully! ---"