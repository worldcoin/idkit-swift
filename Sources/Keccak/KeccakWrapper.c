#include "KeccakWrapper.h"

void Keccak(unsigned int rate,
            unsigned int capacity,
            const unsigned char *input,
            unsigned long long int inputByteLen,
            unsigned char delimitedSuffix,
            unsigned char *output,
            unsigned long long int outputByteLen);

void keccak256_hash(const uint8_t * _Nullable input, size_t inputByteLen, uint8_t *output)
{
    static const uint8_t zero = 0;
    const unsigned char *message = (inputByteLen == 0 && input == NULL) ? &zero : input;
    Keccak(1088, 512, message, (unsigned long long int)inputByteLen, 0x01, output, 32);
}
