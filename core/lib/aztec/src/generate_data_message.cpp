#include <cstddef>
#include <cassert>
#include <algorithm>
#include "base/bin_dec_conversion.h"
#include "add_reed_solomon_checkwords.h"
#include "generate_data_message.h"


void generate_data_message(bit_vector_type *data_message,
    const symbol_info_type &symbol_info,
    const codeword_vector_type &codewords)
{
    assert(data_message != NULL);
    assert(codewords.size() <= symbol_info.data_message.codeword_count);

    // Добавление к потоку кодовых слов кодов коррекции ошибок
    codeword_vector_type data_with_crc;
    data_with_crc.reserve(symbol_info.data_message.codeword_count);

    data_with_crc = codewords;

    add_reed_solomon_checkwords(&data_with_crc,
        symbol_info.data_message.codeword_size,
        symbol_info.data_message.codeword_count - data_with_crc.size());

    // Заполнение Data Message
    //
    // Бит информации в N-слойном символе =
    //  4 * width * (
    //      (first_layer_height - 1 * width) +
    //      (first_layer_height + 1 * width) +
    //      (first_layer_height + 3 * width) +
    //      (first_layer_height + 5 * width) +
    //      ...)
    //
    //  4 * width * N * (first_layer_height + width * (N - 2))

    const unsigned short data_message_size =
        4 * symbol_info.data_message.layer_width * symbol_info.data_message.layers *
        (symbol_info.data_message.first_layer_height +
            symbol_info.data_message.layer_width * (symbol_info.data_message.layers - 2));
    assert(data_message_size >=
        data_with_crc.size() * symbol_info.data_message.codeword_size);

    data_message->resize(0);
    data_message->reserve(data_message_size);

    data_message->resize(
        data_with_crc.size() * symbol_info.data_message.codeword_size);
    dec2bin(data_message->begin(), data_message->end(),
        data_with_crc.begin(), data_with_crc.end());
    using std::reverse;
    reverse(data_message->begin(), data_message->end());

    data_message->resize(data_message_size, 0);
}
