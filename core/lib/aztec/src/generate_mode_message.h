#pragma once
#include "common_definitions.h"


void generate_mode_message(bit_vector_type *mode_message,
	const symbol_info_type &symbol_info, unsigned short codewords_count);
