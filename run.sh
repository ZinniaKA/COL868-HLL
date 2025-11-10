#!/bin/bash

# Clear the state of the containers in case they are running
docker-compose \
  -f docker-compose.yml \
  -f docker-compose.plotter.yml \
  down

# Set up and start the Docker containers
docker-compose \
  -f docker-compose.yml \
  -f docker-compose.plotter.yml \
  up -d

# --- Wait for pgdb ---
echo "Waiting for pgdb to be ready..."

# can successfully connect to the 'mydb' database (-d mydb)
while ! docker exec pgdb pg_isready -q -U postgres -d mydb; do
    printf "."
    sleep 1
done

echo "Database is ready!"
# --- End Wait ---


docker exec pgdb psql -f experiment_1.sql
docker exec plotter python plot_experiment_1.py

docker exec pgdb psql -f experiment_2.sql
docker exec plotter python plot_experiment_2.py