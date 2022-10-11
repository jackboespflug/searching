# Searching

Spike to investigate ElasticSearch segments when updating documents.

## Docker Compose

A docker compose file exists to in the `middleware` directory to facilitate the ElasticSearch and Kibana components.

``` bash command-line
cd middleware

# start the docker containers either attached to the foreground console, or detached in the background

# detached - use docker-compose down to stop
docker-compose up -d
docker-compose down

# attached - use ctrl+c to stop
docker-compose up

# check container status
docker ps

cd ..
```

## Phoenix Backend

A Phoenix based Elixir application provides a data generator to create and update documents in ElasticSearch.

## React Frontend

A React based Javascript application provides controls to start / stop data generation and graphs to display ElasticSearch segment utilization.

## Running

A bash startup script is provided to facilitate running both the backend and frontend applications.

``` bash command-line
# start both the Phoenix web app and frontend React app
./start.sh

# install and compile all dependencies and then start both the Phoenix web app and frontend React app
./start.sh install

# Stopping the applications

# Find the PIDS of the frontend application and kill it
lsof -i -n -P | grep LISTEN | grep 3000
kill PID

# Find the PIDs of the backend application, and kill it
lsof -i -n -P | grep LISTEN | grep 4000
kill PID
```
