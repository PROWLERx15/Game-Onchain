// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

/* imports */
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {DiceGame} from "./DiceGame.sol";

/**
 * @title Game Engine
 * @author PROWLERx15
 *
 * The
 * @notice This contract is used to interact with the game contracts
 */
contract GameEngine is ReentrancyGuard {
    /* errors */
    error GameEngine__AmountShouldBeGreaterTHanZero();
    error GameEngine__TransferFailed();
    error GameEngine__OnlyOwnerIsAllowedToCall();

    /* interfaces, libraries, contract */

    /* Type declarations */
    enum DiceGameBetType {
        ExactNumber, // User bets on a specific dice number (1-6)
        Odd, // User bets that the dice roll will be odd
        Even // User bets that the dice roll will be even

    }
    /* State variables */

    DiceGame private immutable i_DiceGame;

    mapping(address user => uint256 amount) private s_userBalances;

    // uint256 private constant ODD_NUMBER = 1; // when user chooses bet odd ->  bet number for dice roll
    // uint256 private constant EVEN_NUMBER = 2; // when user chooses bet even ->  bet number for dice roll

    address payable private treasury;

    /* Events */
    event FundDeposited(address indexed user, uint256 indexed amount, uint256 indexed balance);
    event FundWithdrawn(address indexed user, uint256 indexed amount, uint256 indexed balance);
    event RewardDeposited(address indexed owner, uint256 indexed amountReward, uint256 indexed contractBalance);

    /* Modifiers */
    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) {
            revert GameEngine__AmountShouldBeGreaterTHanZero();
        }
        _;
    }

    modifier onlyOwnerCanCall(address sender) {
        if (address(this) != sender) {
            revert GameEngine__OnlyOwnerIsAllowedToCall();
        }
        _;
    }
    /* Functions */

    // All functions follow CEI - Checks, Effects & Interactions

    /* constructor */

    constructor(address addressDiceGame) {
        i_DiceGame = DiceGame(addressDiceGame);
    }
    /* receive function (if exists) */
    /* fallback function (if exists) */
    /* external */

    /* public */
    /**
     * @notice This function will deposit funds from the user. The funds will be used to play the game.
     * @param amount The amount to be deposited.
     */
    function depositFund(uint256 amount) public moreThanZero(amount) nonReentrant {
        s_userBalances[msg.sender] += amount;
        emit FundDeposited(msg.sender, amount, s_userBalances[msg.sender]);
        (bool success,) = address(this).call{value: amount}("");
        if (!success) {
            revert GameEngine__TransferFailed();
        }
    }

    /**
     * @notice This function allows users to withdraw their funds.
     */
    function withdrawFund() public moreThanZero(s_userBalances[msg.sender]) nonReentrant {
        uint256 amount = s_userBalances[msg.sender];
        s_userBalances[msg.sender] = 0;
        emit FundWithdrawn(msg.sender, amount, s_userBalances[msg.sender]);
        (bool success,) = msg.sender.call{value: amount}(""); // Transfer funds to the user
        if (!success) {
            revert GameEngine__TransferFailed();
        }
    }

    /**
     * @notice This function allows the owner of the contract to deposit reward. This reward would be given to the users if they win the game.
     * @param rewardAmount The amount of reward to be deposited.
     */
    function depositReward(uint256 rewardAmount)
        public
        moreThanZero(rewardAmount)
        onlyOwnerCanCall(msg.sender)
        nonReentrant
    {
        emit RewardDeposited(msg.sender, rewardAmount, address(this).balance);
        (bool success,) = address(this).call{value: rewardAmount}("");
        if (!success) {
            revert GameEngine__TransferFailed();
        }
    }

    function withdrawEarning() public moreThanZero(treasury.balance) onlyOwnerCanCall(msg.sender) nonReentrant {} // withdraw the money earned by the house

    function placeBet(uint256 bettingAmount, uint256 bet) public moreThanZero(bettingAmount) {} // place a bet
    function resolveBet() public {}

    function playDiceGame(DiceGameBetType betType, uint256 betNumber) public {
        uint256 requestId = i_DiceGame.rollDice(msg.sender);
        // i_DiceGame.validateDiceRoll(betType, betNumber, msg.sender, requestId);
    }

    /* internal */
    /* private */
    /* internal & private view & pure functions */

    /* external & public view & pure functions */
    function getUserBalance(address user) external view returns (uint256) {
        return s_userBalances[user];
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTreasuryBalance() external view returns (uint256) {
        return treasury.balance;
    }
}

/*//////////////////////////////////////////////////////////////
                           TESTING 123
//////////////////////////////////////////////////////////////*/

// possible bets - 1,2,3,4,5,6 /odd number/even number  -> uin8
// bet -> rewards
// 0.01
