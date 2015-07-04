#pragma once
#include <vector>
#include "base/matrix.h"


typedef unsigned char bit_type;
typedef unsigned short codeword_type;

typedef std::vector<bit_type> bit_vector_type;
typedef std::vector<codeword_type> codeword_vector_type;

typedef matrix<bit_type> bit_matrix_type;


enum symbol_format_type
{
	 anyone_format,
	compact_format,
	   full_format,
	compact_format_15x15,
	   full_format_19x19,
	compact_format_19x19,
	   full_format_23x23,
	compact_format_23x23,
	   full_format_27x27,
	compact_format_27x27,
	   full_format_31x31,
	   full_format_37x37,
	   full_format_41x41,
	   full_format_45x45,
	   full_format_49x49,
	   full_format_53x53,
	   full_format_57x57,
	   full_format_61x61,
	   full_format_67x67,
	   full_format_71x71,
	   full_format_75x75,
	   full_format_79x79,
	   full_format_83x83,
	   full_format_87x87,
	   full_format_91x91,
	   full_format_95x95,
	   full_format_101x101,
	   full_format_105x105,
	   full_format_109x109,
	   full_format_113x113,
	   full_format_117x117,
	   full_format_121x121,
	   full_format_125x125,
	   full_format_131x131,
	   full_format_135x135,
	   full_format_139x139,
	   full_format_143x143,
	   full_format_147x147,
	   full_format_151x151
};


struct brief_symbol_info_type
{
	unsigned char layers;
	bool is_compact;
	unsigned char size;
	unsigned short codeword_count;
	unsigned char codeword_size;
};

struct symbol_info_type
{
	unsigned char size;
	bool is_compact;
	bool is_initialization;

	struct
	{
		unsigned char layer_width;
		unsigned char first_layer_height;
		unsigned char layers;

		unsigned short codeword_count;
		unsigned char codeword_size;
	}
	data_message;

	struct
	{
		unsigned char layer_width;
		unsigned char first_layer_height;

		unsigned char bits_on_symbol_size;
		unsigned char bits_on_message_length;
		unsigned char codeword_count;
		unsigned char codeword_size;
	}
	mode_message;

	struct
	{
		unsigned char layer_width;
		unsigned char first_layer_height;
		unsigned char first_layer_color;
		unsigned char layers;
	}
	bulls_eye;
};


enum {bit_stream_initial_capacity = 20000};
enum {codeword_stream_initial_capacity = 2000};
