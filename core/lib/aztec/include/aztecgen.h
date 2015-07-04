#pragma once
#include <stddef.h>


/*****************************************************************************
    Constants
*****************************************************************************/
enum
{
    AG_SUCCESS             = 0,
    AG_INVALID_PARAMETER   = 1,
    AG_OUT_OF_MEMORY       = 2,
    AG_UNHANDLED_EXCEPTION = 3,
    AG_NO_INPUT_DATA       = 4,
    AG_TOO_MUCH_INPUT_DATA = 5
};

enum
{
    AG_NORMAL_SYMBOL          = 0,
    AG_DEVICE_SPECIFIC_SYMBOL = 1
};

enum
{
    AG_ANYONE_FORMAT        =  0,
    /***************************/
    AG_COMPACT_FORMAT       =  1,
    AG_FULL_FORMAT          =  2,
    /***************************/
    AG_15x15_COMPACT_FORMAT =  3,
    AG_19x19_FULL_FORMAT    =  4,
    AG_19x19_COMPACT_FORMAT =  5,
    AG_23x23_FULL_FORMAT    =  6,
    AG_23x23_COMPACT_FORMAT =  7,
    AG_27x27_FULL_FORMAT    =  8,
    AG_27x27_COMPACT_FORMAT =  9,
    AG_31x31_FULL_FORMAT    = 10,
    AG_37x37_FULL_FORMAT    = 11,
    AG_41x41_FULL_FORMAT    = 12,
    AG_45x45_FULL_FORMAT    = 13,
    AG_49x49_FULL_FORMAT    = 14,
    AG_53x53_FULL_FORMAT    = 15,
    AG_57x57_FULL_FORMAT    = 16,
    AG_61x61_FULL_FORMAT    = 17,
    AG_67x67_FULL_FORMAT    = 18,
    AG_71x71_FULL_FORMAT    = 19,
    AG_75x75_FULL_FORMAT    = 20,
    AG_79x79_FULL_FORMAT    = 21,
    AG_83x83_FULL_FORMAT    = 22,
    AG_87x87_FULL_FORMAT    = 23,
    AG_91x91_FULL_FORMAT    = 24,
    AG_95x95_FULL_FORMAT    = 25,
    AG_101x101_FULL_FORMAT  = 26,
    AG_105x105_FULL_FORMAT  = 27,
    AG_109x109_FULL_FORMAT  = 28,
    AG_113x113_FULL_FORMAT  = 29,
    AG_117x117_FULL_FORMAT  = 30,
    AG_121x121_FULL_FORMAT  = 31,
    AG_125x125_FULL_FORMAT  = 32,
    AG_131x131_FULL_FORMAT  = 33,
    AG_135x135_FULL_FORMAT  = 34,
    AG_139x139_FULL_FORMAT  = 35,
    AG_143x143_FULL_FORMAT  = 36,
    AG_147x147_FULL_FORMAT  = 37,
    AG_151x151_FULL_FORMAT  = 38
};

enum
{
    AG_SF_SYMBOL_TYPE                     = 1,
    AG_SF_SYMBOL_FORMAT                   = 2,
    AG_SF_REDUNDANCY_FOR_ERROR_CORRECTION = 4
};


/*****************************************************************************
    Types
*****************************************************************************/
typedef struct ag_matrix_tag
{
    unsigned char *data;
    size_t width;
    size_t height;
}
ag_matrix;

typedef struct ag_settings_tag
{
    unsigned long mask;
    unsigned char symbol_type;               /* AG_NORMAL_SYMBOL by default */
    unsigned char symbol_format;             /* AG_ANYONE_FORMAT by default */
    unsigned char redundancy_for_error_correction; /*        23% by default */
}
ag_settings;


/*****************************************************************************
    Prototypes of functions
*****************************************************************************/
#ifdef __cplusplus
    #define AG_EXTERN_C extern "C"
#else
    #define AG_EXTERN_C
#endif

#ifdef AG_API_EXPORTS
    #ifdef __GNUC__
        #define AG_EXPORT __attribute__((visibility("default")))
    #else
        #define AG_EXPORT __declspec(dllexport)
    #endif
#else
    #define AG_EXPORT
#endif

#define AG_API(return_type) AG_EXTERN_C AG_EXPORT return_type
#define AG_API_IMPL(return_type) AG_EXTERN_C return_type


AG_API(int) ag_generate(ag_matrix **matrix, const void *data,
    size_t data_size, const ag_settings *settings);

AG_API(int) ag_release_matrix(ag_matrix *matrix);
