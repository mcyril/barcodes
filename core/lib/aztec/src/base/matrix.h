#pragma once
#include <memory>
#include <vector>


template <typename Type, typename Allocator = std::allocator<Type> >
class matrix
{
public:
    typedef Allocator allocator_type;
    typedef typename allocator_type::value_type value_type;
    typedef typename allocator_type::size_type size_type;
    typedef typename allocator_type::reference reference;
    typedef typename allocator_type::const_reference const_reference;

    explicit matrix(const allocator_type &allocator = allocator_type());
    matrix(size_type current_width, size_type current_height,
        const value_type &value = value_type(),
        const allocator_type &allocator = allocator_type());

    void clear();
    void resize(size_type new_width, size_type new_height,
        const value_type &value = value_type());
    void swap(matrix &right);

    size_type width() const;
    size_type height() const;

    const_reference operator () (size_type x, size_type y) const;
    reference operator () (size_type x, size_type y);

private:
    typedef std::vector<value_type, allocator_type> data_type;

    data_type _data;
    size_type _width;
    size_type _height;

    size_type index(size_type x, size_type y) const;
};


template <typename Type, typename Allocator>
void swap(matrix<Type, Allocator> &left, matrix<Type, Allocator> &right);


#include "matrix_def.h"
