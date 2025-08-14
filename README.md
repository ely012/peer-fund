 Peer-Fund Smart Contract

 Overview
The **Peer-Fund Smart Contract** is a Clarity-based decentralized group funding platform that enables individuals to pool STX funds towards a shared goal. It ensures transparent, trustless fund management where contributors can track their contributions, funding progress, and receive refunds if goals are not met.

 Features
- **Group Fund Creation** – Initiate a peer-fund pool with a defined funding goal.
- **STX Contributions** – Allow participants to contribute securely.
- **Transparent Tracking** – View total raised funds and individual contributions.
- **Conditional Disbursement** – Release funds only when the target is met.
- **Refund Mechanism** – Automatically refund contributors if the goal is not achieved within the set timeframe.

 Contract Functions
| Function | Description |
|----------|-------------|
| `create-fund` | Creates a new peer-fund pool with a funding goal and deadline. |
| `contribute` | Allows participants to add STX to a funding pool. |
| `get-contribution` | Returns the contribution amount of a specific user. |
| `withdraw-funds` | Disburses the pooled funds if the target is reached. |
| `request-refund` | Refunds a contributor if the funding goal is not met. |

 Deployment
1. Install [Clarinet](https://docs.hiro.so/clarinet/getting-started).
2. Clone the repository:
   ```bash
   git clone https://github.com/your-username/peer-fund.git
