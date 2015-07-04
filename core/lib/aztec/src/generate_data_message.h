#pragma once
#include "common_definitions.h"


void generate_data_message(bit_vector_type *data_message,
	const symbol_info_type &symbol_info,
	const codeword_vector_type &codewords);
