// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

/* imports */
import {VRFConsumerBaseV2Plus} from
    "lib/foundry-chainlink-toolkit/lib/chainlink-brownie-contracts/contracts/src/v0.8/dev/vrf/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from
    "lib/foundry-chainlink-toolkit/lib/chainlink-brownie-contracts/contracts/src/v0.8/dev/vrf/libraries/VRFV2PlusClient.sol";
/**
 * @title Dice Game
 * @author PROWLERx15
 * @notice This contract has the logic of dice roll game. It can be called via the GameEngine Contract
 *         User will bet on one of the following possible outcomes:
 *         -> Exact Dice Number [1,6]   (Probability = 1/6)
 *         -> Number is ODD             (Probability = 1/2)
 *         -> Number is EVEN            (Probability = 1/2)
 * This contract uses the Chainlink VRF V2.5 to generate a Random Number.
 */

contract DiceGame is VRFConsumerBaseV2Plus {
    /* errors */
    error DiceGame__OnlyOwnerIsAllowedToCall();
    error DiceGame__VRFSubscriptionNotSet();

    /* interfaces, libraries, contract */
    /* Type declarations */
    enum DiceGameBetType {
        ExactNumber, // User bets on a specific dice number (1-6)
        Odd, // User bets that the dice roll will be odd
        Even // User bets that the dice roll will be even

    }

    /* State variables */
    uint256 private immutable i_subscriptionId; // Subscription ID for Chainlink VRF service.
    address private immutable i_vrfCoordinator; // Address of the VRF Coordinator contract.
    bytes32 private immutable i_keyHash; // Key hash for VRF randomness requests.
    uint32 private immutable i_callbackGasLimit; // Gas limit for the callback function.
    address private immutable i_owner; // Address of the DiceGame contract owner.
    uint16 private constant REQUEST_CONFIRMATIONS = 3; // Number of confirmations for VRF request.
    uint32 private constant NUM_WORDS = 1; // Number of random words to request (1 in this case).

    mapping(uint256 requestId => address user) private s_DiceRollers; // Maps requestId to roller address
    mapping(address user => mapping(uint256 requestId => uint256 diceResult)) private s_Results; // Maps user to dice result

    /* Events */
    event DiceRolled(uint256 indexed requestId, address indexed roller);
    event DiceLanded(uint256 indexed randomNumber, uint256 indexed result);

    /* Modifiers */
    modifier onlyOwnerCanCall() {
        if (msg.sender != i_owner) {
            revert DiceGame__OnlyOwnerIsAllowedToCall();
        }
        _;
    }

    modifier VRFSubscriptionIsSet(uint256 subscriptionId) {
        if (subscriptionId == 0) {
            revert DiceGame__VRFSubscriptionNotSet(); // Will revert if subscription is not set.
        }
        _;
    }

    /* Functions */

    /* constructor */
    constructor(
        uint256 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        address _owner
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_subscriptionId = _subscriptionId;
        i_vrfCoordinator = _vrfCoordinator;
        i_keyHash = _keyHash;
        i_callbackGasLimit = _callbackGasLimit;
        i_owner = _owner;
    }
    /* receive function (if exists) */
    /* fallback function (if exists) */
    /* external */

    /* public */

    /**
     *
     * @param user The address of the user who has placed the bet
     * @notice This function will be roll the dice and return the VRF requestId.
     *         This requestId will be later used to calculate the dice result.
     *         It will be called by the GameEngine Contract
     */
    function rollDice(address user) public onlyOwnerCanCall returns (uint256 requestId) {
        requestId = _rollDice(user, i_subscriptionId, i_keyHash, i_callbackGasLimit, REQUEST_CONFIRMATIONS, NUM_WORDS);
    }

    /**
     *
     * @param betType The type of bet the user has placed (ExactNumber, Odd, Even)
     * @param betNumber The dice number on which the user has placed the bet (1-6)
     * @param user The address of the user who has placed the bet
     * @param requestId The unique identifier for the bet request
     * @return bool Returns `true` ->  if the bet is correct
     *              Returns `false` -> if the bet is incorrect
     * @notice Validates a user's dice roll bet based on the bet type, bet number, and the dice roll result.
     */
    function validateDiceRoll(DiceGameBetType betType, uint256 betNumber, address user, uint256 requestId)
        public
        view
        onlyOwnerCanCall
        returns (bool)
    {
        uint256 diceResult = s_Results[user][requestId];
        // 1-6 / odd / even
        if ((betType == DiceGameBetType.ExactNumber) && (betNumber == diceResult)) {
            return true; // Checking for Numbers [1-6]
        } else if ((betType == DiceGameBetType.Odd) && ((diceResult % 2) != 0)) {
            return true; // Checking if betType & diceResult  are odd
        } else if ((betType == DiceGameBetType.Even) && ((diceResult % 2) == 0)) {
            return true; // Checking if betType & diceResult  are even
        } else {
            return false;
        }
    }

    /* internal */
    function _rollDice(
        address diceRoller,
        uint256 subscriptionId,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint16 requestConfirmations,
        uint32 numWords
    ) internal VRFSubscriptionIsSet(subscriptionId) returns (uint256 requestId) {
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        s_DiceRollers[requestId] = diceRoller; // Track roller by requestId
        emit DiceRolled(requestId, diceRoller);
        return requestId;
    }

    /**
     *
     * @param requestId The Id initially returned by _rollDice.
     * @param randomWords The random word(number) which is generated by chainlink VRF
     * @notice This function gets the random word(number) and then converts random number into a dice roll result between 1 and 6.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 randomNumber = randomWords[0];
        uint256 diceResult = ((randomNumber % 6) + 1); // Dice value between 1-6

        address diceRoller = s_DiceRollers[requestId]; // Track roller by requestId
        s_Results[diceRoller][requestId] = diceResult;

        emit DiceLanded(randomNumber, diceResult);
    }

    /* private */
    /* internal & private view & pure functions */

    /* external & public view & pure functions */
    function getSubscriptionId() external view returns (uint256) {
        return i_subscriptionId;
    }

    function getVrfCoordinator() external view returns (address) {
        return i_vrfCoordinator;
    }

    function getKeyHash() external view returns (bytes32) {
        return i_keyHash;
    }

    function getCallbackGasLimit() external view returns (uint32) {
        return i_callbackGasLimit;
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

    function getRequestConfirmations() external pure returns (uint16) {
        return REQUEST_CONFIRMATIONS;
    }

    function getNumberOfWords() external pure returns (uint32) {
        return NUM_WORDS;
    }
}

// engine -> playDiceGame { user, betNumber, bet type, amt
// -> rolldice (user)
// -> validate(requestid,user,betNumber,betTYpe)
// -> reward Function
// }

// Add modifier to check if subscription has LINK
