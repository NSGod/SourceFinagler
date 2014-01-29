//
//  MDResource.m
//  Font Finagler
//
//  Created by Mark Douma on 11/17/2008.
//  Copyright © 2008 Mark Douma. All rights reserved.
//


#import "MDResource.h"
#import "MDFoundationAdditions.h"


#define MD_DEBUG 0

@implementation MDResource

+ (id)resourceWithType:(ResType)aType index:(ResourceIndex)anIndex error:(NSError **)outError {
	return [[[[self class] alloc] initWithType:aType index:anIndex error:outError] autorelease];
}


- (id)initWithType:(ResType)aType index:(ResourceIndex)anIndex error:(NSError **)outError {
	if ((self = [super init])) {
		if (outError) *outError = nil;
		resourceType		= aType;
		resourceIndex		= anIndex;
		if (![self getResourceInfo:outError]) {
			NSLog(@"[%@ %@] *** ERROR: [self getResourceInfo:] failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			[self release];
			return nil;
		}
		if (![self parseResourceData:outError]) {
			NSLog(@"[%@ %@] *** ERROR: [self parseResourceData:] failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			[self release];
			return nil;
		}
	}
	return self;
}

- (id)initWithType:(ResType)aType resourceData:(NSData *)aData resourceID:(ResID)anID resourceName:(NSString *)aName resourceIndex:(ResourceIndex)anIndex resourceAttributes:(ResAttributes)anAttributes resChanged:(BOOL)aResChanged copy:(BOOL)shouldCopy error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		if (outError) *outError = nil;
		resourceType		= aType;
		resourceIndex		= anIndex;
		resourceID			= anID;
		
		if (shouldCopy) {
			resourceName	= [aName copy];
			resourceData	= [aData copy];
		} else {
			resourceName	= [aName retain];
			resourceData	= [aData retain];
		}

		resourceSize		= [resourceData length];
		resourceAttributes	= anAttributes;
		resChanged			= aResChanged;
		
		if (![self parseResourceData:outError]) {
			NSLog(@"[%@ %@] *** ERROR: [self parseResourceData:] failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			[self release];
			return nil;
		}
	}
	return self;
}


- (void)dealloc {
	[resourceName release];
	[resourceData release];
	[super dealloc];
}

- (ResType)resourceType {
    return resourceType;
}

- (void)setResourceType:(ResType)value {
	resourceType = value;
	[self setResChanged:YES];
}

- (ResID)resourceID {
    return resourceID;
}

- (void)setResourceID:(ResID)value {
	resourceID = value;
	resChanged = YES;
}

- (NSString *)resourceName {
	return resourceName;
}

- (void)setResourceName:(NSString *)value {
	[value retain];
	[resourceName release];
	resourceName = value;
	resChanged = YES;
}

- (NSData *)resourceData {
	return resourceData;
}

- (void)setResourceData:(NSData *)value {
	[value retain];
	[resourceData release];
	resourceData = value;
	resourceSize = (SInt32)[resourceData length];
	resChanged = YES;
}


- (SInt32)resourceSize {
    return resourceSize;
}

- (void)setResourceSize:(SInt32)value {
	resourceSize = value;
	[self setResChanged:YES];
}

- (ResourceIndex)resourceIndex {
    return resourceIndex;
}

- (void)setResourceIndex:(ResourceIndex)value {
	resourceIndex = value;
	[self setResChanged:YES];
}


- (ResAttributes)resourceAttributes {
    return resourceAttributes;
}

- (void)setResourceAttributes:(ResAttributes)value {
	resourceAttributes = value;
	[self setResChanged:YES];
}


- (BOOL)resChanged {
    return resChanged;
}

- (void)setResChanged:(BOOL)value {
	resChanged = value;
}

- (BOOL)getResourceInfo:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	ResID resID = 0;
	ResType resType;
	Str255 resName;
	
	Handle resHandle = Get1IndResource(resourceType, resourceIndex);
	OSErr err = ResError();
	if ( !(err == noErr && resHandle)) {
		NSLog(@"[%@ %@] ERROR: Get1Resource() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
		if (outError) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		return NO;
	}
	
	GetResInfo(resHandle, &resID, &resType, resName);
	err = ResError();
	if (err != noErr) {
		NSLog(@"[%@ %@] ERROR: GetResInfo() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
		if (outError) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		ReleaseResource(resHandle);
		return NO;
	}
	
	resourceID = resID;
	resourceName = [[NSString stringWithPascalString:resName] retain];
	
	resourceSize = GetResourceSizeOnDisk(resHandle);
	err = ResError();
	if (err != noErr) {
		NSLog(@"[%@ %@] ERROR: ResError() for GetResourceSizeOnDisk() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
		if (outError) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		ReleaseResource(resHandle);
		return NO;
	}
	
	HLock(resHandle);
	resourceData = [[NSData dataWithBytes:*resHandle length:GetHandleSize(resHandle)] retain];
	HUnlock(resHandle);
	
	resourceAttributes = GetResAttrs(resHandle);
	err = ResError();
	if (err != noErr) {
		NSLog(@"[%@ %@] ERROR: ResError() for GetResAttrs() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
		if (outError) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		ReleaseResource(resHandle);
		return NO;
	}
	
	ReleaseResource(resHandle);
	err = ResError();
	if (err != noErr) {
		NSLog(@"[%@ %@] ERROR: ResError() for GetResAttrs() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
		if (outError) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		return NO;
	}
	return YES;
}


/*	subclasses should override */

- (BOOL)parseResourceData:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return YES;
}


@end

