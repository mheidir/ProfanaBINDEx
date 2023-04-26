#!/bin/bash

if [[ "$#" -eq 0 ]]; then
    docker compose -f docker-compose.yml create
    docker compose -f docker-compose.yml start
else
    docker compose -f docker-compose.yml down
fi
