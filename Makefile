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
		--constructor-args 00000000000000000000000040193c8518bb267228fc409a613bdbd8ec5a97b3000000000000000000000000326c977e6efc84e512bb9c30f76e30c160ed06fb \
		--etherscan-api-key ${MUMBAI_SCAN_KEY} \
		--compiler-version v0.8.13+commit.abaa5c0e \
		--chain 80001 \
		0x963b39495a6410504bc8c928f3f6f3951f056d6f \
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
