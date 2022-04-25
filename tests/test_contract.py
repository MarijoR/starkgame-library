"""contract.cairo test file."""
import os

import pytest
from starkware.starknet.testing.starknet import Starknet
from utils import from_uint, to_uint, str_to_felt, felt_to_str, Signer

# The path to the contract source code.
CONTRACT_FILE = os.path.join("contracts", "game_library.cairo")
ACCOUNTFILE = os.path.join("contracts", "openzeppelin/account/Account.cairo")
TOKENFILE = os.path.join("contracts", "openzeppelin/token/erc20/ERC20.cairo")

signer1 = Signer(1234)
signer2 = Signer(5678)

# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.
@pytest.mark.asyncio
async def test_increase_balance():
    """Test increase_balance method."""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )

    # Invoke increase_balance() twice.
    await contract.increase_balance(amount=10).invoke()
    await contract.increase_balance(amount=20).invoke()

    # Check the result of get_balance().
    execution_info = await contract.get_balance().call()
    assert execution_info.result == (30,)

NAME=str_to_felt("TEST")
SYMBOL=str_to_felt("TEST")
DECIMALS=18 
INIT_SUPPLY=to_uint(1000)

@pytest.mark.asyncio 
async def test_deploy_contracts():
    starknet = await Starknet.empty() 

    account1 = await starknet.deploy(
        source=ACCOUNTFILE,
        constructor_calldata=[signer1.public_key]
    )
    account2 = await starknet.deploy(
        contract_def=ACCOUNTFILE,
        constructor_calldata=[signer2.public_key]
    )
    erc20contract = await starknet.deploy(
        source=CONTRACT_FILE,
        constructor_calldata=[]
    )