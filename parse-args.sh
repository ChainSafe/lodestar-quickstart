#!/bin/sh

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  	--elClient)
      elClient="$2"
      shift # past argument
      shift # past value
      ;;
    --dataDir)
      dataDir="$2"
      shift # past argument
      shift # past value
      ;;
    --network)
      network="$2"
      shift # past argument
      shift # past value
      ;;
    --withTerminal)
      withTerminal="$2"
      shift # past argument
      shift # past value
      ;;
    --dockerWithSudo)
      dockerWithSudo=true
      shift # past argument
      ;;
    --withValidatorMnemonic)
      withValidatorMnemonic=true
      shift # past argument
      ;;
    --withValidatorKeystore)
      withValidatorKeystore="$2"
      shift # past argument
      shift # past value
      ;;
    --justEL)
      justEL=true
      shift # past argument
      ;;
    --justCL)
      justCL=true
      shift # past argument
      ;;
    --justVC)
      justVC=true
      shift # past argument
      ;;
    --detached)
      detached=true
      shift # past argument
      ;;
    --skipImagePull)
      skipImagePull=true
      shift # past argument
      ;;
    --justMevBoost)
      justMevBoost=true
      shift
      ;;
    --withMevBoost)
      withMevBoost=true
      shift
      ;;
    *)    # unknown option
      shift # past argument
      ;;
  esac
done

# key won't ever get assigned in while loop if there is no arg, in that case print usage
if [[ ! -n "$key" ]];
then
  echo "usage: ./setup.sh --dataDir <data dir> --elClient <geth | nethermind | ethereumjs | besu | erigon> --devetVars <devnet vars file> [--dockerWithSudo --withTerminal --withMevBoost \"gnome-terminal --disable-factory --\"]"
  echo "example: ./setup.sh --dataDir sepolia-data --elClient nethermind --network sepolia --dockerWithSudo --withTerminal \"gnome-terminal --disable-factory --\""
  echo "Note: if running on macOS where gnome-terminal is not available, remove the gnome-terminal related flags."
  echo "example: ./setup.sh --dataDir sepolia-data --elClient geth --network sepolia"
  exit;
fi;

if [ -n "$network" ]
then
  devnetVars="$scriptDir/$network.vars"
fi;

echo "scriptDir = $scriptDir"
echo "currentDir = $currentDir"
echo "elClient = $elClient"
echo "dataDir = $dataDir"
echo "devnetVars = $devnetVars"
echo "withTerminal = $withTerminal"
echo "dockerWithSudo = $dockerWithSudo"
