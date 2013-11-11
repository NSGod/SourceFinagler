//
//  TextureKitDefines.h
//  Texture Kit
//
//  Created by Mark Douma on 12/17/2010.
//  Copyright (c) 2010-2013 Mark Douma LLC. All rights reserved.
//

#ifndef _TEXTUREKITDEFINES_H
#define _TEXTUREKITDEFINES_H

#import <AvailabilityMacros.h>

//
//  Platform specific defs for externs
//

//
// For MACH
//

#if defined(__MACH__)

#if defined(__cplusplus)
	#define TEXTUREKIT_EXTERN		extern "C"
	#define TEXTUREKIT_PRIVATE_EXTERN	__private_extern__
#else
	#define TEXTUREKIT_EXTERN				extern
	#define TEXTUREKIT_PRIVATE_EXTERN	__private_extern__
#endif

#if !defined(TEXTUREKIT_INLINE)
	#if defined(__GNUC__)
		#define TEXTUREKIT_INLINE static __inline__ __attribute__((always_inline))
	#elif defined(__MWERKS__) || defined(__cplusplus)
		#define TEXTUREKIT_INLINE static inline
	#endif
#endif

#if !defined(TEXTUREKIT_STATIC_INLINE)
	#define TEXTUREKIT_STATIC_INLINE static __inline__
#endif

#if !defined(TEXTUREKIT_EXTERN_INLINE)
	#define TEXTUREKIT_EXTERN_INLINE extern __inline__
#endif


#endif

#endif // _TEXTUREKITDEFINES_H
