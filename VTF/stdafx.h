/*
 * VTFLib
 * Copyright (C) 2005-2011 Neil Jedrzejewski & Ryan Gregg

 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later
 * version.
 */

// ============================================================
// NOTE: This file is commented for compatibility with Doxygen.
// ============================================================
/*!
	\file StdAfx.h
	\brief Application framework header plus VTFLib custom data types.
*/

#ifndef STDAFX_H
#define STDAFX_H

#ifdef _MSC_VER
#ifdef VTFLIB_EXPORTS
#	define VTFLIB_API __declspec(dllexport)
#else
#	define VTFLIB_API __declspec(dllimport)
#endif
#else
#	if defined(HAVE_GCCVISIBILITYPATCH) || __GNUC__ >= 4
#		define VTFLIB_API __attribute__ ((visibility("default")))
#	else
#		define VTFLIB_API
#	endif
#endif

// Custom data types
typedef unsigned char	vlBool;				//!< Boolean value 0/1.
typedef char			vlChar;				//!< Single signed character.
typedef unsigned char	vlByte;				//!< Single unsigned byte.
typedef signed short	vlShort;			//!< Signed short floating point value.
typedef unsigned short	vlUShort;			//!< Unsigned short floating point value.
typedef signed int		vlInt;				//!< Signed integer value.
typedef unsigned int	vlUInt;				//!< Unsigned integer value.
typedef signed long		vlLong;				//!< Signed long number.
typedef unsigned long	vlULong;			//!< Unsigned long number.
typedef float			vlSingle;			//!< Floating point number
typedef double			vlDouble;			//!< Double number
typedef void			vlVoid;				//!< Void value.

#ifdef _MSC_VER
typedef unsigned __int8		vlUInt8;
typedef unsigned __int16	vlUInt16;
typedef unsigned __int32	vlUInt32;
typedef unsigned __int64	vlUInt64;
#else
#include <stdint.h>
typedef uint8_t		vlUInt8;
typedef uint16_t	vlUInt16;
typedef uint32_t	vlUInt32;
typedef uint64_t	vlUInt64;
#endif



typedef vlSingle		vlFloat;			//!< Floating point number (same as vlSingled).

#define vlFalse			0
#define vlTrue			1


#ifdef __cplusplus
extern "C" {
#endif

	
typedef enum tagVLSeekMode {
	SEEK_MODE_BEGIN = 0,
	SEEK_MODE_CURRENT,
	SEEK_MODE_END
} VLSeekMode;
	
	
#ifdef __cplusplus
}
#endif


#if _MSC_VER >= 1400
#	define _CRT_SECURE_NO_WARNINGS
#	define _CRT_NONSTDC_NO_DEPRECATE
#endif

#ifdef _WIN32
#	define WIN32_LEAN_AND_MEAN
#	include <windows.h>
#	include <stdlib.h>
#	include <stdio.h>
#	include <assert.h>
#	include <math.h>
#	include <stdarg.h>

#	if _MSC_VER >= 1600 // Visual Studio 2010
#		define STATIC_ASSERT(condition, message) static_assert(condition, message)
#	else
#		define STATIC_ASSERT(condition, message) typedef char __C_ASSERT__[(condition) ? 1 : -1]
#	endif
    
#	undef USE_NVTT
#	define USE_NVDXT

#else

#	define stricmp strcasecmp
#	define _stricmp strcasecmp
#	define _strnicmp strncasecmp
#	include <errno.h>
#	include <sys/types.h>
#	include <sys/stat.h>
#	include <sys/mman.h>
#	include <unistd.h>
#	include <fcntl.h>


#	include <assert.h>
#	include <stdlib.h>
#	include <stdio.h>
#	include <time.h>
#	include <math.h>

#	include <list>
#	include <vector>

//#	define STATIC_ASSERT(condition, message) static_assert(condition, message)
#		define STATIC_ASSERT(condition, message) typedef char __C_ASSERT__[(condition) ? 1 : -1]

#	undef USE_NVDXT
#	define USE_NVTT

#endif



#endif


