#pragma once
#include "common_definitions.h"
#include "generate_bit_stream.h"
#include "choose_aztec_symbol.h"
#include "generate_codeword_stream.h"
#include "generate_single_barcode.h"


template <typename DataIterator>
void generate_barcode(bit_matrix_type *barcode,
	DataIterator data_first, DataIterator data_last,
	unsigned char error_correction_redundancy = 23,
	symbol_format_type symbol_format = anyone_format,
	bool is_initialization_symbol = false)
{
	// Перевод исходных данных в битовый поток
	bit_vector_type bits;
	generate_bit_stream(&bits, data_first, data_last);

	// Подбор подходящего по размерам символа
	symbol_info_type symbol_info;
	choose_aztec_symbol(&symbol_info, bits, error_correction_redundancy,
		symbol_format, is_initialization_symbol);

	// Формирование потока кодовых слов
	codeword_vector_type codewords;
	generate_codeword_stream(&codewords, bits,
		symbol_info.data_message.codeword_size);

	// Генерация штрих-кода
	generate_single_barcode(barcode, symbol_info, codewords);
}
