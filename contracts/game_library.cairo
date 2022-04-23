%lang starknet 

# Imports 
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_lt, uint256_add
from starkware.cairo.common.math import assert_lt 
from starkware.starknet.common.syscalls import (get_contract_address, get_caller_address)

# Ownable stuff
from openzeppelin.access.ownable import (
    Ownable_initializer,
    Ownable_only_owner,
)

from utils.game_owner import (
    Ownable_game_owner_initializer,
    Ownable_get_game_owner,
    Ownable_only_game_owner
)

# Pausable stuff
from openzeppelin.security.pausable import (
    Pausable_paused,
    Pausable_pause,
    Pausable_unpause,
    Pausable_when_not_paused
)

# ERC20 Stuff 
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20 

# The constructor 
@constructor
func constructor{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        owner: felt,
        token_address : felt,
    ):

    # set the owner of the contract
    Ownable_initializer(owner)
    # write the token address to storage 
    token_address_storage.write(token_address)
    return ()
end

# Events 

@event 
func game_created(game : Game):
end 

@event 
func room_created(room : Room):
end 

@event 
func player_joined_room(game_id : Uint256, room_id : Uint256, account : felt):
end 

@event
func game_started(game_id : Uint256, room_id : Uint256):
end 

# STRUCTS 

# Game struct 
struct Game:
  member game_name : felt
  member game_max_players : Uint256
  member game_min_players : Uint256
  member max_number_of_rooms : Uint256
  member state : felt
  member entry_price : Uint256
end

# room struct 
struct Room:
  member prize : Uint256
  member entry_price : Uint256
  member game_name : felt
  member winner_address : felt
  member high_score : Uint256
end

# STORAGE VARIABLES 

## HELPERS 

# storage for the ecosystem token address
@storage_var
func token_address_storage() -> (address : felt):
end 

## GAMES 

# mapping of all available games 
@storage_var
func games_mapping(game_id : Uint256) -> (game : Game):
end

# Counter of the amount of games 
@storage_var
func game_id_counter() -> (game_id : Uint256):
end

## Rooms 

# mapping of all available rooms 
@storage_var 
func rooms_mapping(room_id : Uint256) -> (room : Room):
end 

# maps games to their room 
@storage_var
func game_to_room_ids(game_id : Uint256, index : Uint256) -> (room_id : Uint256):
end

# index of room for each game 
@storage_var
func game_to_room_ids_length(game_id : Uint256) -> (length : Uint256):
end

## Players 

@storage_var 


# EXTERNAL FUNCTIONS 

## GAMES

# Games will be active straight away upon creation
@external
func create_new_game{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(
        game_name : felt,
        game_max_players : Uint256,
        game_min_players : Uint256,
        max_number_of_rooms : Uint256,
        game_owner : felt,
        entry_price : Uint256
    ) -> (success : felt):

    alloc_locals

    # check if owner is calling this
    Ownable_only_owner()

    # Get the current game ID
    let (local current_game_id : Uint256) = game_id_counter.read()
    local one : Uint256 = Uint256(1, 0)

    # create the game object
    local game : Game = Game(
      game_name=game_name,
      game_max_players=game_max_players,
      game_min_players=game_min_players,
      max_number_of_rooms=max_number_of_rooms,
      state=1,
      entry_price=entry_price
    )

    # calculate new counter
    let (local new_counter, _) = uint256_add(current_game_id, one)

    # set the owner of the game
    Ownable_game_owner_initializer(game_owner, new_counter)
  
    # write game to storage
    games_mapping.write(new_counter, value=game)
    # increase game counter
    game_id_counter.write(new_counter)

    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

    # emit the event 
    game_created.emit(game=game)
    return (1)
end

# change the game state
@external
func toggle_game_state{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(
      game_id : Uint256,
      new_state : felt
    ) -> (state : felt):

    alloc_locals

    with_attr error_message("new state is not a valid value - 1 or 0"):
        assert_lt(new_state, 2)
    end 

    # check that the game owner is calling it
    Ownable_only_game_owner(game_id=game_id)

    # get the game
    let (local game : Game) = games_mapping.read(game_id=game_id)

    # overwrite the state
    # create a new game for until until we figure out how to modify the struct 
        # create the game object
    local updated_game : Game = Game(
      game_name=game.game_name,
      game_max_players=game.game_max_players,
      game_min_players=game.game_min_players,
      max_number_of_rooms=game.max_number_of_rooms,
      state=new_state,
      entry_price=game.entry_price
    )

    # write back the game to its original place 
    games_mapping.write(game_id=game_id, value=updated_game)

    return (new_state)

end

# Remove a game 
@external 
func remove_game{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    } (game_id : Uint256):

    alloc_locals

    # authorization checks 
    Ownable_only_game_owner(game_id=game_id)

    # will need to remove from so many places 
    # will need to check if the game has any rooms active first 

    return ()
end 

## ROOMS

# function or game owner only
@external
func create_room_for_game{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    } (
      game_id : Uint256,
      entry_price : Uint256,
      game_name : felt,
    ) -> (room_id : Uint256):

    alloc_locals

    Ownable_get_game_owner(game_id)
    # read the insertion index
    let (local insertion_index) = game_to_room_ids_length.read(game_id)

    # zero to set to non initiliazed
    local zero : Uint256 = Uint256(0, 0)

    # create a room object
    local room : Room = Room(
      prize=zero,
      entry_price=entry_price,
      game_name=game_name,
      winner_address=0,
      high_score=zero
      )

    # get the index free
    let (local room_index : Uint256) = game_to_room_ids.read(game_id=game_id, index=insertion_index)
    # increase index
    local one : Uint256 = Uint256(1, 0)
    let (local room_index_incrased, _) = uint256_add(room_index, one)

    game_to_room_ids.write(game_id=game_id, index=insertion_index, value=room_index_incrased)

    # increase insertion_index
    let (local increased_insertion_index, _) = uint256_add(insertion_index, one)

    game_to_room_ids_length.write(game_id=game_id, value=increased_insertion_index)

    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

    return (room_index_incrased) 
end   

## PLAYERS 

# Allows a user to join a room 
@external
func player_join_room{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    } (
        room_id : Uint256, 
        game_id : Uint256
    ) -> (success : felt):
    alloc_locals 

    # 1. check if room has space 
    # 2. check if room has not started yet 
    # 3. pay fee (get it first)
    # 4. associate player - room 
    let (local room : Room) = rooms_mapping.read(room_id) 

    return (1)
end 

## HELPERS 

# internal function to get the entry fee for a game 
func get_fee_for_game{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    } (game_id : Uint256):

    alloc_locals 

    # get the game from game_id 
    let (local game : Game) = games_mapping.read(game_id=game_id)

    return (game.entry_price)
end 

# internal function to pay fee and verify that it was transferred 
func pay_fee_for_room{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    } (
        amount : Uint256,
        room_id : Uint256,
        game_id : Uint256,
        caller_address : felt     
    ) -> (success : felt):
    alloc_locals 

    # get the ecosystem token 
    let (local token_address_local) = token_address.read()

    # get contract address
    let (local contract_address) = get_contract_address()

    # check if the balance of the caller is greater than the fee 
    let (local caller_balance : Uint256) = IERC20.balanceOf(contract_address=token_address_local, account=caller_address)

    # assert 
    let (local result) = uint256_lt(amount, caller_balance)
    with_attr error_message("Balance is less than the price of the game):
        assert result = 1
    end 

    # transfer the tokens 
    let (local success) = IERC20.transferFrom(
                            contract_address=token_address_local, 
                            sender=caller_address, 
                            recipient=contract_address, 
                            amount=amount
                            )    


    # revoked references
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr
    
    return (return success)
end 

# function for owner to withdraw funds 
@external
func withdraw_funds{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }():

    alloc_locals 

    # check that we are the owners 
    Ownable_only_owner()

    # get the values we need: caller address, our contract address, and the address of the ecosystem token 
    let (local caller_address) = get_caller_address()
    let (local contract_address) = get_contract_address()
    let (local token_address) = token_address_storage.read()

    # get the total quantity of token held in the contract
    let balance : Uint256 = IERC20.balanceOf(contract_address=token_address, account=contract_address)

    # transfer the tokens 
    IERC20.transferFrom(contract_address=token_address, sender=contract_address, recipient=caller_address, amount=balance)

    # TODO add check that funds have been transfered 

    return () 
end 

# internal function to confirm that a transfer was successful
func verify_transfer{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    } (
        from : felt, 
        recipient : felt
    ) -> (result : felt):

    return (1)
end 

# could add a way for game owners to withdraw funds from their games, however this would require to take a percentage off 

# VIEW FUNCTIONS 

## GAMES

# get a game information  
@view 
func get_game_information{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(game_id : Uint256) -> (game : Game):

    let game : Game = games_mapping.read(game_id=game_id)

    return (game)
end 

# returns the number of games registered so far 
@view 
func get_number_of_games{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }() -> (number : felt):

    let number : Uint256 = game_id_counter.read()
    return (number.low)
end 

## ROOMS

@view 
func get_room_information{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    } (room_id : Uint256) -> (room : Room):
    alloc_locals 

    let (local room : Room) = rooms_mapping.read(room_id=room_id)

    return (room)
end 

## PLAYERS 

## HELPERS 

# function to get the balance of the contract (could be useful to a frontend)
@view 
func get_contract_balance{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }() -> (balance : felt):

    alloc_locals 

    # get the stuff we need 
    let (local token_address) = token_address_storage.read()
    let (local contract_address) = get_contract_address()

    # get balance 
    let (local balance : Uint256) = IERC20.balanceOf(contract_address=token_address, account=contract_address)

    # return only low part 
    return (balance.low)
end 