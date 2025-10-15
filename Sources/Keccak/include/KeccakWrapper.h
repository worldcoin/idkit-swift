#ifndef KECCAK_WRAPPER_H
#define KECCAK_WRAPPER_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void keccak256_hash(const uint8_t * _Nullable input, size_t inputByteLen, uint8_t * _Nonnull output);

#ifdef __cplusplus
}
#endif

#endif
