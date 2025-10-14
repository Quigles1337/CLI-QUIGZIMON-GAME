# QUIGZIMON × XRPL - Setup Guide

Complete guide to building and running QUIGZIMON with full blockchain integration!

---

## 🚀 Quick Start (Windows)

### Step 1: Install Prerequisites

**1. NASM Assembler**
```batch
choco install nasm
```
Or download from: https://www.nasm.us/

**2. Visual Studio**
- Install Visual Studio 2019 or 2022
- Select "Desktop development with C++"
- Or install Build Tools for Visual Studio

**3. vcpkg (Package Manager)**
```batch
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat
.\vcpkg integrate install
```

**4. libsodium (Crypto Library)**
```batch
vcpkg install libsodium:x64-windows
```

### Step 2: Build QUIGZIMON

```batch
# Open Visual Studio Developer Command Prompt
# Navigate to project directory
cd C:\Users\LEET\pocket-monsters-asm

# Build with XRPL integration
build_xrpl.bat
```

### Step 3: Run!

```batch
quigzimon_xrpl.exe
```

---

## 🐧 Linux / WSL Setup

### Step 1: Install Dependencies

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install nasm gcc libsodium-dev

# Fedora
sudo dnf install nasm gcc libsodium-devel

# Arch
sudo pacman -S nasm gcc libsodium
```

### Step 2: Build

```bash
chmod +x build_xrpl.sh
./build_xrpl.sh
```

### Step 3: Run

```bash
./quigzimon_xrpl
```

---

## 📦 What's Included

### Core Components

**Assembly Files:**
- `game_enhanced.asm` - Main game engine
- `xrpl_client.asm` - HTTP client for XRPL API
- `xrpl_nft.asm` - NFT minting and trading
- `xrpl_crypto_bridge.asm` - Assembly → C crypto interface
- `xrpl_demo.asm` - Demo mode

**C Wrapper:**
- `xrpl_crypto_wrapper.c` - Crypto operations via libsodium

**Dependencies:**
- libsodium - Ed25519 signing, SHA-512 hashing
- ws2_32.lib (Windows) - Sockets

---

## 🧪 Testing the Build

### Test 1: Crypto Functions

```batch
# Compile standalone crypto test
cl /DCRYPTO_TEST_MAIN xrpl_crypto_wrapper.c -lsodium -o crypto_test.exe
crypto_test.exe
```

Expected output:
```
Testing crypto operations...
PASS: Keypair generated
PASS: Message signed
PASS: Signature verified
PASS: SHA-512 hash computed

All crypto tests passed!
```

### Test 2: XRPL Connection

In game, select XRPL Demo mode and try:
- Check XRP balance (needs testnet address)
- View NFTs
- Generate metadata

### Test 3: NFT Minting (Coming Soon!)

Once you have a testnet wallet:
1. Catch a QUIGZIMON
2. Select "Mint as NFT"
3. Transaction will be signed and submitted
4. Verify on XRPL Explorer

---

## 🔑 Setting Up XRPL Testnet Wallet

### Option 1: Generate New Wallet

```javascript
// Using xrpl.js
const xrpl = require('xrpl');
const client = new xrpl.Client('wss://s.altnet.rippletest.net:51233');
await client.connect();

const wallet = xrpl.Wallet.generate();
console.log('Address:', wallet.address);
console.log('Seed:', wallet.seed);

// Fund from testnet faucet
await client.fundWallet(wallet);
```

### Option 2: Use Testnet Faucet

1. Go to: https://xrpl.org/xrp-testnet-faucet.html
2. Click "Generate Testnet credentials"
3. Save your address and secret
4. Copy address to game config

### Store Wallet Info

Create `wallet.conf`:
```
address=rYourXRPLAddressHere
secret=sYourSecretSeedHere
```

Game will load on startup!

---

## 🛠️ Troubleshooting

### "NASM not found"
- Add NASM to PATH
- Or specify full path in build script

### "libsodium.lib not found"
```batch
# Verify vcpkg installation
vcpkg list | findstr libsodium

# Reinstall if needed
vcpkg remove libsodium:x64-windows
vcpkg install libsodium:x64-windows
```

### "cl.exe not found"
- Run from "Visual Studio Developer Command Prompt"
- Or add VS to PATH:
  ```batch
  "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
  ```

### "Cannot connect to XRPL"
- Check internet connection
- Testnet might be down - try mainnet (carefully!)
- Firewall may be blocking port 51233

### "Signing failed"
- Verify wallet seed is correct format
- Check private key generated properly
- Run crypto_test to verify libsodium

---

## 📊 Build Artifacts

After successful build:

```
quigzimon_xrpl.exe          # Main executable (Windows)
quigzimon_xrpl              # Main executable (Linux)
*.obj / *.o                 # Object files
*.pdb                       # Debug symbols (Windows)
```

Size: ~150KB (assembly) + ~500KB (libsodium)

---

## 🎮 Features Now Available

### ✅ Working
- XRP balance checking
- Account NFT viewing
- NFT metadata generation
- Transaction signing
- HTTP communication with XRPL

### 🚧 In Progress
- Actual NFT minting
- Marketplace trading
- PvP battles
- Escrow system

### 📅 Coming Soon
- Evolution mechanics
- Breeding system
- Tournament system
- Web viewer for NFTs

---

## 🔐 Security Notes

**IMPORTANT:**
- **Testnet only** for now!
- Never share your secret seed
- Use throwaway wallets for testing
- Mainnet support requires audit
- Encrypt wallet files

**Before Mainnet:**
- [ ] Security audit
- [ ] Extensive testing
- [ ] Key encryption at rest
- [ ] Hardware wallet support
- [ ] Multi-sig options

---

## 📖 Developer Notes

### Architecture

```
┌─────────────────────────────────┐
│   Game Engine (Assembly)        │
│   - Battle system               │
│   - Catching mechanics          │
│   - Party management            │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│   XRPL Client (Assembly)        │
│   - HTTP requests               │
│   - JSON parsing                │
│   - NFT operations              │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│   Crypto Bridge (Assembly)      │
│   - Function call conversion    │
│   - Parameter marshaling        │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│   Crypto Wrapper (C)            │
│   - Ed25519 via libsodium       │
│   - SHA-512 hashing             │
│   - Key generation              │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│   libsodium (Native Library)    │
│   - Optimized crypto primitives │
└─────────────────────────────────┘
```

### Calling Convention

**Windows x64:**
- First 4 args: RCX, RDX, R8, R9
- Additional: Stack (right-to-left)
- Caller cleans stack
- 32-byte shadow space required

**Linux x64 (System V):**
- Args: RDI, RSI, RDX, RCX, R8, R9
- Return: RAX
- Callee-saved: RBX, RBP, R12-R15

### Adding New Crypto Functions

1. Add C function to `xrpl_crypto_wrapper.c`
2. Add `extern` declaration in `xrpl_crypto_bridge.asm`
3. Create assembly wrapper with proper calling convention
4. Export from bridge module
5. Test thoroughly!

---

## 🎓 Learning Resources

**Assembly:**
- Intel x64 Manual: https://software.intel.com/content/www/us/en/develop/articles/intel-sdm.html
- NASM Documentation: https://nasm.us/doc/

**XRPL:**
- XRPL Docs: https://xrpl.org/
- Transaction Format: https://xrpl.org/transaction-formats.html
- NFT Tokens: https://xrpl.org/nft-trading.html

**Cryptography:**
- libsodium Docs: https://doc.libsodium.org/
- Ed25519 Spec: https://ed25519.cr.yp.to/
- SHA-512: https://en.wikipedia.org/wiki/SHA-2

---

## 📞 Support

**Issues:**
- GitHub: https://github.com/Quigles1337/CLI-QUIGZIMON-GAME/issues

**Questions:**
- Check XRPL_INTEGRATION.md for architecture
- Read XRPL_STATUS.md for development status

**Contributing:**
- Fork and submit PR
- Follow existing code style
- Test on both Windows and Linux
- Document new features

---

## 🏆 Success Checklist

Before considering setup complete:

- [ ] NASM installed and in PATH
- [ ] Visual Studio or Build Tools installed
- [ ] vcpkg installed
- [ ] libsodium installed via vcpkg
- [ ] Build script runs without errors
- [ ] Crypto test passes
- [ ] Game launches
- [ ] Can connect to XRPL testnet
- [ ] Can check balance (with test address)
- [ ] Can generate NFT metadata

---

**You're ready to build the future of blockchain gaming! 🚀🎮⛓️**
