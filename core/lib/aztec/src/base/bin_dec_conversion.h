#pragma once
#include <cstddef>
#include <cassert>
#include <climits>
#include <iterator>
#include <algorithm>


template <typename BinIterator, typename DecValue>
void dec2bin(BinIterator bin_first, BinIterator bin_last, DecValue dec)
{
	assert(bin_last - bin_first > 0);

	for (BinIterator bin_current = bin_first;
		bin_current != bin_last; ++bin_current)
	{
		*bin_current =
			typename std::iterator_traits<BinIterator>::value_type(dec & 1);
		dec >>= 1;
	}
	assert(dec == 0 || dec == -1);

	using std::reverse;
	reverse(bin_first, bin_last);
}

template <typename BinIterator, typename DecIterator>
void dec2bin(BinIterator bin_first, BinIterator bin_last,
	DecIterator dec_first, DecIterator dec_last)
{
	const typename std::iterator_traits<BinIterator>::difference_type bin_size =
		bin_last - bin_first;
	const typename std::iterator_traits<DecIterator>::difference_type dec_size =
		dec_last - dec_first;
	assert(dec_size > 0);
	assert(bin_size % dec_size == 0);

	const typename std::iterator_traits<BinIterator>::difference_type bits =
		bin_size / dec_size;

	while (dec_first != dec_last)
	{
		dec2bin(bin_first, bin_first + bits, *dec_first);
		bin_first += bits;
		++dec_first;
	}
}

template <typename DecValue, typename BinIterator>
void bin2dec(DecValue *dec, BinIterator bin_first, BinIterator bin_last)
{
	assert(dec != NULL);
	assert(bin_last - bin_first > 0 &&
		bin_last - bin_first <= sizeof(DecValue) * CHAR_BIT);

	*dec = 0;

	while (bin_first != bin_last)
	{
		assert(*bin_first == 0 || *bin_first == 1);

		*dec <<= 1;
		if (*bin_first != 0)
			*dec |= 1;

		++bin_first;
	}
}

template <typename DecIterator, typename BinIterator>
void bin2dec(DecIterator dec_first, DecIterator dec_last,
	BinIterator bin_first, BinIterator bin_last)
{
	const typename std::iterator_traits<BinIterator>::difference_type bin_size =
		bin_last - bin_first;
	const typename std::iterator_traits<DecIterator>::difference_type dec_size =
		dec_last - dec_first;
	assert(dec_size > 0);
	assert(bin_size % dec_size == 0);

	const typename std::iterator_traits<BinIterator>::difference_type bits =
		bin_size / dec_size;

	while (dec_first != dec_last)
	{
		bin2dec(&*dec_first, bin_first, bin_first + bits);
		bin_first += bits;
		++dec_first;
	}
}
