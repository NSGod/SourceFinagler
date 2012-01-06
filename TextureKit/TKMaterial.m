//
//  TKMaterial.m
//  Texture Kit
//
//  Created by Mark Douma on 1/17/2011.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKMaterial.h>
#import <Cocoa/Cocoa.h>
#import <TextureKit/TKVMTNode.h>


#define TK_DEBUG 1

@implementation TKMaterial

@synthesize rootNode;


+ (id)materialWithContentsOfFile:(NSString *)aPath error:(NSError **)outError {
	return [[[[self class] alloc] initWithContentsOfFile:aPath error:outError] autorelease];
}


+ (id)materialWithContentsOfURL:(NSURL *)URL error:(NSError **)outError {
	return [[(TKMaterial *)[[self class] alloc] initWithContentsOfURL:URL error:outError] autorelease];
}


+ (id)materialWithData:(NSData *)aData error:(NSError **)outError {
	return [[[[self class] alloc] initWithData:aData error:outError] autorelease];
}


- (id)initWithContentsOfFile:(NSString *)aPath error:(NSError **)outError {
	return [self initWithContentsOfURL:[NSURL fileURLWithPath:aPath] error:outError];
}


- (id)initWithContentsOfURL:(NSURL *)URL error:(NSError **)outError {
	return [self initWithData:[NSData dataWithContentsOfURL:URL] error:outError];
}


- (id)initWithData:(NSData *)aData error:(NSError **)outError {
	NSParameterAssert(aData != nil);
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
	return nil;
}


- (NSDictionary *)dictionaryRepresentation {
	return nil;
}


- (NSString *)stringRepresentation {
	return nil;
}


@end




