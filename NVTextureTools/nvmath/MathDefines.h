// This code is in the public domain -- castanyo@yahoo.es

#pragma once
#ifndef NV_MATH_DEFINES_H
#define NV_MATH_DEFINES_H

// Function linkage
#if NVMATH_SHARED
#ifdef NVMATH_EXPORTS
#define NVMATH_API DLL_EXPORT
#define NVMATH_CLASS DLL_EXPORT_CLASS
#else
#define NVMATH_API DLL_IMPORT
#define NVMATH_CLASS DLL_IMPORT
#endif
#else // NVMATH_SHARED
#define NVMATH_API
#define NVMATH_CLASS
#endif // NVMATH_SHARED

#ifndef PI
#define PI                  float(3.1415926535897932384626433833)
#endif

#define NV_EPSILON          (0.0001f)
#define NV_NORMAL_EPSILON   (0.001f)


#endif // NV_MATH_DEFINES_H
