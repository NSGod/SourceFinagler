//
//  HLKitDefines.h
//  HLKit
//
//  Created by Mark Douma on 6/1/2011
//  Copyright (c) 2009-2012 Mark Douma LLC. All rights reserved.
//

#ifndef _HLKITDEFINES_H
#define _HLKITDEFINES_H

#import <AvailabilityMacros.h>

//
//  Platform specific defs for externs
//

//
// For MACH
//

#if defined(__MACH__)

#ifdef __cplusplus
#define HLKIT_EXTERN		extern "C"
#define HLKIT_PRIVATE_EXTERN	__private_extern__
#else
#define HLKIT_EXTERN				extern
#define HLKIT_PRIVATE_EXTERN	__private_extern__
#endif

#if !defined(HLKIT_INLINE)
#if defined(__GNUC__)
#define HLKIT_INLINE static __inline__ __attribute__((always_inline))
#elif defined(__MWERKS__) || defined(__cplusplus)
#define HLKIT_INLINE static inline
#endif
#endif

#if !defined(HLKIT_STATIC_INLINE)
#define HLKIT_STATIC_INLINE static __inline__
#endif

#if !defined(HLKIT_EXTERN_INLINE)
#define HLKIT_EXTERN_INLINE extern __inline__
#endif


#endif

#endif // _HLKITDEFINES_H
