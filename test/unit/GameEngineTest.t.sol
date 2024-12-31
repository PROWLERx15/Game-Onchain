// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {GameEngine} from "../../src/GameEngine.sol";
import {DiceGame} from "../../src/DiceGame.sol";
import {DeployGame} from "../../script/DeployGame.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract GameEngineTest is Test {
    HelperConfig public helperConfig;
    GameEngine public engine;
    DiceGame public diceGame;

    function setUp() public {
        DeployGame deployer = new DeployGame();
        (engine, diceGame, helperConfig) = deployer.deployContract();
    }

    // GETTER FUNCIONS TEST
}
