#pragma once
#include <exception>


class generator_exception: public std::exception
{
public:
	enum error_code_type
	{
		no_input_data_error       = 1,
		too_much_input_data_error = 2
	};

	generator_exception(error_code_type ecode);

	error_code_type error_code() const;
	virtual const char *what() const throw();

private:
	error_code_type _error_code;
};
