#include <cassert>
#include "generator_exception.h"


generator_exception::generator_exception(error_code_type ecode)
	: _error_code(ecode)
{
}

generator_exception::error_code_type generator_exception::error_code() const
{
	return _error_code;
}

const char *generator_exception::what() const
{
	const char *msg = "unknown error_code";

	switch (_error_code)
	{
		case no_input_data_error:
			msg = "no input data";
			break;

		case too_much_input_data_error:
			msg = "too much input data";
			break;

		default:
			assert(false);
			break;
	}

	return msg;
}
