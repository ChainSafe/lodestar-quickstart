# if the env overrides are not defined set the defaults

if [ ! -n "$GETH_IMAGE" ]
then
  GETH_IMAGE=ethereum/client-go:latest
fi;

if [ ! -n "$NETHERMIND_IMAGE" ]
then
  NETHERMIND_IMAGE=nethermind/nethermind:latest
fi;

if [ ! -n "$ETHEREUMJS_IMAGE" ]
then
  ETHEREUMJS_IMAGE=ethpandaops/ethereumjs:stable
fi;

if [ ! -n "$BESU_IMAGE" ]
then
  BESU_IMAGE=hyperledger/besu:latest
fi;

if [ ! -n "$ERIGON_IMAGE" ]
then
  ERIGON_IMAGE=thorax/erigon:stable
fi;

if [ ! -n "$MEV_BOOST_IMAGE" ]
then
  MEV_BOOST_IMAGE=flashbots/mev-boost:latest
fi;

if [ ! -n "$LODESTAR_IMAGE" ]
then
  LODESTAR_IMAGE=chainsafe/lodestar:latest
fi;

