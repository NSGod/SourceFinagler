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


MDFOUNDATION_EXTERN NSString *NSStringForAppleScriptListFromPaths(NSArray *paths);

enum {
	MDCheetah				= 0,
	MDPuma					= 1,
	MDJaguar				= 2,
	MDPanther				= 3,
	MDTiger					= 4,
	MDLeopard				= 5,
	MDSnowLeopard			= 6,
	MDLion					= 7,
	MDMountainLion			= 8,
	MDMavericks				= 9,
	MDYosemite				= 10,
	MDElCapitan				= 11,
	MDUnknownVersion		= 12,
};

typedef struct {
    NSInteger majorVersion;
    NSInteger minorVersion;
    NSInteger patchVersion;
} MDOperatingSystemVersion;


MDFOUNDATION_EXTERN BOOL MDOperatingSystemVersionLessThan(MDOperatingSystemVersion osVersion, MDOperatingSystemVersion referenceVersion);
MDFOUNDATION_EXTERN BOOL MDOperatingSystemVersionGreaterThanOrEqual(MDOperatingSystemVersion osVersion, MDOperatingSystemVersion referenceVersion);


@interface NSProcessInfo (MDAdditions)

- (MDOperatingSystemVersion)md__operatingSystemVersion;

@end



@interface NSString (MDFoundationAdditions)

+ (NSString *)stringWithFSRef:(const FSRef *)anFSRef;
- (BOOL)getFSRef:(FSRef *)anFSRef error:(NSError **)anError;

- (NSString *)stringByAssuringUniqueFilename;

+ (NSString *)stringWithPascalString:(ConstStr255Param)aPStr;
- (BOOL)pascalString:(StringPtr)aBuffer length:(SInt16)aLength;

- (NSComparisonResult)md__caseInsensitiveNumericalCompare:(NSString *)string;
- (NSComparisonResult)md__localizedCaseInsensitiveNumericalCompare:(NSString *)string;

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



@interface NSIndexSet (MDFoundationAdditions)
+ (id)indexSetWithIndexSet:(NSIndexSet *)indexes;
- (NSIndexSet *)indexesIntersectingIndexes:(NSIndexSet *)indexes;
@end


@interface NSMutableIndexSet (MDFoundationAdditions)
- (void)setIndexes:(NSIndexSet *)indexes;
@end


@interface NSData (MDDescriptionAdditions)

- (NSString *)stringRepresentation;
- (NSString *)enhancedDescription;

- (NSString *)enhancedFloatDescriptionForComponentCount:(NSUInteger)numComponents; // R32F = 1, RGB32F = 3, RGBA32F = 4

@end



@interface NSMutableArray (MDFoundationAdditions)
- (void)insertObjectsFromArray:(NSArray *)array atIndex:(NSUInteger)anIndex;
@end




@interface NSObject (MDDeepMutableCopy)
- (id)deepMutableCopy NS_RETURNS_RETAINED;
@end


