// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 subscriptionId;
        address vrfCoordinator;
        bytes32 keyHash;
        uint32 callbackGasLimit;
    }

    /* VRF Mock Values */
    uint96 public constant MOCK_BASE_FEE = 0.25 ether; // Mock base fee required for VRF requests
    uint96 public constant MOCK_GAS_PRICE = 1e9; // Mock gas price in wei
    int56 public constant MOCK_WEI_PER_UNIT_LINK = 1e16; // Mock exchange rate for 1 LINK = 0.01 ETH -> 1e16 wei

    /* Chain Id's */
    uint256 public constant LOCAL_ANVIL_CHAIN_ID = 31337;

    uint256 public constant SEPOLIA_TESTNET_ID = 11155111;
    uint256 public constant AVALANCHE_FUJI_TESTNET_ID = 43113;
    uint256 public constant ARBITRUM_SEPOLIA_TESTNET_ID = 421613;
    uint256 public constant BASE_SEPOLIA_TESTNET_ID = 84531;
    uint256 public constant OPTIMISM_SEPOLIA_TESTNET_ID = 420;

    uint256 public constant ETH_MAINNET_ID = 1;
    uint256 public constant AVALANCHE_MAINNET_ID = 43114;
    uint256 public constant ARBITRUM_MAINNET_ID = 42161;
    uint256 public constant BASE_MAINNET_ID = 8453;
    uint256 public constant OPTIMISM_MAINNET_ID = 10;

    NetworkConfig localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public s_NetworkConfigs;

    constructor() {
        s_NetworkConfigs[SEPOLIA_TESTNET_ID] = getSepoliaEthConfig();
        s_NetworkConfigs[AVALANCHE_FUJI_TESTNET_ID] = getAvalancheFujiTestnetConfig();
        s_NetworkConfigs[ARBITRUM_SEPOLIA_TESTNET_ID] = getArbitrumSepoliaTestnet();
        s_NetworkConfigs[BASE_SEPOLIA_TESTNET_ID] = getBaseSepoliaTestnet();
        s_NetworkConfigs[OPTIMISM_SEPOLIA_TESTNET_ID] = getOptimismSepoliaTestnet();

        s_NetworkConfigs[ETH_MAINNET_ID] = getMainnetEthConfig();
        s_NetworkConfigs[AVALANCHE_MAINNET_ID] = getMainnetAvalancheConfig();
        s_NetworkConfigs[ARBITRUM_MAINNET_ID] = getMainnetArbitrumConfig();
        s_NetworkConfigs[BASE_MAINNET_ID] = getMainnetBaseConfig();
        s_NetworkConfigs[OPTIMISM_MAINNET_ID] = getMainnetOptimismConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (s_NetworkConfigs[chainId].vrfCoordinator != address(0)) {
            return (s_NetworkConfigs[chainId]);
        } else if (chainId == LOCAL_ANVIL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    /* Local Network Config */
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock mockVRFCoordinator =
            new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE, MOCK_WEI_PER_UNIT_LINK);
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            subscriptionId: 0,
            vrfCoordinator: address(mockVRFCoordinator),
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000 // 500,000 gas
        });

        return localNetworkConfig;
    }

    /* Testnet Network Config */

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            subscriptionId: 0,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // 500 gwei Key Hash
            callbackGasLimit: 500000 // 500,000 gas
        });

        return sepoliaNetworkConfig;
    }

    function getAvalancheFujiTestnetConfig()
        public
        pure
        returns (NetworkConfig memory avalancheFujiTestnetNetworkConfig)
    {
        avalancheFujiTestnetNetworkConfig = NetworkConfig({
            subscriptionId: 0,
            vrfCoordinator: 0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE,
            keyHash: 0xc799bd1e3bd4d1a41cd4968997a4e03dfd2a3c7c04b695881138580163f42887, // 300 gwei Key Hash
            callbackGasLimit: 500000 // 500,000 gas
        });

        return avalancheFujiTestnetNetworkConfig;
    }

    function getArbitrumSepoliaTestnet()
        public
        pure
        returns (NetworkConfig memory arbitrumSepoliaTestnetNetworkConfig)
    {
        arbitrumSepoliaTestnetNetworkConfig = NetworkConfig({
            subscriptionId: 0,
            vrfCoordinator: 0x5CE8D5A2BC84beb22a398CCA51996F7930313D61,
            keyHash: 0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be, // 50 gwei Key Hash
            callbackGasLimit: 500000 // 500,000 gas
        });

        return arbitrumSepoliaTestnetNetworkConfig;
    }

    function getBaseSepoliaTestnet() public pure returns (NetworkConfig memory baseSepoliaTestnetNetworkConfig) {
        baseSepoliaTestnetNetworkConfig = NetworkConfig({
            subscriptionId: 0,
            vrfCoordinator: 0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE,
            keyHash: 0x9e1344a1247c8a1785d0a4681a27152bffdb43666ae5bf7d14d24a5efd44bf71, // 30 gwei Key Hash
            callbackGasLimit: 500000 // 500,000 gas
        });

        return baseSepoliaTestnetNetworkConfig;
    }

    function getOptimismSepoliaTestnet()
        public
        pure
        returns (NetworkConfig memory optimismSepoliaTestnetNetworkConfig)
    {
        optimismSepoliaTestnetNetworkConfig = NetworkConfig({
            subscriptionId: 0,
            vrfCoordinator: 0x02667f44a6a44E4BDddCF80e724512Ad3426B17d,
            keyHash: 0xc3d5bc4d5600fa71f7a50b9ad841f14f24f9ca4236fd00bdb5fda56b052b28a4,
            callbackGasLimit: 500000 // 500,000 gas
        });

        return optimismSepoliaTestnetNetworkConfig;
    }

    /* Mainnet Network Config */

    function getMainnetEthConfig() public pure returns (NetworkConfig memory mainnetEthNetworkConfig) {
        mainnetEthNetworkConfig = NetworkConfig({
            subscriptionId: 0,
            vrfCoordinator: 0xD7f86b4b8Cae7D942340FF628F82735b7a20893a,
            keyHash: 0x3fd2fec10d06ee8f65e7f2e95f5c56511359ece3f33960ad8a866ae24a8ff10b, // 500 gwei Key Hash
            callbackGasLimit: 500000 // 500,000 gas
        });

        return mainnetEthNetworkConfig;
    }

    function getMainnetAvalancheConfig() public pure returns (NetworkConfig memory mainnetAvalancheNetworkConfig) {
        mainnetAvalancheNetworkConfig = NetworkConfig({
            subscriptionId: 0,
            vrfCoordinator: 0xE40895D055bccd2053dD0638C9695E326152b1A4,
            keyHash: 0x84213dcadf1f89e4097eb654e3f284d7d5d5bda2bd4748d8b7fada5b3a6eaa0d, // 500 gwei Key Hash
            callbackGasLimit: 500000 // 500,000 gas
        });

        return mainnetAvalancheNetworkConfig;
    }

    function getMainnetArbitrumConfig() public pure returns (NetworkConfig memory mainnetArbitrumNetworkConfig) {
        mainnetArbitrumNetworkConfig = NetworkConfig({
            subscriptionId: 0,
            vrfCoordinator: 0x3C0Ca683b403E37668AE3DC4FB62F4B29B6f7a3e,
            keyHash: 0xe9f223d7d83ec85c4f78042a4845af3a1c8df7757b4997b815ce4b8d07aca68c, // 150 gwei Key Hash
            callbackGasLimit: 500000 // 500,000 gas
        });

        return mainnetArbitrumNetworkConfig;
    }

    function getMainnetBaseConfig() public pure returns (NetworkConfig memory mainnetBaseNetworkConfig) {
        mainnetBaseNetworkConfig = NetworkConfig({
            subscriptionId: 0,
            vrfCoordinator: 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634,
            keyHash: 0xdc2f87677b01473c763cb0aee938ed3341512f6057324a584e5944e786144d70, // 30 gwei Key Hash
            callbackGasLimit: 500000 // 500,000 gas
        });

        return mainnetBaseNetworkConfig;
    }

    function getMainnetOptimismConfig() public pure returns (NetworkConfig memory mainnetOptimismNetworkConfig) {
        mainnetOptimismNetworkConfig = NetworkConfig({
            subscriptionId: 0,
            vrfCoordinator: 0x5FE58960F730153eb5A84a47C51BD4E58302E1c8,
            keyHash: 0x8e7a847ba0757d1c302a3f0fde7b868ef8cf4acc32e48505f1a1d53693a10a19, // 30 gwei Key Hash
            callbackGasLimit: 500000 // 500,000 gas
        });

        return mainnetOptimismNetworkConfig;
    }
}
