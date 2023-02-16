#!/bin/sh

if [ -n "$withValidatorMnemonic" ] && [ -n "$withValidatorKeystore" ]
then
  echo "Only of of --withValidatorMnemonic or --withValidatorKeystore options should be provided, exiting..."
  exit;
fi
if [ -n "$withValidatorMnemonic" ]
then
  if [ "$DEVNET_NAME" == "mainnet" ]
  then
    echo "withValidatorMnemonic is not safe to use on mainnet, please use withValidatorKeystore with correctly set LODESTAR_VALIDATOR_KEYSTORE_ARGS, exiting..."
    exit;
  fi;
  withValidator="withValidatorMnemonic";
  validatorKeyArgs="$LODESTAR_VALIDATOR_MNEMONIC_ARGS"
  if [ ! -n "$validatorKeyArgs" ]
  then
    echo "To run validator with mnemonic, you need to set LODESTAR_VALIDATOR_MNEMONIC_ARGS, exiting..."
    exit;
  fi;
fi;

if [ -n "$withValidatorKeystore" ]
then
  if [ ! -n "$(ls -A $withValidatorKeystore)" ]
  then
    echo "Can't access keystore dir: $withValidatorKeystore, please pass correct dir with keystores folder and pass.txt as arg value for --withValidatorKeystore, exiting..."
    exit;
  fi;
  withValidator="true";
  validatorKeyArgs="$LODESTAR_VALIDATOR_KEYSTORE_ARGS"
  if [ ! -n "$validatorKeyArgs" ]
  then
    echo "To run validator with keystores, you need to set LODESTAR_VALIDATOR_KEYSTORE_ARGS, exiting ..."
    exit;
  fi;
fi;

if [ -n "$justVC" ] && [ ! -n "$withValidator" ]
then
  echo "To run validator, you need to provide either one of --withValidatorMnemonic or --withValidatorKeystore, exiting..."
  exit;
fi;

echo "withValidator = $withValidator, $validatorKeyArgs"
echo "detached = $detached"

if [ -n "$withTerminal" ] && [ -n "$detached" ]
then
  echo "Only of of --withTerminal or --detached options should be provided, exiting..."
  exit;
fi

if [ -n "$justMevBoost" ] && ( [ -n "$justEL" ] || [ -n "$justCL" ] || [ -n "$justVC" ] || [ -n "$withValidator" ] )
then
  echo "--justMevBoost can not be with --justEL or --justCL or --justVC or --withValidator. Try using only --justMevBoost, exiting..."
  exit;
fi;

# withMevBoost can exist with justCl or justVC
if [ -n "$withMevBoost" ] && ( [ -n "$justEL" ] )
then
  echo "--withMevBoost can not be with --justEL or --justVC. exiting..."
  exit;
fi;

if [ -n "$withValidator" ] && ( [ -n "$justEL" ] || [ -n "$justCL" ] || [ -n "$justMevBoost" ] )
then
  echo "--withValidator can not be just with --justEL or --justCL  or --justMevBoost, exiting..."
  exit;
fi;

if [ -n "$justEL" ] && ( [ -n "$justCL" ] || [ -n "$justVC" ] || [ -n "$justMevBoost" ] ) || [ -n "$justCL" ] && ( [ -n "$justEL" ] || [ -n "$justVC" ]  ) || [ -n "$justVC" ] && ( [ -n "$justEL" ] || [ -n "$justCL" ] || [ -n "$justMevBoost" ] )
then
  echo "only one of --justEL, --justCL or --justVC or --justMevBoost can be used at a time. You can however start another (parallel) run(s) to spin them up separately, exiting..."
  exit;
fi

if [ ! -n "$dataDir" ]
then
  echo "Please provide a data directory. If you are running fresh, the dataDir should be non existant for setup to configure it properly, exiting...";
  exit;
fi;


if [ -n "$justCL" ] && [ -n "$justVC" ]  && ([ "$elClient" != "geth" ] && [ "$elClient" != "nethermind" ] && [ "$elClient" != "ethereumjs" ] && [ "$elClient" != "besu" ] && [ "$elClient" != "erigon" ]) 
then
  echo "To run EL client you need to provide one of --elClient <geth | nethermind | ethereumjs | besu | erigon>, exiting ...";
  exit;
fi

if [ ! -n "$JWT_SECRET" ]
then
  echo "You need to provide a file containing 32 bytes JWT_SECRET in hex format, exiting ..."
  exit;
fi;