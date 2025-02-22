#!/bin/bash

#
# Initializing color vars
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
NC=$(tput sgr0)
###
# Starting cluster
###
echo -e "\n\n${RED}Destroying cluster with volumes${NC}\n\n"
#
cd ./task02-mongo-sharding-repl/scripts
docker compose -f ../compose.yaml down
docker compose -f ../compose.yaml down -v
docker volume prune

echo -e "\n\n${RED}Destroyed!${NC}\n\n"
cd ../../