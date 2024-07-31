// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SyndicateFund.sol";

contract DeployInvestmentNFT is Script {
    function run() external {
        // Загрузка переменных окружения
        address investmentWallet = vm.envAddress("INVESTMENT_WALLET");
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");

        // Начало транзакции
        vm.startBroadcast();

        // Развертывание контракта
        new SyndicateFund(0x9C2682440BcC8A5E0C0bdF21FE11690Bf1553D98, investmentWallet, tokenAddress);

        // Завершение транзакции
        vm.stopBroadcast();
    }
}
