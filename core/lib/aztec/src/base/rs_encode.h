/*
	\file
	\brief
		Генерация кодов коррекции ошибок Рида-Соломона.

	Алгоритм взят из ГОСТ-а по символике Aztec (стр. 19, Figure B2).
	Код переделан с С на С++, исправлен выход за границы массива ("if (j < nc - 1)").
*/


#pragma once
#include <cstddef>
#include <cassert>
#include <vector>
#include <algorithm>


/*!
	"rs_prod(x, y, log, alog, gf)" returns the product "x" times "y".
*/
template <typename Codeword>
inline Codeword rs_prod(
	Codeword x,
	Codeword y,
	const std::vector<Codeword> &log,
	const std::vector<Codeword> &alog,
	Codeword gf)
{
	assert(gf > 1);
	assert(x >= 0 && x < gf);
	assert(y >= 0 && y < gf);
	assert(log.size() == gf);
	assert(alog.size() == gf);

	return (x == 0 || y == 0) ?
		0: alog[(log[x] + log[y]) % (gf - 1)];
}


/*!
	"rs_encode(wd, nd, nc, gf, pp)" takes "nd" data codeword values in wd[]
	and adds on "nc" check codewords, all within GF(gf) where "gf" is a
	power of 2 and "pp" is the value of its prime modulus polynomial.
*/
template <typename Codeword>
void rs_encode(
	Codeword *wd,
	size_t nd,
	size_t nc,
	Codeword gf,
	Codeword pp)
{
	assert(wd != NULL);
	assert(nd > 0);
	assert(nc > 0);
	assert(gf > 1);
	assert((gf & (gf - 1)) == 0);
	assert((pp & ~(gf - 1)) == gf);

	// Generate the log & antilog arrays
	std::vector<Codeword> log(gf);
	std::vector<Codeword> alog(gf);

	log[0] = 1 - gf;
	alog[0] = 1;
	for (Codeword i = 1; i < gf; ++i)
	{
		alog[i] = alog[i - 1] << 1;
		if (alog[i] >= gf)
			alog[i] ^= pp;
		log[alog[i]] = i;
	}

	// Generate the generator polynomial coefficients
	std::vector<Codeword> c(nc + 1, 0);
	c[0] = 1;

	for (size_t i = 1; i <= nc; ++i)
	{
		c[i] = c[i - 1];
		for (size_t j = i - 1; j >= 1; --j)
			c[j] = c[j - 1] ^ rs_prod(c[j], alog[i], log, alog, gf);
		c[0] = rs_prod(c[0], alog[i], log, alog, gf);
	}

	// Generate "nc" checkwords in the array wd[]
	using std::fill_n;
	fill_n(&wd[nd], nc, 0);

	for (size_t i = 0; i < nd; ++i)
	{
		assert(wd[i] >= 0 && wd[i] < gf);

		const Codeword k = wd[nd] ^ wd[i];
		for (size_t j = 0; j < nc; ++j)
		{
			wd[nd + j] = rs_prod(k, c[nc - j - 1], log, alog, gf);
			if (j < nc - 1)
				wd[nd + j] ^= wd[nd + j + 1];
		}
	}
}
