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
	forge script script/Moderatio.s.sol:DeployModeratio --fork-url ${RPC_URL} --broadcast -vvvv

deploy-with-consumer:
	forge script script/ModeratioWithConsumer.s.sol:DeployModeratioWithConsumer --rpc-url ${RPC_URL} --broadcast -vvvv

verify-with-consumer:
	forge verify-contract \
		--chain-id 80001 \
		--watch \
		--etherscan-api-key ${MUMBAI_SCAN_KEY} \
		--compiler-version v0.8.13+commit.abaa5c0e \
		0xd2ea180ce1a77e9ac5cc9cd25f5a4786ed365932 \
		src/ModeratioWithConsumer.sol:ModeratioWithConsumer 




export-abi:
	rm -rf abi && mkdir abi && forge inspect src/Moderatio.sol:Moderatio abi > abi/Moderatio.json
