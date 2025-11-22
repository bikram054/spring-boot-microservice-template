#!/bin/bash

# Default credentials (change these as needed)
AUTH_USERNAME=${AUTH_USERNAME:-"admin"}
AUTH_PASSWORD=${AUTH_PASSWORD:-"admin123"}

echo "Running JMeter performance tests with basic authentication..."
echo "Username: $AUTH_USERNAME"

export AUTH_USERNAME AUTH_PASSWORD
make perf-test