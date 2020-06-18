#!/bin/bash -eu

signer_count=${1:-3}
threshold=${2:-2}

docker run --rm --volume=$PWD/scripts:/scripts --volume=$PWD/outputs:/outputs -e SIGNER_COUNT=${signer_count} -e THRESHOLD${threshold} hawyasunaga/tapyrus-signer:v0.4.0 /scripts/generate_aggregate_public_key.sh
docker run --rm --volume=$PWD/scripts:/scripts --volume=$PWD/outputs:/outputs hawyasunaga/tapyrus-core:v0.4.0 /scripts/generate_genesis_block.sh
docker run --rm --volume=$PWD/scripts:/scripts --volume=$PWD/outputs:/outputs -e SIGNER_COUNT=${signer_count} -e THRESHOLD${threshold} hawyasunaga/tapyrus-signer:v0.4.0 /scripts/generate_signed_genesis_block.sh

output_dir='./outputs'

genesis_block_with_sig=`cat ${output_dir}/genesis_block_with_sig`

docker_compose=$(cat << EOS
version: "3.0"
volumes:
  redis:
  tapyrus:
services:
  redis:
    image: redis:6
    command: ["redis-server", "--appendonly", "yes"]
    volumes:
      - redis:/data
    restart: on-failure
  tapyrus-core:
    image: hawyasunaga/tapyrus-core:v0.4.0
    environment:
      GENESIS_BLOCK_WITH_SIG: '${genesis_block_with_sig}'
    volumes:
      - tapyrus:/var/lib/tapyrus
      - ./tapyrus.conf:/etc/tapyrus/tapyrus.conf
    restart: on-failure
EOS
)

echo -e "${docker_compose}" > docker-compose.yml

docker-compose up -d
sleep 5
to_address=$(docker-compose run --rm tapyrus-core tapyrus-cli -rpcconnect=tapyrus-core -datadir=/var/lib/tapyrus -conf=/etc/tapyrus/tapyrus.conf getnewaddress | sed -e "s/[\r\n]\+//g")
docker-compose stop

for ((i=0; i<${signer_count}; i++)); do
  pub_keys+=(`cat ${output_dir}/${i}/pub_key`)
done

for ((i=0; i<${signer_count}; i++)); do
  docker_compose+="\n$(cat << EOS
  tapyrus-signer-${i}:
    image: hawyasunaga/tapyrus-signer:v0.4.0
    environment:
      REDIS_HOST: redis
      TAPYRUS_CORE_HOST: 'tapyrus-core'
      TAPYRUS_CORE_PORT: 2377
      PUBLIC_KEY: '${pub_keys[${i}]}'
      TO_ADDRESS: '${to_address}'
    volumes:
      - ./outputs/${i}/federations.toml:/etc/tapyrus/federations.toml
    depends_on:
      - tapyrus-core
    restart: on-failure
EOS
)"
done

echo -e "${docker_compose}" > docker-compose.yml