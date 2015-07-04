#include <cassert>
#include <cstddef>
#include <algorithm>
#include "wrapping_clockwise.h"


void wrapping_clockwise(symbol_matrix *mtx,
	const bit_vector_type &data, unsigned char layer_width,
	unsigned char first_layer_height)
{
	assert(mtx != NULL);
	assert(data.size() > 0);
	assert(layer_width > 0);
	assert((first_layer_height == layer_width && layer_width == 1) ||
		first_layer_height >= 2 * layer_width);

	bit_vector_type::const_iterator b = data.begin();
	bit_vector_type::const_iterator e = data.end();

	for (unsigned char current_layer_height = first_layer_height;
		;
		current_layer_height += 2 * layer_width)
	{
		if (current_layer_height == layer_width)
		{
			if (b == e)
				return;

			mtx->set(0, 0, *b++);
			continue;
		}

		const int x0 = -current_layer_height / 2 + layer_width;
		const int y0 = -current_layer_height / 2 + current_layer_height - layer_width;
		const int even_coeff = (current_layer_height + 1) % 2;

		for (int i = 0; i < 4; ++i)
		{
			for (int h = 0; h < current_layer_height - layer_width; ++h)
			{
				for (int w = 0; w < layer_width; ++w)
				{
					using std::swap;
					int x = x0 + h, y = y0 + w;

					switch (i)
					{
						case 1:
							swap(x, y);
							y = -(y + even_coeff);
							break;

						case 2:
							x = -(x + even_coeff);
							y = -(y + even_coeff);
							break;

						case 3:
							swap(x, y);
							x = -(x + even_coeff);
							break;
					}

					if (b == e)
					{
						assert(i == 0 && h == 0 && w == 0);
						return;
					}

					mtx->set(x, y, *b++);
				}
			}
		}
	}
}
