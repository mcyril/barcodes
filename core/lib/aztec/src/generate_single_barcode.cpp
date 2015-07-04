#include <cstddef>
#include <cassert>
#include <memory>
#include "generate_data_message.h"
#include "generate_mode_message.h"
#include "generate_bulls_eye.h"
#include "wrapping_clockwise.h"
#include "generate_single_barcode.h"


void generate_single_barcode(bit_matrix_type *barcode,
	const symbol_info_type &symbol_info, const codeword_vector_type &codewords)
{
	assert(barcode != NULL);

	// Формирование основных компонентов штрихового кода
	bit_vector_type data_message;
	generate_data_message(&data_message, symbol_info, codewords);

	bit_vector_type mode_message;
	generate_mode_message(&mode_message, symbol_info,
		static_cast<unsigned short>(codewords.size()));

	bit_vector_type bulls_eye;
	generate_bulls_eye(&bulls_eye, symbol_info);

	// Формирование штрихового кода
	barcode->clear();
	barcode->resize(symbol_info.size, symbol_info.size);

	std::auto_ptr<symbol_matrix> mtx_ptr(symbol_info.is_compact ?
		new compact_symbol_matrix(barcode): new full_symbol_matrix(barcode));

	wrapping_clockwise(mtx_ptr.get(), data_message,
		symbol_info.data_message.layer_width,
		symbol_info.data_message.first_layer_height);

	wrapping_clockwise(mtx_ptr.get(), mode_message,
		symbol_info.mode_message.layer_width,
		symbol_info.mode_message.first_layer_height);

	wrapping_clockwise(mtx_ptr.get(), bulls_eye,
		symbol_info.bulls_eye.layer_width,
		symbol_info.bulls_eye.first_layer_height);
}
