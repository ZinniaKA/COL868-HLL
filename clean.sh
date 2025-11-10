#!/bin/bash

# Stop and remove the Docker containers and images
docker-compose \
  -f docker-compose.yml \
  -f docker-compose.plotter.yml \
  down \
  --rmi all

rm -rf plots/ tables/