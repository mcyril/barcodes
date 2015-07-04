#pragma once
#include "common_definitions.h"


void generate_symbol_info(symbol_info_type *info,
	const brief_symbol_info_type &brief_info,
	bool is_initialization_symbol = false);
