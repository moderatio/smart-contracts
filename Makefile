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

RPC_URL ?= https://polygon-mumbai.g.alchemy.com/v2/rgs_wZXnvfoCUyMdyxqDPU9f-bhiFqse
create-subscription:
	forge script script/Subscription.s.sol:SubscriptionCreate --fork-url ${RPC_URL} 

deploy-moderatio:
	forge script script/Moderatio.s.sol:DeployModeratio --fork-url ${RPC_URL} --broadcast -vvvv

export-abi:
	rm -rf abi && mkdir abi && forge inspect src/Moderatio.sol:Moderatio abi > abi/Moderatio.json
