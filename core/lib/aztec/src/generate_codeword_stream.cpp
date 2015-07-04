#include <cstddef>
#include <cassert>
#include <algorithm>
#include "base/bin_dec_conversion.h"
#include "generate_codeword_stream.h"


void generate_codeword_stream(codeword_vector_type *codewords,
    const bit_vector_type &bits, unsigned char codeword_size)
{
    assert(codewords != NULL);
    assert(bits.size() > 0);
    assert(codeword_size >= 2);

    codewords->resize(0);
    codewords->reserve(codeword_stream_initial_capacity);

    bit_vector_type codeword_bits;
    codeword_bits.reserve(codeword_size);

    bit_vector_type::const_iterator b = bits.begin();
    bit_vector_type::const_iterator e = bits.end();
    while (b != e)
    {
        typedef bit_vector_type::difference_type difference_type;
        difference_type number_of_used_bits =
            std::min(e - b, difference_type(codeword_size));

        // Создание кодового слова из набора бит
        codeword_bits.assign(b, b + number_of_used_bits);
        codeword_bits.insert(codeword_bits.end(),
            codeword_size - number_of_used_bits, 1);

        codeword_type codeword;
        bin2dec(&codeword, codeword_bits.begin(), codeword_bits.end());

        // Добавление защиты от стирания
        const codeword_type pseudo_erasure_mask =
            (codeword_type(1) << codeword_size) - 1 - 1;

        if ((codeword & pseudo_erasure_mask) == 0)
        {
            codeword = 1;
            number_of_used_bits = std::min(
                number_of_used_bits, difference_type(codeword_size - 1));
        }
        else if ((codeword & pseudo_erasure_mask) == pseudo_erasure_mask)
        {
            codeword = pseudo_erasure_mask;
            number_of_used_bits = std::min(
                number_of_used_bits, difference_type(codeword_size - 1));
        }

        // Вставка кодового слова в поток
        codewords->push_back(codeword);

        b += number_of_used_bits;
    }
}
