//
//  MDAlias.m
//  Source Finagler
//
//  Created by Mark Douma on 10/23/2006.
//  Copyright © 2006 Mark Douma. All rights reserved.
//



#import "MDAlias.h"
#import "MDFoundationAdditions.h"


@implementation MDAlias

+ (id)aliasWithAlias:(AliasHandle)anAlias {
	return [[[[self class] alloc] initWithAlias:anAlias] autorelease];
}


+ (id)aliasWithPath:(NSString *)aPath {
	return [[[[self class] alloc] initWithPath:aPath] autorelease];
}


+ (id)aliasWithData:(NSData *)data {
	return [[[[self class] alloc] initWithData:data] autorelease];
}


- (id)initWithAlias:(AliasHandle)anAlias {
	if (self = [super init]) {
		alias = anAlias;
	}
	return self;
}


- (id)initWithPath:(NSString *)aPath {
	if (aPath) {
		AliasHandle anAlias = NULL;
		OSErr err = noErr;
		FSRef fileRef;
		
		if ([aPath getFSRef:&fileRef error:NULL]) {
			err = FSNewAlias(NULL, &fileRef, &anAlias);
			
			if (err != noErr) {
				return nil;
			}
		}
		return [self initWithAlias:anAlias];
	}
	NSLog(@"[%@ %@] WARNING: aPath == nil; returning nil", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	return nil;
}


- (id)initWithData:(NSData *)data {
	if (self = [super init]) {
		if (data && PtrToHand([data bytes], (Handle *)&alias, [data length]) == noErr) {
			
		} else {
			[self release];
			return nil;
		}
	}
	return self;
}



- (void)dealloc {
	if (alias != NULL) {
		DisposeHandle((Handle)alias);
		alias = NULL;
	}
	[super dealloc];
}


- (NSData *)aliasData {
	NSData *aliasData = nil;
	
	HLock((Handle)alias);
	aliasData = [[[NSData dataWithBytes:*alias length:GetHandleSize((Handle)alias)] retain] autorelease];
	HUnlock((Handle)alias);
	
	return aliasData;
}


- (AliasHandle)alias {
	return alias;
}


- (NSString *)filePath {
	NSString *filePath = nil;
	FSRef resolvedRef;
	
	OSErr err = noErr;
	Boolean wasChanged;
	
	if (alias != NULL) {
		
		err = FSResolveAlias(NULL, alias, &resolvedRef, &wasChanged);
		
		if (err != noErr) {
			NSLog(@"[%@ %@] FSResolveAlias() returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
			return filePath;
		}
		
		filePath = [NSString stringWithFSRef:&resolvedRef];
		
	}
	
	return filePath;
}



@end








