#pragma once
#include <cstddef>
#include "aztecgen.h"


class ag_matrix_ptr
{
public:
    explicit ag_matrix_ptr(ag_matrix *mtx = NULL);
    ~ag_matrix_ptr();

    ag_matrix *get() const;

    ag_matrix *release();
    void reset(ag_matrix *mtx = NULL);
    void swap(ag_matrix_ptr &right);

    ag_matrix &operator * () const;
    ag_matrix *operator -> () const;

private:
    ag_matrix *_mtx;

    ag_matrix_ptr(const ag_matrix_ptr &);
    ag_matrix_ptr &operator = (const ag_matrix_ptr &);
};


void swap(ag_matrix_ptr &left, ag_matrix_ptr &right);


#include "ag_matrix_ptr_def.h"
