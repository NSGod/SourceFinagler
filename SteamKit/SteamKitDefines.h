//
//  SteamKitDefines.h
//  Steam Kit
//
//  Created by Mark Douma on 12/17/2010.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//

#ifndef _STEAMKITDEFINES_H
#define _STEAMKITDEFINES_H

#import <AvailabilityMacros.h>

//
//  Platform specific defs for externs
//

//
// For MACH
//

#if defined(__MACH__)

#ifdef __cplusplus
#define STEAMKIT_EXTERN		extern "C"
#define STEAMKIT_PRIVATE_EXTERN	__private_extern__
#else
#define STEAMKIT_EXTERN				extern
#define STEAMKIT_PRIVATE_EXTERN	__private_extern__
#endif

#if !defined(STEAMKIT_INLINE)
#if defined(__GNUC__)
#define STEAMKIT_INLINE static __inline__ __attribute__((always_inline))
#elif defined(__MWERKS__) || defined(__cplusplus)
#define STEAMKIT_INLINE static inline
#endif
#endif

#if !defined(STEAMKIT_STATIC_INLINE)
#define STEAMKIT_STATIC_INLINE static __inline__
#endif

#if !defined(STEAMKIT_EXTERN_INLINE)
#define STEAMKIT_EXTERN_INLINE extern __inline__
#endif


#endif

#endif // _STEAMKITDEFINES_H
