#!/bin/bash

# Colors
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}Stopping all microservices...${NC}"

pkill -f "spring-boot:run"

echo -e "${RED}All services stopped.${NC}"
