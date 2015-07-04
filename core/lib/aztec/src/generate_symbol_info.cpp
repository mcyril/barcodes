#include <cstddef>
#include <cassert>
#include "generate_symbol_info.h"


void generate_symbol_info(symbol_info_type *info,
    const brief_symbol_info_type &brief_info,
    bool is_initialization_symbol)
{
    assert(info != NULL);

    info->size = brief_info.size;
    info->is_compact = brief_info.is_compact;
    info->is_initialization = is_initialization_symbol;

    info->bulls_eye.layer_width = 1;
    info->bulls_eye.first_layer_height = info->is_compact ? 1: 2;
    info->bulls_eye.first_layer_color = info->is_compact ? 1: 0;
    info->bulls_eye.layers = info->is_compact ? 5: 6;

    info->mode_message.layer_width = 1;
    info->mode_message.first_layer_height =
        info->bulls_eye.first_layer_height + 2 * (
            (info->bulls_eye.layers - 1) * info->bulls_eye.layer_width +
            info->mode_message.layer_width);
    info->mode_message.bits_on_symbol_size = info->is_compact ? 2: 5;
    info->mode_message.bits_on_message_length = info->is_compact ? 6: 11;
    info->mode_message.codeword_count = info->is_compact ? 7: 10;
    info->mode_message.codeword_size = 4;

    info->data_message.layer_width = 2;
    info->data_message.first_layer_height =
        info->mode_message.first_layer_height +
        2 * info->data_message.layer_width;
    info->data_message.layers = brief_info.layers;
    info->data_message.codeword_count = brief_info.codeword_count;
    info->data_message.codeword_size = brief_info.codeword_size;
}
