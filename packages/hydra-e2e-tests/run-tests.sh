#!/bin/bash

cleanup()
{
  (echo "## Processor Logs ##" && docker logs hydra-e2e-tests_hydra-processor_1 --tail 50) || :
  (echo "## Processor Server Logs ##" && docker logs hydra-e2e-tests_processor-gql-server_1 --tail 50) || :  
  (echo "## Indexer Logs ##" && docker logs hydra-e2e-tests_hydra-indexer_1 --tail 50) || :  
  (echo "## Indexer API Server ##" && docker logs hydra-e2e-tests_hydra-indexer-gateway_1 --tail 50) || :  
  yarn post-e2e-test
}

set -e
# clean up
trap cleanup ERR EXIT SIGINT SIGTERM

docker build ../../ -t hydra-builder:latest
#docker build ../hydra-cli -t hydra-cli:latest 
docker build ./schema -t hydra:latest
docker build ../hydra-indexer -t hydra-indexer:latest
docker build ../hydra-indexer-gateway -t hydra-indexer-gateway:latest

docker-compose up -d
# wait for the indexer api to start 
attempt_counter=0
max_attempts=10

until $(curl -s --head  --request GET http://localhost:4001/graphql | grep "400" > /dev/null);  do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
      echo "Max attempts reached"
      exit 1
    fi

    printf '.'
    attempt_counter=$(($attempt_counter+1))
    sleep 5
done 

# run the actual tests
yarn e2e-test-local
