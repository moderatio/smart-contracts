include .env

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

create-subscription:
	forge script script/Subscription.s.sol:SubscriptionCreate --fork-url ${RPC_URL} 

deploy-moderatio:
	forge script script/Moderatio.s.sol:DeployModeratio --fork-url ${RPC_URL}  --broadcast -vvvv

deploy-with-consumer:
	forge script script/ModeratioWithConsumer.s.sol:DeployModeratioWithConsumer --rpc-url ${RPC_URL} \
	--verify --broadcast -vvvv

deploy-basic-ruler: 
	forge script script/DeployRuler.s.sol:DeployBasicRuler --fork-url ${RPC_URL}  --broadcast -vvvv


verify-with-consumer:
	forge verify-contract \
		--watch \
	--constructor-args "$(cast abi-encode 'constructor(address,bytes32,address)' '0x40193c8518BB267228Fc409a613bDbD8eC5a97b3' ca98366cc7314957b8c012c72f05aeeb '0x326C977E6efc84E512bB9C30f76E30c160eD06FB')" \
		--etherscan-api-key ${MUMBAI_SCAN_KEY} \
		--compiler-version v0.8.13+commit.abaa5c0e \
		--chain 80001 \
		0xe8c77fc8d5173e8eae0a90ee6d8d0dfdeb0c537e \
		src/ModeratioWithConsumer.sol:ModeratioWithConsumer

verify-ruler:
	forge verify-contract \
		--watch \
		--etherscan-api-key ${MUMBAI_SCAN_KEY} \
		--compiler-version v0.8.13+commit.abaa5c0e \
		--chain 80001 \
		0x22b71291022b9fe139ebad84a6309d4966e22601 \
		src/BasicRuler.sol:BasicRuler


flatten-moderatio:
	forge flatten src/ModeratioWithConsumer.sol -o flattened.sol



export-consumer-abi:
	rm -rf abi && mkdir abi && forge inspect src/ModeratioWithConsumer.sol:ModeratioWithConsumer abi > abi/ModeratioWithConsumer.json	

export-abi:
	rm -rf abi && mkdir abi && forge inspect src/Moderatio.sol:Moderatio abi > abi/Moderatio.json
