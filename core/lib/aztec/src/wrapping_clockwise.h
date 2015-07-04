#pragma once
#include "common_definitions.h"
#include "symbol_matrix.h"


void wrapping_clockwise(symbol_matrix *mtx,
    const bit_vector_type &data, unsigned char layer_width,
    unsigned char first_layer_height);
