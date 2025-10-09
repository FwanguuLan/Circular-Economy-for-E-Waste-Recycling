## 🌍 Overview

A blockchain-based platform for tracking electronics lifecycle from production to safe disposal, solving e-waste traceability problems and incentivizing proper recycling.

## ✨ Features

- 📱 **NFT Product Passports**: Unique digital identity for every electronic device
- 🏭 **Verified Recycler Registry**: Certified recyclers with verification system
- 🪙 **Recycling Incentives**: Earn eco-tokens for proper e-waste disposal
- 📊 **Lifecycle Tracking**: Complete traceability from production to recycling
- 🔒 **Secure & Transparent**: Blockchain-based immutable records
- ⭐ **Recycler Rating System**: Community feedback for recyclers

## 🚀 Quick Start

### Prerequisites
- Clarinet CLI installed
- Stacks wallet for testing

### Installation

```bash
git clone https://github.com/your-repo/circular-economy-ewaste
cd circular-economy-ewaste
clarinet check
```

## 📋 Usage

### For Manufacturers

Create product passport for new device:
```clarity
(contract-call? .circular-economy-for-e-waste-recycling create-product-passport 
  "smartphone" 
  "ABC123XYZ789" 
  u1640995200)
```

### For Device Owners

Transfer ownership:
```clarity
(contract-call? .circular-economy-for-e-waste-recycling transfer-product 
  u1 
  'SP2USER...)
```

Update device status:
```clarity
(contract-call? .circular-economy-for-e-waste-recycling update-product-status
  u1
  "end-of-life")
```

Rate recycler after recycling:
```clarity
(contract-call? .circular-economy-for-e-waste-recycling rate-recycler
  u1
  u5)
```

### For Recyclers

Register as recycler:
```clarity
(contract-call? .circular-economy-for-e-waste-recycling register-recycler 
  "GreenTech Recycling" 
  "LICENSE123" 
  u3)
```

Complete recycling process:
```clarity
(contract-call? .circular-economy-for-e-waste-recycling complete-recycling u1)
```

## 🔧 Contract Functions

### Public Functions

| Function | Description |
|----------|-------------|
| `register-recycler` | Register as certified recycler |
| `verify-recycler` | Verify recycler (owner only) |
| `create-product-passport` | Mint NFT passport for device |
| `transfer-product` | Transfer device ownership |
| `update-product-status` | Update device lifecycle status |
| `initiate-recycling` | Start recycling process |
| `complete-recycling` | Finish recycling & earn rewards |
| `rate-recycler` | Rate recycler after recycling |
| `set-recycling-reward` | Update reward amount (owner only) |

### Read-Only Functions

| Function | Description |
|----------|-------------|
| `get-product-info` | Get device details |
| `get-recycler-info` | Get recycler details |
| `get-user-balance` | Check eco-token balance |
| `get-recycler-average-rating` | Get recycler's average rating |
| `is-verified-recycler` | Check recycler verification |

## 💰 Token Economics

- 🎁 **Base Reward**: 100 eco-tokens per recycled device
- 🏆 **Certification Bonus**: 2x rewards for level 3+ certified recyclers
- 💎 **Owner Incentive**: 50% of recycling reward goes to device owner

## 🔄 Device Lifecycle

1. **Produced** - Device manufactured
2. **Transferred** - Ownership changed
3. **End-of-life** - Ready for recycling
4. **Recycling** - In recycling process
5. **Recycled** - Successfully recycled

## 🧪 Testing

```bash
clarinet test
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Submit pull request

## 📄 License

MIT License - see LICENSE file for details
