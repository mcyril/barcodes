#pragma once
#include "common_definitions.h"


void choose_aztec_symbol(
	symbol_info_type *symbol_info,
	const bit_vector_type &bits,
	unsigned char error_correction_redundancy,
	symbol_format_type symbol_format,
	bool is_initialization_symbol);
