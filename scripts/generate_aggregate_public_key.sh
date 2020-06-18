#!/bin/bash -eu

signer_count=${SIGNER_COUNT:-3}
threshold=${THRESHOLD:-2}
output_dir=${OUTPUT_DIR:-/outputs}

# Create signer priv/pub keys
for ((i=0; i<$signer_count; i++)); do
  command="tapyrus-setup createkey"
  key_pair=(`${command}`)

  priv_keys+=(${key_pair[0]})
  pub_keys+=(${key_pair[1]})
done

# Create node vss
for ((i=0; i<$signer_count; i++)); do
  command="tapyrus-setup createnodevss
            --private-key=${priv_keys[$i]}
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
        array_name=node_vss_$j
        eval $array_name+=\(\$vss\)
      fi
    done
  done
done

# Generate an Aggregated public key
for ((i=0; i<$signer_count; i++)); do
  command="tapyrus-setup aggregate
            --private-key=${priv_keys[$i]}"

  for ((j=0; j<$signer_count; j++)); do
    vss=node_vss_$i[$j]
    eval vss=\$\{$vss\}
    command+=" --vss=${vss}"
  done

  result=(`${command}`)
  agg_pub_key=${result[0]}
  sec_share+=(${result[1]})
done

# Output
echo ${agg_pub_key} > ${output_dir}/aggregate_public_key
for ((i=0; i<$signer_count; i++)); do
  mkdir -p ${output_dir}/${i}
  echo ${priv_keys[i]} > ${output_dir}/${i}/priv_key
  echo ${pub_keys[i]} > ${output_dir}/${i}/pub_key
  echo ${sec_share[i]} > ${output_dir}/${i}/secret_share

  eval echo \${node_vss_${i}[@]} | tr ' ' '\n' > ${output_dir}/${i}/node_vss

  eval vss=\(\${node_vss_${i}[@]}\)
  node_vss_array=$(printf ",\"%s\"" "${vss[@]}")

  cat << EOS > ${output_dir}/${i}/federations.toml
[[federation]]
block-height = 0
threshold = ${threshold}
aggregated-public-key = "${agg_pub_key}"
node-vss = [${node_vss_array:1}]
EOS
done
