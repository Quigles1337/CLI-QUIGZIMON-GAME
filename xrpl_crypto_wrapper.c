/*
 * QUIGZIMON XRPL Crypto Wrapper
 * Minimal C functions for cryptographic operations
 * Called from assembly code for transaction signing
 *
 * Uses libsodium for Ed25519 and SHA-512
 * Much faster than implementing crypto primitives in pure assembly!
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sodium.h>

// Export functions for assembly to call
#ifdef _WIN32
    #define EXPORT __declspec(dllexport)
#else
    #define EXPORT
#endif

/*
 * Initialize libsodium
 * Call this once at program start
 */
EXPORT int crypto_init(void) {
    if (sodium_init() < 0) {
        return -1;
    }
    return 0;
}

/*
 * Generate Ed25519 keypair from seed
 * seed: 32-byte seed
 * public_key: output 32-byte public key
 * private_key: output 64-byte private key (seed + public key)
 */
EXPORT int ed25519_keypair_from_seed(
    const unsigned char *seed,
    unsigned char *public_key,
    unsigned char *private_key
) {
    return crypto_sign_ed25519_seed_keypair(public_key, private_key, seed);
}

/*
 * Sign message with Ed25519
 * message: data to sign
 * message_len: length of message
 * private_key: 64-byte Ed25519 private key
 * signature: output 64-byte signature
 */
EXPORT int ed25519_sign_message(
    const unsigned char *message,
    unsigned long long message_len,
    const unsigned char *private_key,
    unsigned char *signature
) {
    unsigned long long sig_len;

    return crypto_sign_ed25519_detached(
        signature,
        &sig_len,
        message,
        message_len,
        private_key
    );
}

/*
 * Verify Ed25519 signature
 * message: original message
 * message_len: length of message
 * signature: 64-byte signature
 * public_key: 32-byte public key
 * Returns: 0 if valid, -1 if invalid
 */
EXPORT int ed25519_verify_signature(
    const unsigned char *message,
    unsigned long long message_len,
    const unsigned char *signature,
    const unsigned char *public_key
) {
    return crypto_sign_ed25519_verify_detached(
        signature,
        message,
        message_len,
        public_key
    );
}

/*
 * Compute SHA-512 hash
 * message: input data
 * message_len: length of input
 * hash: output 64-byte hash
 */
EXPORT int sha512_hash_data(
    const unsigned char *message,
    unsigned long long message_len,
    unsigned char *hash
) {
    crypto_hash_sha512(hash, message, message_len);
    return 0;
}

/*
 * Compute SHA-512Half (first 32 bytes of SHA-512)
 * Used by XRPL for transaction hashing
 */
EXPORT int sha512_half_hash(
    const unsigned char *message,
    unsigned long long message_len,
    unsigned char *hash
) {
    unsigned char full_hash[64];
    crypto_hash_sha512(full_hash, message, message_len);
    memcpy(hash, full_hash, 32);
    return 0;
}

/*
 * Compute SHA-256 hash
 * message: input data
 * message_len: length of input
 * hash: output 32-byte hash
 */
EXPORT int sha256_hash_data(
    const unsigned char *message,
    unsigned long long message_len,
    unsigned char *hash
) {
    crypto_hash_sha256(hash, message, message_len);
    return 0;
}

/*
 * XRPL-specific: Generate wallet from family seed
 * seed_base58: Base58-encoded family seed (sEdXXX...)
 * public_key: output 33-byte compressed public key
 * private_key: output 32-byte private key
 * address: output classic address (rXXX...)
 */
EXPORT int xrpl_wallet_from_seed(
    const char *seed_base58,
    unsigned char *public_key,
    unsigned char *private_key,
    char *address
) {
    // This would need:
    // 1. Base58 decode seed
    // 2. Extract key material
    // 3. Generate Ed25519 keypair
    // 4. Compute address with RIPEMD-160
    // 5. Base58 encode address

    // For now, placeholder
    // Full implementation needs base58 and RIPEMD-160

    return -1;  // Not yet implemented
}

/*
 * Convert binary data to hexadecimal string
 * data: input binary
 * data_len: length of binary data
 * hex: output hex string (must be 2*data_len + 1 bytes)
 */
EXPORT void binary_to_hex(
    const unsigned char *data,
    size_t data_len,
    char *hex
) {
    const char hex_chars[] = "0123456789ABCDEF";

    for (size_t i = 0; i < data_len; i++) {
        hex[i * 2] = hex_chars[(data[i] >> 4) & 0x0F];
        hex[i * 2 + 1] = hex_chars[data[i] & 0x0F];
    }
    hex[data_len * 2] = '\0';
}

/*
 * Convert hexadecimal string to binary data
 * hex: input hex string
 * data: output binary
 * Returns: number of bytes written, or -1 on error
 */
EXPORT int hex_to_binary(
    const char *hex,
    unsigned char *data
) {
    size_t len = strlen(hex);

    if (len % 2 != 0) {
        return -1;  // Invalid hex string
    }

    for (size_t i = 0; i < len / 2; i++) {
        char h1 = hex[i * 2];
        char h2 = hex[i * 2 + 1];

        unsigned char b1, b2;

        // Convert first nibble
        if (h1 >= '0' && h1 <= '9') b1 = h1 - '0';
        else if (h1 >= 'A' && h1 <= 'F') b1 = h1 - 'A' + 10;
        else if (h1 >= 'a' && h1 <= 'f') b1 = h1 - 'a' + 10;
        else return -1;

        // Convert second nibble
        if (h2 >= '0' && h2 <= '9') b2 = h2 - '0';
        else if (h2 >= 'A' && h2 <= 'F') b2 = h2 - 'A' + 10;
        else if (h2 >= 'a' && h2 <= 'f') b2 = h2 - 'a' + 10;
        else return -1;

        data[i] = (b1 << 4) | b2;
    }

    return len / 2;
}

/*
 * Test function - verify crypto operations work
 */
EXPORT int crypto_test(void) {
    unsigned char seed[32];
    unsigned char public_key[32];
    unsigned char private_key[64];
    unsigned char message[] = "Hello QUIGZIMON!";
    unsigned char signature[64];

    printf("Testing crypto operations...\n");

    // Generate random seed
    randombytes_buf(seed, sizeof(seed));

    // Generate keypair
    if (ed25519_keypair_from_seed(seed, public_key, private_key) != 0) {
        printf("FAIL: Keypair generation\n");
        return -1;
    }
    printf("PASS: Keypair generated\n");

    // Sign message
    if (ed25519_sign_message(message, sizeof(message), private_key, signature) != 0) {
        printf("FAIL: Message signing\n");
        return -1;
    }
    printf("PASS: Message signed\n");

    // Verify signature
    if (ed25519_verify_signature(message, sizeof(message), signature, public_key) != 0) {
        printf("FAIL: Signature verification\n");
        return -1;
    }
    printf("PASS: Signature verified\n");

    // Test SHA-512
    unsigned char hash[64];
    sha512_hash_data(message, sizeof(message), hash);
    printf("PASS: SHA-512 hash computed\n");

    printf("\nAll crypto tests passed!\n");
    return 0;
}

#ifdef CRYPTO_TEST_MAIN
/*
 * Standalone test program
 * Compile: gcc -DCRYPTO_TEST_MAIN xrpl_crypto_wrapper.c -lsodium -o crypto_test
 * Run: ./crypto_test
 */
int main(void) {
    if (crypto_init() != 0) {
        fprintf(stderr, "Failed to initialize libsodium\n");
        return 1;
    }

    return crypto_test();
}
#endif
