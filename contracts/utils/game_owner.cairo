# Author Alessandro Cara @ctrlc03 Halborn 

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256

@storage_var
func Ownable_game_owner_mapping(game_id : Uint256) -> (game_owner : felt):
end

# change game_id to Uint256 

func Ownable_only_game_owner{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(game_id : Uint256):
    let (game_owner) = Ownable_game_owner_mapping.read(game_id)
    let (caller) = get_caller_address()
    with_attr error_message("Ownable: caller is not the game owner"):
        assert game_owner = caller
    end
    return ()
end

func Ownable_get_game_owner{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(game_id : Uint256) -> (game_owner: felt):
    let (game_owner) = Ownable_game_owner_mapping.read(game_id)
    return (game_owner=game_owner)
end

func Ownable_game_owner_initializer{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(game_owner: felt, game_id : Uint256):
    Ownable_game_owner_mapping.write(game_id=game_id, value=game_owner)
    return ()
end