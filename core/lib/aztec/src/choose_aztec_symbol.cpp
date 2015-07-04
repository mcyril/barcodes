#include <cstddef>
#include <cassert>
#include <cmath>
#include "generator_exception.h"
#include "generate_symbol_info.h"
#include "generate_codeword_stream.h"
#include "choose_aztec_symbol.h"


namespace
{
	const brief_symbol_info_type symbols[] =
	{
		{ 1,  true,  15,   17,  6},
		{ 1, false,  19,   21,  6},
		{ 2,  true,  19,   40,  6},
		{ 2, false,  23,   48,  6},
		{ 3,  true,  23,   51,  8},
		{ 3, false,  27,   60,  8},
		{ 4,  true,  27,   76,  8},
		{ 4, false,  31,   88,  8},
		{ 5, false,  37,  120,  8},
		{ 6, false,  41,  156,  8},
		{ 7, false,  45,  196,  8},
		{ 8, false,  49,  240,  8},
		{ 9, false,  53,  230, 10},
		{10, false,  57,  272, 10},
		{11, false,  61,  316, 10},
		{12, false,  67,  364, 10},
		{13, false,  71,  416, 10},
		{14, false,  75,  470, 10},
		{15, false,  79,  528, 10},
		{16, false,  83,  588, 10},
		{17, false,  87,  652, 10},
		{18, false,  91,  720, 10},
		{19, false,  95,  790, 10},
		{20, false, 101,  864, 10},
		{21, false, 105,  940, 10},
		{22, false, 109, 1020, 10},
		{23, false, 113,  920, 12},
		{24, false, 117,  992, 12},
		{25, false, 121, 1066, 12},
		{26, false, 125, 1144, 12},
		{27, false, 131, 1224, 12},
		{28, false, 135, 1306, 12},
		{29, false, 139, 1392, 12},
		{30, false, 143, 1480, 12},
		{31, false, 147, 1570, 12},
		{32, false, 151, 1664, 12}
	};
}

void choose_aztec_symbol(symbol_info_type *symbol_info,
	const bit_vector_type &bits, unsigned char error_correction_redundancy,
	symbol_format_type symbol_format, bool is_initialization_symbol)
{
	assert(symbol_info != NULL);
	assert(error_correction_redundancy < 100);

	if (bits.empty())
		throw generator_exception(generator_exception::no_input_data_error);

	unsigned char codeword_size = 0;
	codeword_vector_type::size_type data_codeword_count;
	codeword_vector_type::size_type data_with_crc_codeword_count;

	for (size_t i = 0; i < sizeof(symbols) / sizeof(symbols[0]); ++i)
	{
		if (symbol_format >= compact_format_15x15 &&
				i != symbol_format - compact_format_15x15)
			continue;

		if (symbol_format == compact_format &&
				!symbols[i].is_compact)
			continue;

		if (symbol_format == full_format &&
				symbols[i].is_compact)
			continue;

		if (symbols[i].codeword_size != codeword_size)
		{
			codeword_size = symbols[i].codeword_size;

			codeword_vector_type codewords;
			generate_codeword_stream(&codewords, bits, codeword_size);

			data_codeword_count = codewords.size();
			data_with_crc_codeword_count = codeword_vector_type::size_type(
				ceil((data_codeword_count + 3) * 100 /
				float(100 - error_correction_redundancy)));
		}

		if (symbols[i].codeword_count < data_with_crc_codeword_count)
			continue;

		generate_symbol_info(symbol_info, symbols[i],
			is_initialization_symbol);

		if (symbol_info->is_initialization)
		{
			codeword_vector_type::size_type message_length =
				data_codeword_count - 1;

			const codeword_vector_type::size_type initialization_symbol_mask =
				codeword_vector_type::size_type(1) <<
				(symbol_info->mode_message.bits_on_message_length - 1);
			if ((message_length & initialization_symbol_mask) != 0)
				continue;

			message_length |= initialization_symbol_mask;
			if (message_length + 1 <= symbol_info->data_message.codeword_count)
				continue;
		}

		return;
	}

	throw generator_exception(generator_exception::too_much_input_data_error);
}
