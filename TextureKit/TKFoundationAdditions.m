//
//  TKFoundationAdditions.m
//  Texture Kit
//
//  Created by Mark Douma on 12/25/2010.
//  Copyright (c) 2010-2014 Mark Douma LLC. All rights reserved.
//

#import "TKFoundationAdditions.h"


#define TK_DEBUG 0

@implementation NSObject (TKDeepMutableCopy)

- (id)deepMutableCopy {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
    if ([self respondsToSelector:@selector(mutableCopyWithZone:)]) {
        return [self mutableCopy];
	} else if ([self respondsToSelector:@selector(copyWithZone:)]) {
        return [self copy];
	} else {
        return [self retain];
	}
}

@end

@implementation NSDictionary (TKDeepMutableCopy)

- (id)deepMutableCopy {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    NSMutableDictionary *newDictionary = [[NSMutableDictionary alloc] init];
	id key = nil;
	
	NSArray *allKeys = [self allKeys];
	
	for (key in allKeys) {
		id copiedObject = [[self objectForKey:key] deepMutableCopy];
		
		id keyCopy = nil;
		
		if ([key conformsToProtocol:@protocol(NSCopying)]) {
			keyCopy = [key copy];
		} else {
			keyCopy = [key retain];
		}
		
		[newDictionary setObject:copiedObject forKey:keyCopy];
		[copiedObject release];
		[keyCopy release];
	}	
    return newDictionary;
}

@end



@implementation NSArray (TKDeepMutableCopy)

- (id)deepMutableCopy {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    NSMutableArray *newArray = [[NSMutableArray alloc] init];
	
	for (id object in self) {
		id copiedObject = [object deepMutableCopy];
		[newArray addObject:copiedObject];
		[copiedObject release];
	}
    return newArray;
}
	
@end



@implementation NSSet (TKDeepMutableCopy)

- (id)deepMutableCopy {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    NSMutableSet *newSet = [[NSMutableSet alloc] init];
	
	NSArray *allObjects = [self allObjects];
	
	for (id object in allObjects) {
		id copiedObject = [object deepMutableCopy];
		[newSet addObject:copiedObject];
		[copiedObject release];
	}
    return newSet;
}
	
@end





BOOL TKOperatingSystemVersionLessThan(TKOperatingSystemVersion osVersion, TKOperatingSystemVersion referenceVersion) {
	if (osVersion.majorVersion != referenceVersion.majorVersion) {
		return osVersion.majorVersion < referenceVersion.majorVersion;
	}
	if (osVersion.minorVersion != referenceVersion.minorVersion) {
		return osVersion.minorVersion < referenceVersion.minorVersion;
	}
	return osVersion.patchVersion < referenceVersion.patchVersion;
}


BOOL TKOperatingSystemVersionGreaterThanOrEqual(TKOperatingSystemVersion osVersion, TKOperatingSystemVersion referenceVersion) {
	if (osVersion.majorVersion != referenceVersion.majorVersion) {
		return osVersion.majorVersion > referenceVersion.majorVersion;
	}
	if (osVersion.minorVersion != referenceVersion.minorVersion) {
		return osVersion.minorVersion > referenceVersion.minorVersion;
	}
	return osVersion.patchVersion >= referenceVersion.patchVersion;
}



@implementation NSProcessInfo (TKAdditions)


- (TKOperatingSystemVersion)tk__operatingSystemVersion {
	static BOOL initialized = NO;
	static TKOperatingSystemVersion operatingSystemVersion = {0, 0, 0};
	
	if (initialized == NO) {
		SInt32 majorVersion = 0;
		SInt32 minorVersion = 0;
		SInt32 patchVersion = 0;
		
		OSErr err = Gestalt(gestaltSystemVersionMajor, &majorVersion);
		err |= Gestalt(gestaltSystemVersionMinor, &minorVersion);
		err |= Gestalt(gestaltSystemVersionBugFix, &patchVersion);
		
		if (err) {
			NSLog(@"[%@ %@] Gestalt() returned == %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (int)err);
		}
		
		operatingSystemVersion.majorVersion = majorVersion;
		operatingSystemVersion.minorVersion = minorVersion;
		operatingSystemVersion.patchVersion = patchVersion;
		
		initialized = YES;
	}
	
	return operatingSystemVersion;
}


@end

