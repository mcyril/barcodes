#include <cassert>
#include <cstdlib>
#include <cstring>
#include <new>
#include <exception>
#include <limits>
#include "generate_barcode.h"
#include "generator_exception.h"
#include "aztecgen.h"


namespace
{
    class invalid_parameter_exception:
        public std::exception
    {
    };

    void check(bool result)
    {
        if (!result)
            throw invalid_parameter_exception();
    }


    int error_handler()
    {
        int result = AG_UNHANDLED_EXCEPTION;
        try
        {
            throw;
        }
        catch (const generator_exception &e)
        {
            switch (e.error_code())
            {
                case generator_exception::no_input_data_error:
                    result = AG_NO_INPUT_DATA;
                    break;

                case generator_exception::too_much_input_data_error:
                    result = AG_TOO_MUCH_INPUT_DATA;
                    break;

                default:
                    assert(false);
                    break;
            }
        }
        catch (const invalid_parameter_exception &)
        {
            result = AG_INVALID_PARAMETER;
        }
        catch (const std::bad_alloc &)
        {
            result = AG_OUT_OF_MEMORY;
        }
        catch (...)
        {
        }
        return result;
    }

    #define SAFE_BODY \
        { \
            int safe_body_result = AG_SUCCESS; \
            try \
            {

    #define END_SAFE_BODY \
            } \
            catch (...) \
            { \
                safe_body_result = error_handler(); \
            } \
            return safe_body_result; \
        }


    bool make_correct_settings(ag_settings *correct_settings,
        const ag_settings *settings = NULL)
    {
        assert(correct_settings != NULL);

        enum {symbol_type_mask = AG_SF_SYMBOL_TYPE};
        enum {symbol_format_mask = AG_SF_SYMBOL_FORMAT};
        enum {redundancy_for_error_correction_mask =
            AG_SF_REDUNDANCY_FOR_ERROR_CORRECTION};

        enum {default_symbol_type = AG_NORMAL_SYMBOL};
        enum {default_symbol_format = AG_ANYONE_FORMAT};
        enum {default_redundancy_for_error_correction = 23};

        #define INIT_FIELD(field_name) \
            correct_settings->mask |= field_name##_mask; \
            correct_settings->field_name = \
                (settings != NULL && (settings->mask & field_name##_mask) != 0) ? \
                    settings->field_name: \
                    default_##field_name

        correct_settings->mask = 0;

        INIT_FIELD(symbol_type);
        if (correct_settings->symbol_type != AG_NORMAL_SYMBOL &&
                correct_settings->symbol_type != AG_DEVICE_SPECIFIC_SYMBOL)
            return false;

        INIT_FIELD(symbol_format);
        if (correct_settings->symbol_format != AG_ANYONE_FORMAT &&
                correct_settings->symbol_format != AG_COMPACT_FORMAT &&
                correct_settings->symbol_format != AG_FULL_FORMAT &&
                (correct_settings->symbol_format < AG_15x15_COMPACT_FORMAT ||
                    correct_settings->symbol_format > AG_151x151_FULL_FORMAT))
            return false;

        INIT_FIELD(redundancy_for_error_correction);
        if (correct_settings->redundancy_for_error_correction >= 100)
            return false;

        #undef INIT_FIELD

        return true;
    }


    ag_matrix *create_matrix(size_t width, size_t height)
    {
        if (height > 0 &&
                width > std::numeric_limits<size_t>::max() / height)
            return NULL;

        ag_matrix *const mtx = static_cast<ag_matrix *>(
            malloc(sizeof(ag_matrix)));
        if (mtx == NULL)
            return NULL;

        if (width == 0 || height == 0)
            mtx->data = NULL;
        else
        {
            mtx->data = static_cast<unsigned char *>(
                malloc(width * height));
            if (mtx->data == NULL)
            {
                free(mtx);
                return NULL;
            }
        }
        mtx->width = width;
        mtx->height = height;

        return mtx;
    }

    void destroy_matrix(ag_matrix *mtx)
    {
        if (mtx == NULL)
            return;

        if (mtx->width > 0 && mtx->height > 0)
            free(mtx->data);
        free(mtx);
    }
}


AG_API_IMPL(int) ag_generate(ag_matrix **matrix, const void *data,
    size_t data_size, const ag_settings *settings)
{
    SAFE_BODY
    {
        check(matrix != NULL);
        check(data_size == 0 || data != NULL);

        // Получение итераторов на входные данные
        const unsigned char *const data_first =
            static_cast<const unsigned char *>(data);
        const unsigned char *const data_last =
            data_first + data_size;

        // Получение корректных настроек
        ag_settings correct_settings;
        const bool mcs_result =
            make_correct_settings(&correct_settings, settings);
        check(mcs_result);

        const unsigned long required_settings_mask =
            AG_SF_SYMBOL_TYPE |
            AG_SF_SYMBOL_FORMAT |
            AG_SF_REDUNDANCY_FOR_ERROR_CORRECTION;

        assert((correct_settings.mask & required_settings_mask) ==
            required_settings_mask);

        // Генерация штрих-кода
        bit_matrix_type barcode;
        generate_barcode(
            &barcode,
            data_first,
            data_last,
            correct_settings.redundancy_for_error_correction,
            symbol_format_type(correct_settings.symbol_format),
            correct_settings.symbol_type != AG_NORMAL_SYMBOL);

        // Формирование выходной матрицы
        *matrix = create_matrix(barcode.width(), barcode.height());
        if (*matrix == NULL)
            return AG_OUT_OF_MEMORY;

        if (barcode.width() > 0 && barcode.height() > 0)
        {
            assert(sizeof(bit_matrix_type::value_type) ==
                sizeof(unsigned char));

            memcpy((*matrix)->data, &barcode(0, 0), barcode.width() *
                barcode.height() * sizeof(bit_matrix_type::value_type));
        }
    }
    END_SAFE_BODY
}

AG_API_IMPL(int) ag_release_matrix(ag_matrix *matrix)
{
    SAFE_BODY
    {
        destroy_matrix(matrix);
    }
    END_SAFE_BODY
}
