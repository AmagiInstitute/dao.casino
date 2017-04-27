pragma solidity ^0.4.9;
import 'common/Object.sol';

/**
 * @dev Signature based dice contract
 *      based on https://github.com/gluk256/misc/blob/master/rng4ethereum/signidice.md
 *
 * Howto use this contract:
 *   contract MyDice is Signidice {
 *      function MyDice() Signidice(1 ether) {}
 *
 *      function playerReward(uint256 _id, uint256 _lucky) internal returns (bool) {
 *          var random = _lucky % 100;
 *          var game = games[_id];
 *          // Primitive HI/LO game
 *          var win =  ((game.bet == 0) && (random < 45))
 *                  || ((game.bet > 0) && (random > 55));
 *          if (win) if (!game.player.send(game.value * 2)) throw;
 *          return true;
 *      }
 *   }
 */
contract Signidice is Object {
    function Signidice(uint256 _bountyValue) payable {
        bountyValue = _bountyValue;
    }

    /**
     * @dev Dice bounty value
     */
    uint256 public bountyValue;

    /**
     * @dev List of used random numbers 
     */
    mapping(address => mapping(uint96 => bool)) public usedRandom;

    struct Game {
        address player;
        uint256 value;
        uint256 bet;
        bytes32 random;
        bool    closed;
    }

    Game[] public games;

    /**
     * @dev List of game ids by user account
     */
    mapping(address => uint256[]) public gamesOf;

    /**
     * @dev Dice roll by user 
     * @param _bet User bet
     * @param _random Some random number
     * @notice Random number cannot be used twice.
     */
    function rollDice(
        uint256 _bet,
        uint96  _random
    )
        payable
        returns (uint256)
    {
        if (usedRandom[msg.sender][_random]) throw;
        usedRandom[msg.sender][_random] = true;

        var id = games.length;
        var random = bytes32(uint256(msg.sender) << 96 | _random);
        games.push(Game(msg.sender, msg.value, _bet, random, false));
        gamesOf[msg.sender].push(id);
        RollDice(id, random);
        return id;
    }

    /**
     * @dev Roll dice event for oracle 
     * @param id Game identifier
     * @param v Concatenation of player address and random number
     */
    event RollDice(uint256 indexed id, bytes32 indexed v);

    /**
     * @dev Confirm roll by casino oracle
     * @param _id Game identifier 
     */
    function confirm(
        uint256 _id,
        uint8   _v,
        bytes32 _r,
        bytes32 _s
    )
        onlyOwner
    {
        var game = games[_id];
        // Check for game is open
        if (game.closed) throw;
        // Casino falcify check
        if (ecrecover(game.random, _v, _r, _s) == owner) {
            if (!playerReward(_id, uint256(sha3(_v, _r, _s))))
                throw;
        } else if (!game.player.send(bountyValue)) throw;
        // Close the game
        game.closed = true;
    }

    /**
     * @dev Player rewarding scheme
     * @param _id Game identifier
     * @param _lucky Lucky number
     */
    function playerReward(uint256 _id, uint256 _lucky) internal returns (bool);
}
