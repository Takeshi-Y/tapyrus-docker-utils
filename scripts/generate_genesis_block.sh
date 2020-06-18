#!/bin/bash -eu

output_dir=${OUTPUT_DIR:-/outputs}

agg_pub_key=`cat /outputs/aggregate_public_key`
command="tapyrus-genesis
          -signblockpubkey=${agg_pub_key}"
genesis_block=`${command}`

echo ${genesis_block} > ${output_dir}/genesis_block
