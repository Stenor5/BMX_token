# Transferable and stakable Token project
# @author Stenor Tanaka


1. You should make the .secret file and write down your account private key in that file.
2. You should make the .bsc_api_key file and write down your Binance smart chain api key in that file.
3. You should make the .env file and write down your account address.
4. Please run "yarn deploy:mainnet" to deploy the contract on mainnet.
5. Please run "yarn deploy:testnet" to deploy the contract on testnet.
6. There will be appeared contractAddress.js file.
   In there you should copy the contract address and replace the contract address of package.json.
   As like "hardhat verify <contract address> ----constructor-args arguments.js --network testnet".
7. And then please run "yarn verify:mainnet" to verify the contract on mainnet.
8. And then please run "yarn verify:testnet" to verify the contract on testnet.