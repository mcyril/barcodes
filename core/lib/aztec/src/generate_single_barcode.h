#pragma once
#include "common_definitions.h"


void generate_single_barcode(bit_matrix_type *barcode,
	const symbol_info_type &symbol_info, const codeword_vector_type &codewords);
