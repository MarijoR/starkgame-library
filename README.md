# stark-game-core

Core for a StarkNet game library.

The purpose of this library is to allow game developers to quickly build P2E game ecosystems. The contracts allow the following:

1. Create game objects
    * These will have different properties such as entry price, number of players, length etc.
    * The creator of a game can manage its characterirsts at a later point in time should anything change 
2. Create rooms
    * players will be alloed to join a room until the minimum number of players or max is reached
    * rooms will start and depending on the game, players will play against or each on their own instance 
    * room will end as the game ended or all players had their try 
    * rewards will be calculated 

Players will only need a wallet and rewards will be distributed with the token chosen by the smart contract deployer. Each room will have an entry price defined by the game creator. 

WIP
