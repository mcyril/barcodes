#pragma once
#include <cstddef>
#include <cassert>
#include <vector>
#include <iterator>
#include "common_definitions.h"
#include "base/bin_dec_conversion.h"


template <typename DataIterator>
void generate_bit_stream(bit_vector_type *bits,
	DataIterator data_first, DataIterator data_last, bool sa_enabled = false)
{
	enum {bits_on_value = 5};

	assert(bits != NULL);

	bits->resize(0);
	bits->reserve(bit_stream_initial_capacity);

	// Генерация маркера структурированного соединения
	if (sa_enabled)
	{
		const int upper_latch = 29;
		const int mixed_latch = 29;

		bits->resize(bits->size() + bits_on_value);
		dec2bin(bits->end() - bits_on_value, bits->end(), mixed_latch);

		bits->resize(bits->size() + bits_on_value);
		dec2bin(bits->end() - bits_on_value, bits->end(), upper_latch);
	}

	// Генерация потока бит из входных данных
	typedef std::vector<
		typename std::iterator_traits<DataIterator>::value_type> buffer_type;
	enum {bits_on_small_size = 5};
	enum {bits_on_big_size = 11};

	buffer_type buffer;
	buffer.reserve(
		(1 << bits_on_big_size) - 1 + (1 << bits_on_small_size) - 1);

	for (;;)
	{
		// Чтение данных в буфер
		buffer.resize(0);
		while (data_first != data_last && buffer.size() < buffer.capacity())
			buffer.push_back(*data_first++);

		if (buffer.size() == 0)
			break;

		// Генерация ByteShift-а
		const int byte_shift = 31;

		bits->resize(bits->size() + bits_on_value);
		dec2bin(bits->end() - bits_on_value, bits->end(), byte_shift);

		if (buffer.size() <= (1 << bits_on_small_size) - 1)
		{
			bits->resize(bits->size() + bits_on_small_size);
			dec2bin(bits->end() - bits_on_small_size, bits->end(),
				buffer.size());
		}
		else
		{
			bits->resize(bits->size() + bits_on_small_size);
			dec2bin(bits->end() - bits_on_small_size, bits->end(), 0);

			bits->resize(bits->size() + bits_on_big_size);
			dec2bin(bits->end() - bits_on_big_size, bits->end(),
				buffer.size() - ((1 << bits_on_small_size) - 1));
		}

		// Генерация данных
		typename buffer_type::const_iterator b = buffer.begin();
		typename buffer_type::const_iterator e = buffer.end();
		while (b != e)
		{
			enum {bits_on_byte = 8};

			bits->resize(bits->size() + bits_on_byte);
			dec2bin(bits->end() - bits_on_byte, bits->end(), *b++);
		}
	}
}
