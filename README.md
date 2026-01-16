# SimpleDAO - Professional Governance System

A gas-efficient, secure Decentralized Autonomous Organization (DAO) built with **Foundry** and **OpenZeppelin**. This project implements a proposal-vote-execution lifecycle using snapshot-based voting power to prevent common governance exploits.



## 🚀 Features

* **Snapshot Voting**: Utilizes `ERC20Votes` to calculate voting power based on historical balances, making the system immune to **Flash Loan attacks**.
* **Quorum Protection**: Ensures a minimum level of participation (`1,000 GOV`) is reached before a proposal can pass.
* **Custom Errors**: Uses Solidity 0.8.26 custom errors for optimized gas usage and better debugging.
* **Foundry Native**: Optimized for the Foundry development toolchain with clear remappings and submodule management.

## 🛠 Architecture

### 1. GovToken.sol
The governance token (`GOV`) leverages OpenZeppelin's `ERC20Votes` extension. This contract maintains "checkpoints" of user balances every time a transfer occurs, allowing the DAO to query a user's balance at any specific block height in the past.

### 2. SimpleDAO.sol
The core engine that handles:
* **Proposing**: Any user can propose an arbitrary transaction (target address, ETH value, and encoded data).
* **Voting**: Token holders vote 'Yes' or 'No'. Power is determined by the balance they held at the block the proposal was created.
* **Execution**: Once the voting duration expires, if the quorum is met and the majority is achieved, anyone can trigger the execution.

---

## 💻 Getting Started

### Prerequisites
* [Foundry](https://getfoundry.sh/) installed.
* [VS Code](https://code.visualstudio.com/) with the Solidity extension.

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/navneet-saini2/Governance-DAO
   cd SimpleDAO

2. Install dependencies:
   ```bash
    forge install OpenZeppelin/openzeppelin-contracts

3. Build & Test
Compile the contracts to ensure everything is linked correctly:
    ```bash
    forge build

4. Run the test suite:
   ```Bash
   forge test