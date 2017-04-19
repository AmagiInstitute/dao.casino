pragma solidity ^0.4.9;
import 'common/Object.sol';
import 'token/Recipient.sol';

/**
 * @title Random number generator contract
 */
contract Random is Object, Recipient {
    struct Seed {
        bytes32 seed;
        uint256 entropy;
        uint256 blockNum;
    }
    
    /**
     * @dev Random seed data
     */
    Seed[] public randomSeed;
    
    /**
     * @dev Get length of random seed data
     */
    function randomSeedLength() constant returns (uint256)
    { return randomSeed.length; }
    
    /**
     * @dev Minimal count of seed data parts
     */
    uint256 public minEntropy;
    
    /**
     * @dev Set minimal count of seed data
     * @param _entropy Count of seed data parts
     */
    function setMinEntropy(uint256 _entropy) onlyOwner
    { minEntropy = _entropy; }
    
    /**
     * @dev Put new seed data part
     * @param _hash Random hash
     */
    function put(bytes32 _hash) {
        if (randomSeed.length == 0)
            randomSeed.push(Seed("", 0, 0));

        var latest = randomSeed[randomSeed.length - 1];

        if (latest.entropy < minEntropy) {
            latest.seed = sha3(latest.seed, _hash);
            latest.entropy += 1;
            latest.blockNum = block.number;
        } else {
            randomSeed.push(Seed(_hash, 1, block.number));
        }

        // Refund transaction gas cost
        if (!msg.sender.send(msg.gas * tx.gasprice)) throw;
    }
    
    /**
     * @dev Get random number
     * @param _id Seed ident
     * @param _range Random number range value
     */
    function get(uint256 _id, uint256 _range) constant returns (uint256) {
        var seed = randomSeed[_id];
        
        if (seed.entropy < minEntropy) throw;

        return uint256(seed.seed) % _range;
    }
}
