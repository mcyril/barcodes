#include <cstddef>
#include <cassert>
#include "symbol_matrix.h"


symbol_matrix::symbol_matrix(matrix_type *mtx)
    : _matrix(mtx)
{
    assert(mtx != NULL);
}

symbol_matrix::~symbol_matrix()
{
}

void symbol_matrix::set(coord_type x, coord_type y, value_type v)
{
    const coord_type xt = coord_type(_matrix->width() / 2) + x;
    const coord_type yt = coord_type(_matrix->height() / 2) + y;

    assert(xt >= 0);
    assert(yt >= 0);
    (*_matrix)(matrix_type::size_type(xt), matrix_type::size_type(yt)) = v;
}

void symbol_matrix::restrictive_rectangle(rect_type *rect) const
{
    assert(rect != NULL);

    rect->left = -coord_type(_matrix->width() / 2);
    rect->right = rect->left + coord_type(_matrix->width());
    rect->top = -coord_type(_matrix->height() / 2);
    rect->bottom = rect->top + coord_type(_matrix->height());
}

full_symbol_matrix::full_symbol_matrix(matrix_type *mtx)
    : symbol_matrix(mtx)
{
    draw_grid();
}

void full_symbol_matrix::set(coord_type x, coord_type y, value_type v)
{
    symbol_matrix::set(
        x + correction_for_grid(x), y + correction_for_grid(y), v);
}

void full_symbol_matrix::draw_grid()
{
    rect_type rect;
    restrictive_rectangle(&rect);

    for (coord_type y = rect.top; y < rect.bottom; ++y)
        for (coord_type x = rect.left; x < rect.right; ++x)
        {
            if (y % grid_step == 0)
                symbol_matrix::set(x, y, (x % 2 == 0) ? 1: 0);
            else if (x % grid_step == 0)
                symbol_matrix::set(x, y, (y % 2 == 0) ? 1: 0);
        }
}

full_symbol_matrix::coord_type full_symbol_matrix::correction_for_grid(
    coord_type t) const
{
    return (t < 0) ?
        (t + 1) / (grid_step - 1):
        t / (grid_step - 1) + 1;
}
