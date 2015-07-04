#pragma once
#include "common_definitions.h"


void add_reed_solomon_checkwords(
    codeword_vector_type *codewords,
    unsigned char codeword_size,
    codeword_vector_type::size_type crc_size);
