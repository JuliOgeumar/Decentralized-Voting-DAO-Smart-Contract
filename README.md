# Decentralized Voting/DAO Smart Contract

A Clarity smart contract for decentralized autonomous organization (DAO) governance, enabling token holders to create and vote on proposals in a transparent and democratic manner.

## Overview

This smart contract implements a complete DAO voting system where:
- Token holders can create proposals
- Community members vote using their token balance as voting power
- Proposals are time-bound with automatic execution capabilities
- Delegation of voting power is supported

## Features

### 🗳️ Proposal Management
- **Create Proposals**: Token holders with minimum balance can submit proposals
- **Time-bound Voting**: Configurable voting periods (default: ~10 days)
- **Automatic Execution**: Successful proposals can be executed after voting ends
- **Status Tracking**: Real-time proposal status monitoring

### 🪙 Token-based Voting
- **Weighted Voting**: Vote power proportional to token balance
- **One Vote Per Proposal**: Prevents double voting
- **Balance Verification**: Ensures voters have sufficient tokens

### 👥 Delegation System
- **Vote Delegation**: Token holders can delegate voting power
- **Flexible Representation**: Change delegates at any time

### 🔒 Security Features
- **Owner Controls**: Contract owner can mint tokens (for testing)
- **Access Control**: Proper authorization checks
- **State Validation**: Comprehensive error handling

## Contract Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `min-proposal-tokens` | 1000 | Minimum tokens required to create a proposal |
| `voting-period` | 1440 blocks | Voting duration (~10 days) |

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u300 | `err-owner-only` | Action restricted to contract owner |
| u301 | `err-not-found` | Proposal not found |
| u302 | `err-unauthorized` | Insufficient permissions |
| u303 | `err-invalid-amount` | Invalid token amount |
| u304 | `err-proposal-ended` | Proposal voting period ended |
| u305 | `err-already-voted` | User already voted on proposal |
| u306 | `err-insufficient-tokens` | Insufficient token balance |

## Public Functions

### Token Management

#### `mint-tokens`
```clarity
(mint-tokens (recipient principal) (amount uint))
