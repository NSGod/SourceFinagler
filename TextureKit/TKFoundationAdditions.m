//
//  TKFoundationAdditions.m
//  Texture Kit
//
//  Created by Mark Douma on 12/25/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import "TKFoundationAdditions.h"
#import <CoreServices/CoreServices.h>
#import <sys/syslimits.h>

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


@implementation NSString (TKAdditions)

- (BOOL)getFSRef:(FSRef *)anFSRef error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (outError) *outError = nil;
	OSStatus status = noErr;
	status = FSPathMakeRef((const UInt8 *)[self UTF8String], anFSRef, NULL);
	if (status != noErr) {
		if (outError) {
			if (status == fnfErr) {
				*outError = [NSError errorWithDomain:NSCocoaErrorDomain	code:NSFileNoSuchFileError userInfo:nil];
				
			} else {
				*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
			}
		}
	}
	return (status == noErr);
}


@end






