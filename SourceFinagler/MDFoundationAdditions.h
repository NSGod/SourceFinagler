//
//  MDFoundationAdditions.h
//  MDFoundationAdditions
//
//  Created by Mark Douma on 12/03/2007.
//  Copyright (c) 2007-2011 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>


#if defined(__cplusplus)
#define MDFOUNDATION_EXTERN extern "C"
#else
#define MDFOUNDATION_EXTERN extern
#endif

#if !defined(MD_INLINE)
    #if defined(__GNUC__)
        #define MD_INLINE static __inline__ __attribute__((always_inline))
    #elif defined(__MWERKS__) || defined(__cplusplus)
        #define MD_INLINE static inline
    #elif defined(_MSC_VER)
        #define MD_INLINE static __inline
    #elif TARGET_OS_WIN32
        #define MD_INLINE static __inline__
    #endif
#endif


enum {
	MDUndeterminedVersion	= -1,
	MDCheetah				= 0x1000,
	MDPuma					= 0x1010,
	MDJaguar				= 0x1020,
	MDPanther				= 0x1030,
	MDTiger					= 0x1040,
	MDLeopard				= 0x1050,
	MDSnowLeopard			= 0x1060,
	MDLion					= 0x1070,
	MDMountainLion			= 0x1080,
	MDUnknownKitty			= 0x1090,
	MDUnknownVersion		= 0x1100
};

	
	
MDFOUNDATION_EXTERN BOOL MDMouseInRects(NSPoint inPoint, NSArray *inRects, BOOL isFlipped);
MDFOUNDATION_EXTERN NSString *NSStringForAppleScriptListFromPaths(NSArray *paths);
MDFOUNDATION_EXTERN SInt32 MDGetSystemVersion();
	


//	Bookmark Data Creation Options
//	Options used when creating bookmark data.
//		Constants
//	NSURLBookmarkCreationPreferFileIDResolution
//		Option for specifying that an alias created with the bookmark data prefers resolving with its embedded file ID.
//		Available in Mac OS X v10.6 and later.
//		Declared in NSURL.h.
//		
//	NSURLBookmarkCreationMinimalBookmark
//		Option for specifying that an alias created with the bookmark data be created with minimal information, which may make it smaller but still able to resolve in certain ways.
//		Available in Mac OS X v10.6 and later.
//		Declared in NSURL.h.
//	NSURLBookmarkCreationSuitableForBookmarkFile
//		Option for specifying that the bookmark data include properties required to create Finder alias files.
//		Available in Mac OS X v10.6 and later.
//		Declared in NSURL.h.

enum {
	MDBookmarkCreationDefaultOptions			= 1
};
typedef NSUInteger MDBookmarkCreationOptions;


//	Constants
//	NSURLBookmarkResolutionWithoutUI
//		Option for specifying that no UI feedback accompany resolution of the bookmark data.
//		Available in Mac OS X v10.6 and later.
//		Declared in NSURL.h.
//	NSURLBookmarkResolutionWithoutMounting
//		Option for specifying that no volume should be mounted during resolution of the bookmark data.
//		Available in Mac OS X v10.6 and later.
//		Declared in NSURL.h.
enum {
	MDBookmarkResolutionDefaultOptions		= 1,
	MDBookmarkResolutionWithoutUI = ( 1UL << 8 )
};
typedef NSUInteger MDBookmarkResolutionOptions;


//@interface NSURL (MDAdditions)
//- (BOOL)getFSRef:(FSRef *)anFSRef;
//@end

@interface NSString (MDAdditions)
+ (id)stringByResolvingBookmarkData:(NSData *)bookmarkData options:(MDBookmarkResolutionOptions)options bookmarkDataIsStale:(BOOL *)isStale error:(NSError **)outError;
- (NSData *)bookmarkDataWithOptions:(MDBookmarkCreationOptions)options error:(NSError **)outError;

#if (TARGET_CPU_PPC || TARGET_CPU_X86) && MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
+ (NSString *)stringWithFSSpec:(const FSSpec *)anFSSpec;
#endif

+ (NSString *)stringWithFSRef:(const FSRef *)anFSRef;
- (BOOL)getFSRef:(FSRef *)anFSRef error:(NSError **)anError;
- (BOOL)boolValue;
- (NSString *)stringByAssuringUniqueFilename;
- (NSString *)stringByAbbreviatingFilenameTo31Characters;
- (NSSize)sizeForStringWithSavedFrame;
+ (NSString *)stringWithPascalString:(ConstStr255Param)aPStr;
//- (BOOL)getFSSpec:(FSSpec *)anFSSpec;
- (BOOL)pascalString:(StringPtr)aBuffer length:(SInt16)aLength;

- (NSComparisonResult)caseInsensitiveNumericalCompare:(NSString *)string;
- (NSComparisonResult)localizedCaseInsensitiveNumericalCompare:(NSString *)string;

- (BOOL)containsString:(NSString *)aString;

- (NSString *)stringByReplacing:(NSString *)value with:(NSString *)newValue;
- (NSString *)slashToColon;
- (NSString *)colonToSlash;

- (NSString *)displayPath;

@end


@interface NSUserDefaults (MDSortDescriptorAdditions)

- (void)setSortDescriptors:(NSArray *)sortDescriptors forKey:(NSString *)key;
- (NSArray *)sortDescriptorsForKey:(NSString *)key;

@end

@interface NSDictionary (MDSortDescriptorAdditions)

- (NSArray *)sortDescriptorsForKey:(NSString *)key;

@end

@interface NSMutableDictionary (MDSortDescriptorAdditions)

- (void)setSortDescriptors:(NSArray *)sortDescriptors forKey:(NSString *)key;

@end



@interface NSData (MDDescriptionAdditions)

- (NSString *)stringRepresentation;
- (NSString *)enhancedDescription;

@end


//#if !defined(TEXTUREKIT_EXTERN)
//
//@interface NSData (MDAdditions)
//- (NSString *)sha1HexHash;
//- (NSData *)sha1Hash;
//
//
//@end
//
//@interface NSBundle (MDAdditions)
//- (NSString *)checksumForAuxiliaryLibrary:(NSString *)dylibName;
//@end
//#endif


////////////////////////////////////////////////////////////////
////    NSMutableDictionary CATEGORY FOR THREAD-SAFETY
////////////////////////////////////////////////////////////////

//@interface NSMutableDictionary (MDThreadSafety)
//
//- (id)threadSafeObjectForKey:(id)aKey usingLock:(NSLock *)aLock;
//
//- (void)threadSafeRemoveObjectForKey:(id)aKey usingLock:(NSLock *)aLock;
//
//- (void)threadSafeSetObject:(id)anObject forKey:(id)aKey usingLock:(NSLock *)aLock;
//
//@end


//@interface NSArray (MDAdditions)
//- (BOOL)containsObjectIdenticalTo:(id)object;
//@end
//
@interface NSMutableArray (MDAdditions)
- (void)insertObjectsFromArray:(NSArray *)array atIndex:(NSUInteger)anIndex;
@end


@interface NSObject (MDDeepMutableCopy)
- (id)deepMutableCopy NS_RETURNS_RETAINED;
@end



