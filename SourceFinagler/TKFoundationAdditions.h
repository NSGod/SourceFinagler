//
//  TKFoundationAdditions.h
//  TKFoundationAdditions
//
//  Created by Mark Douma on 12/03/2007.
//  Copyright (c) 2007-2011 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>


#if defined(__cplusplus)
#define TKFOUNDATION_EXTERN extern "C"
#else
#define TKFOUNDATION_EXTERN extern
#endif

#if !defined(TK_INLINE)
    #if defined(__GNUC__)
        #define TK_INLINE static __inline__ __attribute__((always_inline))
    #elif defined(__MWERKS__) || defined(__cplusplus)
        #define TK_INLINE static inline
    #elif defined(_MSC_VER)
        #define TK_INLINE static __inline
    #elif TARGET_OS_WIN32
        #define TK_INLINE static __inline__
    #endif
#endif


enum {
	TKUndeterminedVersion	= 0,
	TKCheetah				= 0x1000,
	TKPuma					= 0x1010,
	TKJaguar				= 0x1020,
	TKPanther				= 0x1030,
	TKTiger					= 0x1040,
	TKLeopard				= 0x1050,
	TKSnowLeopard			= 0x1060,
	TKLion					= 0x1070,
	TKMountainLion			= 0x1080,
	TKMavericks				= 0x1090,
	TKUnknownVersion		= 0x1100
};

TKFOUNDATION_EXTERN SInt32 TKGetSystemVersion();




@interface NSString (TKAdditions)


+ (NSString *)stringWithFSRef:(const FSRef *)anFSRef;
- (BOOL)getFSRef:(FSRef *)anFSRef error:(NSError **)anError;

- (NSString *)stringByAssuringUniqueFilename;

+ (NSString *)stringWithPascalString:(ConstStr255Param)aPStr;
- (BOOL)pascalString:(StringPtr)aBuffer length:(SInt16)aLength;

- (NSComparisonResult)caseInsensitiveNumericalCompare:(NSString *)string;
- (NSComparisonResult)localizedCaseInsensitiveNumericalCompare:(NSString *)string;

- (NSString *)stringByReplacing:(NSString *)value with:(NSString *)newValue;
- (NSString *)slashToColon;
- (NSString *)colonToSlash;

- (NSString *)displayPath;

@end



@interface NSUserDefaults (TKSortDescriptorAdditions)
- (void)setSortDescriptors:(NSArray *)sortDescriptors forKey:(NSString *)key;
- (NSArray *)sortDescriptorsForKey:(NSString *)key;
@end

@interface NSDictionary (TKSortDescriptorAdditions)
- (NSArray *)sortDescriptorsForKey:(NSString *)key;
@end

@interface NSMutableDictionary (TKSortDescriptorAdditions)
- (void)setSortDescriptors:(NSArray *)sortDescriptors forKey:(NSString *)key;
@end



@interface NSIndexSet (TKAdditions)
+ (id)indexSetWithIndexSet:(NSIndexSet *)indexes;
- (NSIndexSet *)indexesIntersectingIndexes:(NSIndexSet *)indexes;
@end


@interface NSMutableIndexSet (TKAdditions)
- (void)setIndexes:(NSIndexSet *)indexes;
@end


@interface NSData (TKDescriptionAdditions)
- (NSString *)stringRepresentation;
- (NSString *)enhancedDescription;
@end



@interface NSMutableArray (TKAdditions)
- (void)insertObjectsFromArray:(NSArray *)array atIndex:(NSUInteger)anIndex;
@end




@interface NSObject (TKDeepMutableCopy)
- (id)deepMutableCopy NS_RETURNS_RETAINED;
@end


