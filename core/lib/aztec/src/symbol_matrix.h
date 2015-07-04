#pragma once
#include "common_definitions.h"


class symbol_matrix
{
public:
    typedef bit_matrix_type matrix_type;
    typedef matrix_type::value_type value_type;
    typedef short coord_type;

    explicit symbol_matrix(matrix_type *mtx);
    virtual ~symbol_matrix();

    virtual void set(coord_type x, coord_type y, value_type v);

protected:
    struct rect_type
    {
        coord_type left;
        coord_type top;
        coord_type right;
        coord_type bottom;
    };

    void restrictive_rectangle(rect_type *rect) const;

private:
    matrix_type *_matrix;
};


typedef symbol_matrix compact_symbol_matrix;

class full_symbol_matrix: public symbol_matrix
{
public:
    full_symbol_matrix(matrix_type *mtx);

    virtual void set(coord_type x, coord_type y, value_type v);

private:
    enum {grid_step = 16};

    void draw_grid();
    coord_type correction_for_grid(coord_type t) const;
};
