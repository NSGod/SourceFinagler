//
//  TKTexture.m
//  Texture Kit
//
//  Created by Mark Douma on 1/7/2011.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//



#import <TextureKit/TKTexture.h>
#import <OpenGL/glu.h>

#import <TextureKit/TKDDSImageRep.h>
#import <TextureKit/TKVTFImageRep.h>


#define TK_DEBUG 1



@implementation TKTexture

@synthesize name;



+ (id)textureWithContentsOfFile:(NSString *)aPath {
	return [[[[self class] alloc] initWithContentsOfFile:aPath] autorelease];
}


+ (id)textureWithData:(NSData *)aData {
	return [[[[self class] alloc] initWithData:aData] autorelease];
}


- (id)initWithContentsOfFile:(NSString *)aPath {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSData *aData = [NSData dataWithContentsOfFile:aPath];
	if (aData) {
		return [self initWithData:aData];
	}
	return nil;
}


- (id)initWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (self = [super init]) {
		
	}
	
	return self;
}


- (void)dealloc {
	glDeleteTextures(1, &name);
	glDeleteBuffers(1, &pixelBuffer);
	[super dealloc];
}







@end
