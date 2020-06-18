# tapyrus-docker-utils

## About

`tapyrus-docker-utils` is a easy to use scripts for [Tapyrus](https://github.com/chaintope/tapyrus-core) with [Docker](https://www.docker.com/)

### create_new_tapyrus_network.sh

Generate `docker-compose.yml` and related files for new Tapyrus Network.

## Requirements

* Docker Engine 1.13.0+
* Docker Compose 1.10.0+

## Quick Start

### Create new Tapyrus network

```bash
$ ./create_new_tapyrus_network.sh
Creating network "tapyrus-docker_default" with the default driver
Creating volume "tapyrus-docker_redis" with default driver
Creating volume "tapyrus-docker_tapyrus" with default driver
Creating tapyrus-docker_redis_1        ... done
Creating tapyrus-docker_tapyrus-core_1 ... done
Stopping tapyrus-docker_redis_1        ... done
Stopping tapyrus-docker_tapyrus-core_1 ... done

$ docker-compose up -d
Starting tapyrus-docker_tapyrus-core_1 ... done
Starting tapyrus-docker_redis_1        ... done
Creating tapyrus-docker_tapyrus-signer-0_1 ... done
Creating tapyrus-docker_tapyrus-signer-1_1 ... done
Creating tapyrus-docker_tapyrus-signer-2_1 ... done
```

Create and running 1 Tapyrus Core node and 3 Tapyrus Signer node.

### Use `tapyrus-cli`

```bash
$ docker-compose run --rm tapyrus-core tapyrus-cli -rpcconnect=tapyrus-core -conf=/etc/tapyrus/tapyrus.conf getblockchaininfo

{
  "chain": "1",
  "mode": "prod",
  "blocks": 3,
  "headers": 3,
  "bestblockhash": "7a17d3b47dda3b7b5ae1a6b5188f58074c886e207fd0d6e276f896340c3e94d3",
  "mediantime": 1593170357,
  "verificationprogress": 1,
  "initialblockdownload": false,
  "size_on_disk": 1222,
  "pruned": false,
  "aggregatePubkeys": [
    {
      "023fb2da40ce8b6c4f1ea1ab5fe78370846320ff09fa37f9856dc74165eb3907e4": 0
    }
  ],
  "warnings": ""
}
```

## How to use

### Specify tapyrus-signer node amount and threshold.

#### Example

##### 3 Tapyrus Signer node (3 signers required to sign block.)

```bash
$ ./create_new_tapyrus_network.sh 3 3
```

##### 10 Tapyrus Signer node (5 signers required to sign block.)

```bash
$ ./create_new_tapyrus_network.sh 10 5
```
