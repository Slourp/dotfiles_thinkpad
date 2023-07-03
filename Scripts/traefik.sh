#!/bin/bash

# Define variables
DEV_COMPOSE_FILE="/home/$USER/code/popfrance/traefik/docker-compose.dev.yml"
PROD_COMPOSE_FILE="/home/$USER/code/popfrance/traefik/docker-compose.prod.yml"

# Function to start Traefik
function start_traefik() {
local env="$1"
case $env in
   dev)
     docker-compose -f $DEV_COMPOSE_FILE up -d
     ;;
   prod)
     docker-compose -f $PROD_COMPOSE_FILE up -d
     ;;
   *)
     echo "Invalid environment. Please specify either 'dev' or 'prod'."
     ;;
esac
}

# Function to stop Traefik
function stop_traefik() {
docker-compose -f $PROD_COMPOSE_FILE down
}

# Main function
function main() {
local command="$1"
local env="$2"
case $command in
   start)
     if [[ "$env" == "--dev" ]]; then
       start_traefik "dev";
     elif [[ "$env" == "--prod" ]]; then
       start_traefik "prod";
     else
       echo "Invalid environment. Please specify either '--dev' or '--prod'.";
     fi
     ;;
   stop)
     stop_traefik
     ;;
   *)
     echo "Invalid command. Please specify either 'start' or 'stop'."
     ;;
esac
}

# Call the main function with command line arguments
main "$@"
