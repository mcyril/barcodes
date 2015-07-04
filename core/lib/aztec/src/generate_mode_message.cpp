#include <cstddef>
#include <cassert>
#include "base/bin_dec_conversion.h"
#include "add_reed_solomon_checkwords.h"
#include "generate_mode_message.h"


void generate_mode_message(bit_vector_type *mode_message,
	const symbol_info_type &symbol_info, unsigned short codewords_count)
{
	assert(mode_message != NULL);
	assert(codewords_count > 0);

	// Получение кодируемых в Mode Message значений
	const unsigned char symbol_size = symbol_info.data_message.layers - 1;
	unsigned short message_length = codewords_count - 1;

	if (symbol_info.is_initialization)
	{
		const unsigned short initialization_symbol_mask =
			static_cast<unsigned short>(1) <<
				(symbol_info.mode_message.bits_on_message_length - 1);
		assert((message_length & initialization_symbol_mask) == 0);

		message_length |= initialization_symbol_mask;
		assert(message_length + 1 > symbol_info.data_message.codeword_count);
	}

	// Формирование битового потока из кодируемых значений
	bit_vector_type data_bits(
		symbol_info.mode_message.bits_on_symbol_size +
		symbol_info.mode_message.bits_on_message_length);

	assert(symbol_size < static_cast<unsigned short>(1) <<
		symbol_info.mode_message.bits_on_symbol_size);
	dec2bin(data_bits.begin(), data_bits.begin() +
		symbol_info.mode_message.bits_on_symbol_size, symbol_size);

	assert(message_length < static_cast<unsigned short>(1) <<
		symbol_info.mode_message.bits_on_message_length);
	dec2bin(data_bits.begin() + symbol_info.mode_message.bits_on_symbol_size,
		data_bits.end(), message_length);

	// Формирование потока кодовых слов дополненного кодами коррекции ошибок
	codeword_vector_type data_with_crc;
	data_with_crc.reserve(symbol_info.mode_message.codeword_count);

	assert(data_bits.size() % symbol_info.mode_message.codeword_size == 0);
	data_with_crc.resize(data_bits.size() / symbol_info.mode_message.codeword_size);
	bin2dec(data_with_crc.begin(), data_with_crc.end(),
		data_bits.begin(), data_bits.end());

	add_reed_solomon_checkwords(&data_with_crc,
		symbol_info.mode_message.codeword_size,
		symbol_info.mode_message.codeword_count - data_with_crc.size());

	// Формирование Mode Message дополненного метками ориентации
	enum {pattern_count = 4};
	enum {pattern_size = 3};
	const bit_type orientation_patterns[pattern_count][pattern_size] =
	{
		{1, 1, 1},
		{0, 1, 1},
		{1, 0, 0},
		{0, 0, 0}
	};

	mode_message->resize(0);
	mode_message->reserve(
		data_with_crc.size() * symbol_info.mode_message.codeword_size +
		pattern_count * pattern_size);

	mode_message->resize(data_with_crc.size() *
		symbol_info.mode_message.codeword_size);
	dec2bin(mode_message->begin(), mode_message->end(),
		data_with_crc.begin(), data_with_crc.end());

	assert(mode_message->size() % 4 == 0);
	const bit_vector_type::size_type side_width = mode_message->size() / 4;

	mode_message->insert(mode_message->begin() + 4 * side_width,
		&orientation_patterns[0][1], &orientation_patterns[0][pattern_size]);
	mode_message->insert(mode_message->begin() + 3 * side_width,
		&orientation_patterns[3][0], &orientation_patterns[3][pattern_size]);
	mode_message->insert(mode_message->begin() + 2 * side_width,
		&orientation_patterns[2][0], &orientation_patterns[2][pattern_size]);
	mode_message->insert(mode_message->begin() + 1 * side_width,
		&orientation_patterns[1][0], &orientation_patterns[1][pattern_size]);
	mode_message->insert(mode_message->begin() + 0 * side_width,
		&orientation_patterns[0][0], &orientation_patterns[0][1]);
}
