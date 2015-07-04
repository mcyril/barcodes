#pragma once
#include <cassert>
#include <algorithm>


template <typename Type, typename Allocator>
inline matrix<Type, Allocator>::matrix(const allocator_type &allocator)
    : _data(allocator), _width(0), _height(0)
{
}

template <typename Type, typename Allocator>
inline matrix<Type, Allocator>::matrix(
        size_type current_width, size_type current_height,
        const value_type &value, const allocator_type &allocator)
    : _data(current_width * current_height, value, allocator),
      _width(current_width), _height(current_height)
{
}

template <typename Type, typename Allocator>
inline void matrix<Type, Allocator>::clear()
{
    resize(0, 0);
}

template <typename Type, typename Allocator>
inline void matrix<Type, Allocator>::resize(
    size_type new_width, size_type new_height,
    const value_type &value)
{
    if (new_width == width() && new_height == height())
        return;

    matrix t(new_width, new_height, value);
    for (size_type y = 0, y_max = std::min(height(), new_height);
        y < y_max; ++y)
    {
        for (size_type x = 0, x_max = std::min(width(), new_width);
            x < x_max; ++x)
        {
            using std::swap;
            swap((*this)(x, y), t(x, y));
        }
    }
    swap(t);
}

template <typename Type, typename Allocator>
inline void matrix<Type, Allocator>::swap(matrix &right)
{
    using std::swap;
    swap(_data, right._data);
    swap(_width, right._width);
    swap(_height, right._height);
}

template <typename Type, typename Allocator>
inline typename matrix<Type, Allocator>::size_type
    matrix<Type, Allocator>::width() const
{
    return _width;
}

template <typename Type, typename Allocator>
inline typename matrix<Type, Allocator>::size_type
    matrix<Type, Allocator>::height() const
{
    return _height;
}

template <typename Type, typename Allocator>
inline typename matrix<Type, Allocator>::const_reference
    matrix<Type, Allocator>::operator () (size_type x, size_type y) const
{
    return _data[index(x, y)];
}

template <typename Type, typename Allocator>
inline typename matrix<Type, Allocator>::reference
    matrix<Type, Allocator>::operator () (size_type x, size_type y)
{
    return _data[index(x, y)];
}

template <typename Type, typename Allocator>
inline typename matrix<Type, Allocator>::size_type
    matrix<Type, Allocator>::index(size_type x, size_type y) const
{
    assert(x < width());
    assert(y < height());

    return y * width() + x;
}


template <typename Type, typename Allocator>
inline void swap(
    matrix<Type, Allocator> &left, matrix<Type, Allocator> &right)
{
    left.swap(right);
}
