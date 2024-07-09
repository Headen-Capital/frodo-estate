# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# Install dependencies
forge-install:; forge update
blitz-install:; (cd app && yarn)
install: forge-install blitz-install

# Lint code for style hygiene
forge-lint:; npx solhint --config ./.solhint.json  --fix contracts/*/**.sol contracts/*.sol
blitz-lint:; echo "blitz-lint: TODO"
lint: forge-lint blitz-lint

# Clean away build artifacts
forge-clean:; forge clean
blitz-clean:; (cd app && npm run clean)
snapshot-clean:; rm -rf .gas-snapshot
clean: forge-clean blitz-clean snapshot-clean

# Test code
forge-test:; forge test -vvv
blitz-test:; (cd app && npm run test)
test: forge-test blitz-test

# Blitz Miscs
# See: https://blitzjs.com/docs/cli-overview#available-commands
app:; (cd app && npm run build)
dev:; (cd app && npm run dev)
prod:; (cd app && npm run start)

# Forge Miscs
# See: https://github.com/gakonst/foundry/blob/master/cli/README.md#foundry-clis
contracts:; forge build
snapshot:; forge snapshot
report:; forge test --gas-report

# Stop 'make' from mistaking commands for directories
.PHONY: contracts


deploy-sepolia:; forge script contracts/scripts/FrodoDeployer.sol:FrodoDeployer --chain 84532 --rpc-url base_sepolia --broadcast  -vv --gas-estimate-multiplier 150 --sender 0x4C741E7f98B166286157940Bc7bb86EBaEC51D0a
build: forge build