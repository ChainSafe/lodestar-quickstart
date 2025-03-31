#!/bin/bash
# set -e

scriptDir=$(dirname $0)
currentDir=$(pwd)

source parse-args.sh
source import-images.sh
source import-args.sh
source "./fixed.vars"
if [ ! -n "$devnetVars" ] 
then
  echo "You need to specify the corresponding network.vars file, for e.g. kiln.vars, exiting ..."
  exit;
fi;
source $devnetVars
source validate.sh

currentDir=$(pwd)

setupConfigUrl="https://github.com/eth-clients/merge-testnets.git"
if [ -n SETUP_CONFIG_URL ]
then
  setupConfigUrl="$SETUP_CONFIG_URL"
fi;

setupBranch="main"
if [ -n SETUP_CONFIG_BRANCH ]
then
  setupBranch="$SETUP_CONFIG_BRANCH"
fi;

configGitDir=$CONFIG_GIT_DIR

gethImage=$GETH_IMAGE
nethermindImage=$NETHERMIND_IMAGE
rethImage=$RETH_IMAGE
mevBoostImage=$MEV_BOOST_IMAGE

if [[ "$dataDir" != /* ]]; then
  dataDir="$currentDir/$dataDir"
fi

mkdir $dataDir && mkdir $dataDir/lodestar && mkdir $dataDir/geth && mkdir $dataDir/nethermind && mkdir $dataDir/reth && mkdir $dataDir/ethereumjs && mkdir $dataDir/besu && mkdir $dataDir/erigon && mkdir $dataDir/mevboost

if [ -n "$configGitDir" ]
then
  if [ ! -n "$(ls -A $dataDir/$configGitDir)" ]
  then
    cmd="cd $dataDir && git init && git remote add -f origin $setupConfigUrl && git config core.sparseCheckout true && echo "$configGitDir/*" >> .git/info/sparse-checkout && git pull origin $setupBranch && cd $currentDir"
    echo $cmd
    cd $dataDir && git init && git remote add -f origin $setupConfigUrl && git config core.sparseCheckout true && echo "$configGitDir/*" >> .git/info/sparse-checkout && git pull origin $setupBranch && cd $currentDir
  fi;

  if [ ! -n "$(ls -A $dataDir/$configGitDir/el_bootnode.txt)" ]
  then
    # one of the files will have el bootnodes
    cp $dataDir/$configGitDir/bootnodes.txt $dataDir/$configGitDir/el_bootnode.txt
    cp $dataDir/$configGitDir/bootnode.txt $dataDir/$configGitDir/el_bootnode.txt
    cp $dataDir/$configGitDir/enodes.txt $dataDir/$configGitDir/el_bootnode.txt
  fi;
  # if there is a dynamic inventory url pull from there
  if [ -n "$SETUP_CONFIG_INVENTORY_URL" ]
  then
    enodeCmd="curl $SETUP_CONFIG_INVENTORY_URL | jq -r ".ethereum_pairs[].execution.enode" > $dataDir/$configGitDir/el_bootnode.txt"
    echo "------------------------------------------"
    echo "fetching enodes: enodeCmd=$enodeCmd"
    echo "------------------------------------------"
    eval "$enodeCmd"
  fi;

  if [ ! -n "$(ls -A $dataDir/$configGitDir/boot_enr.yaml)" ]
  then
    # one of the files will have cl bootnodes
    cp $dataDir/$configGitDir/bootstrap_nodes.txt $dataDir/$configGitDir/boot_enr.yaml
  fi;
  # if there is a dynamic inventory url pull from there
  if [ -n "$SETUP_CONFIG_INVENTORY_URL" ]
  then
    bootenrCmd="curl $SETUP_CONFIG_INVENTORY_URL | jq -r ".ethereum_pairs[].consensus.enr" > $dataDir/$configGitDir/boot_enr.yaml"
    echo "------------------------------------------"
    echo "fetching enrs: bootenrCmd=$bootenrCmd"
    echo "------------------------------------------"
    eval "$bootenrCmd"
  fi;

  if [ ! -n "$(ls -A $dataDir/$configGitDir)" ] || [ ! -n "$(ls -A $dataDir/$configGitDir/genesis.ssz)" ] || ( [ ! -n "$(ls -A $dataDir/$configGitDir/el_bootnode.txt)" ] ) || ( [ ! -n "$(ls -A $dataDir/$configGitDir/boot_enr.yaml)" ] )
  then
    echo "Configuration directory not setup properly, remove the data directory and run again."
    echo "exiting ..."
    exit;
  else
    echo "Configuration discovered!"
  fi;



  # Load the required variables from the config dir
  bootNode=$(cat $dataDir/$configGitDir/el_bootnode.txt)
  bootNode=($bootNode)
  bootNodeWithSpace=$(IFS=" " ; echo "${bootNode[*]}")
  bootNode=$(IFS=, ; echo "${bootNode[*]}")

  bootEnr=$(cat $dataDir/$configGitDir/bootstrap_nodes.txt)
  bootEnr=($bootEnr)
  bootEnr=$(IFS=" " ; echo "${bootEnr[*]}")

  depositContractDeployBlock=$(cat $dataDir/$configGitDir/deposit_contract_block.txt)

else
  echo "No configuration specified, assuming the configuration baked in the images and args appropriately set to use it!"
fi;


run_cmd(){
  execCmd=$1;
  echo "------------------------------------------"
  if [ -n "$detached" ]
  then
    echo "running detached: $execCmd"
    eval "$execCmd"
  else
    if [ -n "$withTerminal" ]
    then
      execCmd="$withTerminal $execCmd"
    fi;
    echo "running: $execCmd &"
    eval "$execCmd" &
  fi;
  echo "------------------------------------------"
}

if [ -n "$dockerWithSudo" ]
then 
  dockerExec="sudo docker"
else 
  dockerExec="docker"
fi;
dockerCmd="$dockerExec run"

if [ -n "$detached" ]
then 
  dockerCmd="$dockerCmd --detach --restart unless-stopped"
else
  dockerCmd="$dockerCmd --rm"
fi;

if [ -n "$withTerminal" ]
then
  dockerCmd="$dockerCmd -it" 
fi;

platform=$(uname)

if [ $platform == 'Darwin' ]
then
  elDockerNetwork=""
else
  elDockerNetwork="--network host"
fi;

if [ ! -n "$skipImagePull" ]
then
  if [ ! -n "$justCL" ] && [ ! -n "$justVC" ]
  then
    if [ "$elClient" == "geth" ]
    then
      $dockerExec pull $GETH_IMAGE
    elif [ "$elClient" == "nethermind" ]
    then
      $dockerExec pull $NETHERMIND_IMAGE
    elif [ "$elClient" == "reth" ]
    then
      $dockerExec pull $RETH_IMAGE
    elif [ "$elClient" == "ethereumjs" ]
    then
      $dockerExec pull $ETHEREUMJS_IMAGE
    elif [ "$elClient" == "besu" ]
    then
      $dockerExec pull $BESU_IMAGE
    elif [ "$elClient" == "erigon" ]
    then
      $dockerExec pull $ERIGON_IMAGE
    fi;
  fi;

  if [ ! -n "$justEL" ] && [ ! -n "$justMevBoost" ]
  then
    $dockerExec pull $LODESTAR_IMAGE
  fi;

  if [ -n "$justMevBoost" ] || [ -n "$withMevBoost" ]
  then
    $dockerExec pull $MEV_BOOST_IMAGE
  fi;
fi

if [ "$elClient" == "geth" ]
then
  echo "gethImage: $GETH_IMAGE"

  if [ -n "$configGitDir" ] && [ ! -n "$(ls -A $dataDir/$configGitDir/genesis.json)" ]
  then
    echo "geth genesis file not found in config, exiting... "
    exit;
  fi;

  elName="$DEVNET_NAME-geth"
  if [ ! -n "$(ls -A $dataDir/geth)" ] && [ -n "$configGitDir" ]
  then
    if [ ! -n "$GETH_INIT_IMAGE" ]
    then
      GETH_INIT_IMAGE=$GETH_IMAGE
    fi;
    elSetupCmd="$dockerExec run --rm -v $dataDir/$configGitDir:/config -v $dataDir/geth:/data $GETH_INIT_IMAGE $GETH_EXTRA_INIT_PARAMS --datadir /data init /config/genesis.json"
    echo "------------------------------------------"
    echo "setting up geth directory: $elSetupCmd"
    echo "------------------------------------------"
    $elSetupCmd
  fi;

  elCmd="$dockerCmd --name $elName $elDockerNetwork -v $dataDir:/data $GETH_IMAGE $GETH_EXTRA_ARGS"
  if [ -n "$configGitDir" ]
  then
    elCmd="$elCmd --bootnodes $EXTRA_BOOTNODES$bootNode"
  fi;

elif [ "$elClient" == "nethermind" ] 
then
  echo "nethermindImage: $NETHERMIND_IMAGE"

  if [ -n "$configGitDir" ] && [ ! -n "$(ls -A $dataDir/$configGitDir/chainspec.json)" ]
  then
    echo "nethermind genesis file not found in config, exiting... "
    exit;
  fi;

  elName="$DEVNET_NAME-nethermind"
  elCmd="$dockerCmd --name $elName $elDockerNetwork -v $dataDir:/data"
  if [ -n "$configGitDir" ]
  then
    elCmd="$elCmd -v $dataDir/$configGitDir:/config $NETHERMIND_IMAGE --Discovery.Bootnodes $EXTRA_BOOTNODES$bootNode"
    if [ ! -n "$NETHERMIND_INBUILD_CONFIG" ]
    then
      elCmd="$elCmd --Init.ChainSpecPath=/config/chainspec.json"
    fi;
  else
    elCmd="$elCmd $NETHERMIND_IMAGE"
  fi;
  elCmd="$elCmd $NETHERMIND_EXTRA_ARGS"

elif [ "$elClient" == "reth" ] 
then
  echo "rethImage: $RETH_IMAGE"

  if [ -n "$configGitDir" ] && [ ! -n "$(ls -A $dataDir/$configGitDir/reth.toml)" ]
  then
    echo "reth config file not found in config, exiting... "
    exit;
  fi;

  elName="$DEVNET_NAME-reth"
  elCmd="$dockerCmd --name $elName $elDockerNetwork -v $dataDir:/data"
  if [ -n "$configGitDir" ]
  then
    elCmd="$elCmd -v $currentDir/$dataDir/$configGitDir:/config  $RETH_IMAGE node --config /config"
  else
    elCmd="$elCmd $RETH_IMAGE node"
  fi;
  elCmd="$elCmd $RETH_EXTRA_ARGS"

elif [ "$elClient" == "ethereumjs" ] 
then
  echo "ethereumjsImage: $ETHEREUMJS_IMAGE"

  if [ -n "$configGitDir" ] && [ ! -n "$(ls -A $dataDir/$configGitDir/genesis.json)" ]
  then
    echo "ethereumjs genesis file not found in config, exiting... "
    exit;
  fi;

  elName="$DEVNET_NAME-ethereumjs"
  elCmd="$dockerCmd --name $elName $elDockerNetwork -v $dataDir:/data"
  if [ -n "$configGitDir" ]
  then
    elCmd="$elCmd -v $dataDir/$configGitDir:/config  $ETHEREUMJS_IMAGE --bootnodes=$EXTRA_BOOTNODES$bootNode"
  else
    elCmd="$elCmd $ETHEREUMJS_IMAGE"
  fi;
  elCmd="$elCmd $ETHEREUMJS_EXTRA_ARGS "

elif [ "$elClient" == "besu" ] 
then
  echo "besuImage: $BESU_IMAGE"

  if [ -n "$configGitDir" ] && [ ! -n "$(ls -A $dataDir/$configGitDir/besu_genesis.json)" ]
  then
    echo "besu genesis file not found in config, exiting... "
    exit;
  fi;

  elName="$DEVNET_NAME-besu"
  elCmd="$dockerCmd --name $elName $elDockerNetwork -v $dataDir:/data"
  if [ -n "$configGitDir" ]
  then
    elCmd="$elCmd -v $dataDir/$configGitDir:/config  $BESU_IMAGE --genesis-file=/config/besu_genesis.json --bootnodes=$EXTRA_BOOTNODES$bootNode"
  else
    elCmd="$elCmd $BESU_IMAGE"
  fi;
  elCmd="$elCmd $BESU_EXTRA_ARGS"
elif [ "$elClient" == "erigon" ] 
then
  echo "erigonImage: $ERIGON_IMAGE"

  if [ -n "$configGitDir" ] && [ ! -n "$(ls -A $dataDir/$configGitDir/erigon_genesis.json)" ]
  then
    echo "erigon genesis file not found in config, exiting... "
    exit;
  fi;

  elName="$DEVNET_NAME-erigon"
  elCmd="$dockerCmd --name $elName $elDockerNetwork -v $dataDir:/data"
  if [ -n "$configGitDir" ]
  then
    elCmd="$elCmd -v $dataDir/$configGitDir:/config  $ERIGON_IMAGE --bootnodes=$EXTRA_BOOTNODES$bootNode"
  else
    elCmd="$elCmd $ERIGON_IMAGE"
  fi;
  elCmd="$elCmd $ERIGON_EXTRA_ARGS"
fi

echo "lodestarImage: $LODESTAR_IMAGE"

if [ $platform == 'Darwin' ]
then
  clDockerNetwork="--net=container:$elName"
else
  clDockerNetwork="--network host"
fi

clName="$DEVNET_NAME-lodestar"
clCmd="$dockerCmd --env NODE_OPTIONS='--max_old_space_size=8192' --name $clName $clDockerNetwork -v $dataDir:/data"
# mount and use config
if [ -n "$configGitDir" ]
then
  clCmd="$clCmd -v $dataDir/$configGitDir:/config $LODESTAR_IMAGE beacon --paramsFile /config/config.yaml --genesisStateFile /config/genesis.ssz --eth1.depositContractDeployBlock $depositContractDeployBlock --bootnodesFile /config/boot_enr.yaml"
else
  clCmd="$clCmd $LODESTAR_IMAGE beacon"
fi;
clCmd="$clCmd $LODESTAR_EXTRA_ARGS"

if [ -n "$withMevBoost" ]
then
  clCmd="$clCmd --builder --builder.urls $MEVBOOST_URL"
fi;

valName="$DEVNET_NAME-validator"
if [ -n "$withValidatorKeystore" ]
then
  # generate an unique id with path for this particular validator
  hash="$(echo -n "$withValidatorKeystore" | md5sum )"
  hasharr=($hash)
  keystoreDirHash="${hasharr[0]}"
  mkdir "$dataDir/lodestar/$keystoreDirHash"

  # keystoreDir is where the keystores are to be expected, keystores and pass.txt will be picked from here
  # also the validator db will be saved here which is very important for past validator choices
  actualKeystoreDir="$withValidatorKeystore"
  actualDataDir="$dataDir/lodestar/$keystoreDirHash"
  valName="$valName-${keystoreDirHash}"
else
  # use current dir for keystore dir which will be used primarily for validator db here
  actualKeystoreDir="$currentDir"
  actualDataDir="$dataDir/lodestar"
fi;
# we are additionally mounting current dir to /currentDir if anyone wants to provide keystores
valCmd="$dockerCmd --name $valName $clDockerNetwork -v $actualDataDir:/data -v $actualKeystoreDir:/keystoresDir"
# mount and use config
if [ -n "$configGitDir" ]
then
  valCmd="$valCmd -v $dataDir/$configGitDir:/config $LODESTAR_IMAGE validator --paramsFile /config/config.yaml"
else
  valCmd="$valCmd $LODESTAR_IMAGE validator"
fi;
valCmd="$valCmd $LODESTAR_VALIDATOR_ARGS $validatorKeyArgs"

if [ -n "$withMevBoost" ]
then
  valCmd="$valCmd --builder"
fi;

echo -n $JWT_SECRET > $dataDir/jwtsecret
terminalInfo=""

# if we don't have any of the just flags, we need to launch the EL
if [ ! -n "$justCL" ] && [ ! -n "$justVC" ] && [ ! -n "$justMevBoost" ]
then
  cleanupEL=true
  run_cmd "$elCmd"
  elPid=$!
  echo "elPid= $elPid"
  terminalInfo="$terminalInfo elPid= $elPid for $elName"
  if [ -n "$justEL" ]
  then
    # Just placeholder copy the pid into el and val pid as we do a multi wait on them later
    clPid="$elPid"
    valPid="$elPid"
  fi;
fi;

if [ $platform == 'Darwin' ]
then
   # hack to allow network stack of EL to be up before starting the CL on macOs. Waiting on pid does not work
   sleep 5
fi

# if we don't have any of the other just flags then we need to launch EL
if [ ! -n "$justEL" ] && [ ! -n "$justVC" ] && [ ! -n "$justMevBoost" ]
then
  cleanupCL=true
  run_cmd "$clCmd"
  clPid=$!
  echo "clPid= $clPid"
  terminalInfo="$terminalInfo, clPid= $clPid for $clName"
  if [ -n "$justCL" ]
  then
    # Just placeholder copy the pid into el and val pid as we do a multi wait on them later
    elPid="$clPid"
    valPid="$clPid"
  fi;
fi;

# if we have validator start flags
if [ -n "$withValidator" ] || [ -n "$justVC" ]
then
  cleanupVAL=true
  run_cmd "$valCmd"
  valPid=$!
  echo "valPid= $valPid"
  terminalInfo="$terminalInfo, valPid= $valPid for $elName"
  if [ -n "$justVC" ]
  then
    # Just placeholder copy the pid into el and val pid as we do a multi wait on them later
    elPid="$valPid"
    clPid="$valPid"
  fi;
else 
   # hack to assign clPid to valPid for joint wait later
   valPid=$clPid
fi;

mevName="$DEVNET_NAME-mevboost"
mevCmd="$dockerCmd --name $mevName $clDockerNetwork -v $currentDir/$dataDir:/data $mevBoostImage $MEVBOOST_VARS"

# if we have mevBoost start flags, but not as justCL or justVC or justEL 
# as then it only means to enable mevboost
if ([ -n "$withMevBoost" ] && [ ! -n "$justCL" ] && [ ! -n "$justVC" ] && [ ! -n "$justEL" ]) || [ -n "$justMevBoost" ]
then
  cleanupMev=true
  run_cmd "$mevCmd"
  mevPid=$!
  echo "mevPid= $mevPid"
  terminalInfo="$terminalInfo, mevPid= $mevPid"
  if [ -n "$justMevBoost" ]
  then
    # Just placeholder copy the pid into el and val pid as we do a multi wait on them later
    elPid="$mevPid"
    clPid="$mevPid"
    valPid="$mevPid"
  fi;
else
    # hack to assign clPid to mevPid for joint wait later
    mevPid=$clPid
fi;

cleanup() {
  echo "cleaning up"
  # Cleanup only those that have been (tried) spinned up by this run of the script
  if [ -n "$cleanupEL" ]
  then
    $dockerExec stop $elName
    $dockerExec rm $elName -f
  fi;
  if [ -n "$cleanupCL" ]
  then
    $dockerExec stop $clName
    $dockerExec rm $clName -f
  fi;
  if [ -n "$cleanupVAL" ]
  then
    $dockerExec stop $valName
    $dockerExec rm $valName -f
  fi
  if [ -n "$cleanupMev" ]
  then
    $dockerExec stop $mevName
    $dockerExec rm $mevName -f
  fi;
  elPid=null
  clPid=null
  valPid=null
  mevPid=null
}

trap "echo exit signal recived;cleanup" SIGINT SIGTERM

if [ ! -n "$detached" ] && [ -n "$elPid" ] && [ -n "$clPid" ] && ([ ! -n "$withValidator" ] || [ -n "$valPid" ] ) && ([ ! -n "$withMevBoost" ] || [ -n "$mevPid" ])
then 
	echo "launched terminals for $terminalInfo"
	echo "you can watch observe the client logs at the respective terminals"
	echo "use ctl + c on any of these (including this) terminals to stop the process"
	echo "waiting ..."
	if [ $platform == 'Darwin' ]
	then # macOs ships with an old version of bash with wait that does not have the -n flag
	  wait $elPid
	  wait $clPid
    wait $valPid
    wait $mevPid
	else
	  wait -n  $elPid $clPid $valPid $mevPid
	fi
  echo "one of the el or cl process exited, stopping and cleanup"
	cleanup
fi;

# if its not detached and is here, it means one of the processes exited/didn't launch
if [ ! -n "$detached" ] && [ -n "$elPid$clPid$valPid$mevPid" ]
then
	echo "one of the processes didn't launch properly"
	cleanup
fi;

if [ -n "$detached" ]
then  
  echo "launched detached containers: $terminalInfo"
else 
  echo "exiting ..."
fi;
