#include <cstddef>
#include <cassert>
#include "base/rs_encode.h"
#include "add_reed_solomon_checkwords.h"


void add_reed_solomon_checkwords(
	codeword_vector_type *codewords,
	unsigned char codeword_size,
	codeword_vector_type::size_type crc_size)
{
	assert(codewords != NULL);
	assert(codewords->size() > 0);

	codeword_type poly;
	switch (codeword_size)
	{
		case  4:   poly =   19; break;
		case  6:   poly =   67; break;
		case  8:   poly =  301; break;
		case 10:   poly = 1033; break;
		case 12:   poly = 4201; break;
		default: assert(false); break;
	}

	const codeword_vector_type::size_type data_size = codewords->size();
	codewords->resize(data_size + crc_size);

	rs_encode(&(*codewords)[0], data_size,
		crc_size, codeword_type(1 << codeword_size), poly);
}
