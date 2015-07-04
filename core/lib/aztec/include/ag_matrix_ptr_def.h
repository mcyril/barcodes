#pragma once
#include <cassert>
#include <algorithm>


inline ag_matrix_ptr::ag_matrix_ptr(ag_matrix *mtx)
	: _mtx(mtx)
{
}

inline ag_matrix_ptr::~ag_matrix_ptr()
{
	reset();
}

inline ag_matrix *ag_matrix_ptr::get() const
{
	return _mtx;
}

inline ag_matrix *ag_matrix_ptr::release()
{
	ag_matrix *t = _mtx;
	_mtx = NULL;
	return t;
}

inline void ag_matrix_ptr::reset(ag_matrix *mtx)
{
	if (mtx == _mtx)
		return;

	if (_mtx != NULL)
		ag_release_matrix(_mtx);

	_mtx = mtx;
}

inline void ag_matrix_ptr::swap(ag_matrix_ptr &right)
{
	using std::swap;
	swap(_mtx, right._mtx);
}

inline ag_matrix &ag_matrix_ptr::operator * () const
{
	assert(_mtx != NULL);
	return *_mtx;
}

inline ag_matrix *ag_matrix_ptr::operator -> () const
{
	assert(_mtx != NULL);
	return _mtx;
}


inline void swap(ag_matrix_ptr &left, ag_matrix_ptr &right)
{
	left.swap(right);
}
