# 💰 Smart Payroll Streaming

> Stream salaries by the block. Pay employees continuously, not monthly. 🚀

## 🌟 Overview

Smart Payroll Streaming is a revolutionary Clarity smart contract that enables **continuous salary payments** on the Stacks blockchain. Instead of traditional monthly payrolls, employers can stream payments by the block, giving employees instant access to their earned wages at any time.

## ✨ Features

- ⏱️ **Real-time Earnings**: Employees earn STX every block
- 💸 **Instant Withdrawals**: Withdraw earned salary anytime, no waiting
- 🔒 **Trustless Payments**: Smart contract holds funds securely
- 📊 **Multiple Streams**: Manage multiple payroll streams per employer/employee
- ⚡ **Block-based Calculations**: Precise earnings based on Stacks block height
- 🛡️ **Employer Controls**: Cancel streams and recover unearned funds

## 🏗️ Architecture

The contract manages payroll streams with the following key components:

- **Stream Creation**: Employers deposit full salary and set duration
- **Rate Calculation**: Automatic per-block payment rate
- **Earned Tracking**: Real-time calculation of available earnings
- **Withdrawal System**: Employees can withdraw anytime
- **Stream Management**: Employers can cancel active streams

## 📋 Contract Functions

### Public Functions

#### `create-stream`
```clarity
(create-stream (employee principal) (total-amount uint) (duration-blocks uint))
```
Creates a new payroll stream for an employee.
- **employer**: Automatically set to tx-sender
- **employee**: Recipient principal
- **total-amount**: Total STX to be streamed
- **duration-blocks**: Number of blocks for the stream
- **Returns**: Stream ID

#### `withdraw`
```clarity
(withdraw (stream-id uint))
```
Allows employees to withdraw their earned amount.
- **stream-id**: The ID of the payroll stream
- **Returns**: Amount withdrawn

#### `cancel-stream`
```clarity
(cancel-stream (stream-id uint))
```
Employers can cancel active streams. Pays earned amount to employee and returns remainder.
- **stream-id**: The ID of the stream to cancel
- **Returns**: Success boolean

### Read-Only Functions

#### `get-stream`
```clarity
(get-stream (stream-id uint))
```
Retrieves stream details by ID.

#### `calculate-earned`
```clarity
(calculate-earned (stream-id uint))
```
Calculates currently earned amount for a stream.

#### `get-stream-details`
```clarity
(get-stream-details (stream-id uint))
```
Returns comprehensive stream information including available balance.

#### `get-employee-streams`
```clarity
(get-employee-streams (employee principal))
```
Lists all stream IDs for an employee.

#### `get-employer-streams`
```clarity
(get-employer-streams (employer principal))
```
Lists all stream IDs created by an employer.

#### `get-contract-balance`
```clarity
(get-contract-balance)
```
Returns total STX held by the contract.

#### `get-total-streams`
```clarity
(get-total-streams)
```
Returns the total number of streams created.

## 🚀 Usage Examples

### Creating a Payroll Stream

```clarity
;; Employer creates a 1000 STX stream over 1440 blocks (~10 days)
(contract-call? .Smart-Payroll-Streaming create-stream 
  'ST1EMPLOYEE123... 
  u1000000000 
  u1440)
```

### Employee Withdrawing Earnings

```clarity
;; Employee withdraws earned salary from stream #0
(contract-call? .Smart-Payroll-Streaming withdraw u0)
```

### Checking Earned Amount

```clarity
;; Check how much has been earned from stream #0
(contract-call? .Smart-Payroll-Streaming calculate-earned u0)
```

### Canceling a Stream

```clarity
;; Employer cancels stream #0
(contract-call? .Smart-Payroll-Streaming cancel-stream u0)
```

## 🎯 Use Cases

- 💼 **Freelance Payments**: Stream payments for ongoing project work
- 👨‍💻 **Employee Salaries**: Modern continuous payroll system
- 🤝 **Contractor Payments**: Fair compensation based on time worked
- 📈 **Vesting Schedules**: Token or payment vesting over time
- 🎓 **Stipends & Grants**: Educational or research funding distribution

## 🔧 Development

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Testing

```bash
clarinet check
clarinet test
```

### Deployment

```bash
clarinet integrate
```

## 📊 Technical Details

- **Payment Rate**: Calculated as `total-amount / duration-blocks`
- **Earnings**: Calculated as `(current-block - start-block) * rate-per-block`
- **Available**: Total earned minus already withdrawn amount
- **Block Time**: Stacks blocks (~10 minutes average)

## 🔐 Security Considerations

- ✅ Funds locked in contract until earned
- ✅ Only employees can withdraw from their streams
- ✅ Only employers can cancel their own streams
- ✅ Withdrawn amounts tracked to prevent double-spending
- ✅ Stream active status prevents manipulation after cancellation

## 🛣️ Roadmap

- [ ] Multi-token support (SIP-010 tokens)
- [ ] Pausable streams
- [ ] Recurring stream templates
- [ ] Stream modifications (rate adjustments)
- [ ] Batch operations for multiple employees

## 📄 License

MIT

## 🤝 Contributing

Contributions welcome! Feel free to open issues or submit PRs.

---

**Built with ❤️ on Stacks Blockchain**
