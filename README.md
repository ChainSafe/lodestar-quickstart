# BREAKING CHANGE

Use `--network` flag instead of `--devnetVars` for e.g. `--network sepolia` instead of `--devnetVars sepolia.vars`

# Easy script to join the Ethereum networks

This is a setup to run and join the merge devnets, testnets, shadowforks and mainnet as well! with a single shell command. This script will pull the appropriate images and config and spin up the EL client and lodestar.

This script is borne out of need to simplify putting together the various moving parts of the post merge ethereum setup so that the users can have super fast onboarding, easy switch/test EL clients as well as can take inspiration for how to match/debug the configurations for their customized setups.

So just give it a go and fire away your merge setup command!

A comprehensive setup guide on how to use this merge script can be found here: https://hackmd.io/@philknows/rJegZyH9q

### Supported Networks

Look for the .vars file in the folder to see what networks are supported. There is a .vars file corresponding to a each network which will be loaded. Here are a few examples

1. **Mainnet**: `--network mainnet` (reads `mainnet.vars`)
2. Holesky Network: `--network holesky` (reads `holesky.vars`)
3. Sepolia Network: `--network sepolia` (reads `sepolia.vars`)
4. Verkle Kautinen 7: `--network kaustinen7` (reads `kaustinen7.vars`)
5. Pectra devnet 7: `--network pectra7` (reads `pectra7.vars`)
6. Hoodi Network: `--network hoodi` (reads `hoodi.vars`)

### Requirements

1. docker
2. git
3. A bash shell

### Example quickstart commands with arguments 

1. Run with separate terminals launched & attached (best for testing in local) :
   `./setup.sh --dataDir sepolia-data --elClient nethermind --network sepolia --withTerminal "gnome-terminal --disable-factory --" --dockerWithSudo `
2. Run _in-terminal_ attached with logs interleaved (best for testing in remote shell) :
   `./setup.sh --dataDir sepolia-data --elClient nethermind --network sepolia --dockerWithSudo`
3. Run detached (best for leaving it to run, typically after testing 1 or 2):
   `./setup.sh --dataDir sepolia-data --elClient nethermind --network sepolia --detached --dockerWithSudo`

### Supported EL clients

Look for the .vars file in the folder to see what networks are supported. Here are a few examples

1. Geth: `--elClient geth`
2. Nethermind: `--elClient nethermind`
3. Besu: `--elClient besu`
4. Ethereumjs: (might sync only small size testnets for now): `--elClient ethereumjs`
5. Erigon: `--elClient erigon`
6. Reth: `--elClient reth`

You can alternate between them (without needing to reset/cleanup) to experiment with the ELs being out of sync ( and catching up) with `lodestar` via **Optimistic Sync** features.

### Script parameters help

1. `dataDir`: Where you want the script and client's configuration data to be setup. Should be non-existent one for the first run. (The directory if already present will skip fetching the configuration, assuming it has done previously). You can also clean indivizual directories of CL/EL between the re-runs.
2. `elClient`: Which EL client you want, currently working with `geth` and `nethermind`
3. `network`: The network/chain you want to load, reads the corresponding `.vars` (for e.g. `sepolia.vars`) network configuration , like images, or urls for EL/CL to interact. Will be updated with new vars.
4. `dockerWithSudo`(optional): Provide this argument if your docker needs a sudo prefix
5. `--withTerminal`(optional): Provide the terminal command prefix for CL and EL processes to run in your favourite terminal.
   You may use an alias or a terminal launching script as long as it waits for the command it runs till ends and then closes.If not provided, it will launch the docker processes in _in-terminal_ mode.
6. `--detached`(optional): By default the script will wait for processes and use user input (ctrl +c) to end the processes, however you can pass this option to skip this behavior and just return, for e.g. in case you just want to leave it running.
7. `--withValidatorKeystore | --withValidatorMnemonic` (optional): Launch a validator client using `LODESTAR_VALIDATOR_MNEMONIC_ARGS` (`--withValidatorMnemonic`) or using a folder (`--withValidatorKeystore <abs path to folder`) having `keystores` and `pass.txt` (which advance users may modify in `LODESTAR_VALIDATOR_KEYSTORE_ARGS` as per their setup).
   Users can spin multiple validators using `--withValidatorMnemonic <folder path> --justVC` connecting to same beacon node.
8. `--withMevBoost` (optional): Also launch a `mev-boost` container to interface with multiple relays picked for the corresponding network vars (for e.g. from `mainnet.vars`). When paired with `--justCL` or `--justVC` this only activate the builder args in the beacon/validator and use the builder url set in `MEVBOOST_URL` variable in `fixed.vars`
9. `--justEL | --justCL | --justVC | --justMevBoost` (optional) : Just launch only EL client or lodestar beacon or lodestar validator or `mev-boost` relay  at any given time. Gives you more control over the setup.
10. `--skipImagePull` (optional): Just work with local images, don't try updating them.
11. `LODESTAR_EXTRA_ARGS` for CL (and `LODESTAR_VALIDATOR_ARGS` for VC) in `.vars` file allows to supply additional parameters to enable features such as [Checkpoint Sync](https://chainsafe.github.io/lodestar/usage/beacon-management/#checkpoint-sync) (CL only) and [Client monitoring](https://chainsafe.github.io/lodestar/usage/client-monitoring/).

Only one of `--withTerminal` or `--detached` should be provided.
