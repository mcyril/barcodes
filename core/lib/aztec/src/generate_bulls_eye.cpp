#include <cstddef>
#include <cassert>
#include "generate_bulls_eye.h"


void generate_bulls_eye(bit_vector_type *bulls_eye,
	const symbol_info_type &symbol_info)
{
	assert(bulls_eye != NULL);
	assert(symbol_info.bulls_eye.layer_width == 1);
	assert(symbol_info.bulls_eye.layers > 0);

	const unsigned char side_of_square =
		symbol_info.bulls_eye.first_layer_height +
		2 * (symbol_info.bulls_eye.layers - 1);

	bulls_eye->resize(0);
	bulls_eye->reserve(side_of_square * side_of_square);

	bulls_eye->insert(bulls_eye->end(),
		symbol_info.bulls_eye.first_layer_height *
			symbol_info.bulls_eye.first_layer_height,
		symbol_info.bulls_eye.first_layer_color);

	for (unsigned char i = 0; i < symbol_info.bulls_eye.layers - 1; ++i)
		bulls_eye->insert(bulls_eye->end(),
			4 * (symbol_info.bulls_eye.first_layer_height + 1) + 8 * i,
			(symbol_info.bulls_eye.first_layer_color + 1 + i) % 2);
}
