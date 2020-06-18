#!/bin/bash -eu

signer_count=${SIGNER_COUNT:-3}
threshold=${THRESHOLD:-2}
output_dir=${OUTPUT_DIR:-/outputs}

# Import variables
agg_pub_key=`cat /outputs/aggregate_public_key`
genesis_block=`cat ${output_dir}/genesis_block`

for ((i=0; i<$signer_count; i++)); do
  priv_keys+=(`cat ${output_dir}/${i}/priv_key`)
  pub_keys+=(`cat ${output_dir}/${i}/pub_key`)
  secret_shares+=(`cat ${output_dir}/${i}/secret_share`)
done
node_vss_0=(`cat ${output_dir}/0/node_vss`)

# Create Block VSS
for ((i=0; i<$signer_count; i++)); do
  command="tapyrus-setup createblockvss
          --private-key=${priv_keys[${i}]}
          --threshold=${threshold}"
  for((j=0; j<$signer_count; j++)); do
    public_key=pub_keys[$j]
    eval public_key=\$\{$public_key\}
    command+=" --public-key=${public_key}"
  done

  result=(`${command}`)

  for output in ${result[@]}; do
    pubkey_vss=(${output//:/ })
    pubkey=${pubkey_vss[0]}
    vss=${pubkey_vss[1]}

    for ((j=0; j<${#pub_keys[@]}; j++)); do
      if [ ${pubkey} = ${pub_keys[$j]} ]; then
        array_name=block_vss_$j
        eval $array_name+=\(\$vss\)
      fi
    done
  done
done

# Sign
for ((i=0; i<$signer_count; i++)); do
  command="tapyrus-setup sign
            --aggregated-public-key=${agg_pub_key}
            --node-secret-share=${secret_shares[${i}]}
            --private-key=${priv_keys[${i}]}
            --block=${genesis_block}
            --threshold=${threshold}"

  for((j=0; j<$signer_count; j++)); do
    vss=block_vss_$i[$j]
    eval vss=\$\{$vss\}
    command+=" --block-vss=${vss}"
  done

  sigs+=(`${command}`)
done

# Compute Sig
command="tapyrus-setup computesig
          --private-key=${priv_keys[0]}
          --block=${genesis_block}
          --aggregated-public-key=${agg_pub_key}
          --node-secret-share=${secret_shares[0]}
          --threshold=${threshold}"

for((i=0; i<$signer_count; i++)); do
  vss=node_vss_0[$i]
  eval vss=\$\{$vss\}
  command+=" --node-vss=${vss}"
done

for((i=0; i<$signer_count; i++)); do
  vss=block_vss_0[$i]
  eval vss=\$\{$vss\}
  command+=" --block-vss=${vss}"
done

for sig in ${sigs[@]}; do
  command+=" --sig=${sig}"
done

# Output
genesis_block_with_sig=`${command}`

echo ${genesis_block_with_sig} > ${output_dir}/genesis_block_with_sig
