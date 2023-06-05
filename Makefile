setup-foundry:
	curl -L https://foundry.paradigm.xyz | bash
	foundryup

install:
	forge install
	cd function && npm install

test:
	forge test

simulate-function:
	cd function && npm run simulate

export-abi:
	mkdir abi && forge inspect src/Moderatio.sol:Moderatio abi > abi/Moderatio.json
