// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {GameEngine} from "../../src/GameEngine.sol";
import {DiceGame} from "../src/DiceGame.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Script} from "forge-std/Script.sol";

contract DeployGame is Script {
    function deployContract() external returns (DiceGame, GameEngine) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vm.startBroadcast();
        DiceGame diceGame =
            new DiceGame(config.subscriptionId, config.vrfCoordinator, config.keyHash, config.callbackGasLimit);
        address diceGameAddress = address(diceGame);
        GameEngine engine = new GameEngine(diceGameAddress);
        vm.stopBroadcast();
        return (diceGame, engine);
    }

    function run() public {}
}
