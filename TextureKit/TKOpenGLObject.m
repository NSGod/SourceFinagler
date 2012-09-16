//
//  TKOpenGLObject.m
//  Texture Kit
//
//  Created by Mark Douma on 1/7/2011.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//


#import <TextureKit/TKOpenGLObject.h>

#define TK_DEBUG 1


@implementation TKOpenGLObject

//@synthesize name;

@dynamic name;

- (id)init {
	if ((self = [super init])) {
		nameLock = [[NSRecursiveLock alloc] init];
	}
	return self;
}


- (void)dealloc {
	[nameLock release];
	[super dealloc];
}



- (GLuint)name {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[nameLock lock];
	if (generatedName == NO) [self generateName];
	[nameLock unlock];
	return name;
}


- (void)generateName {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
//	[nameLock lock];
//	if (generatedName) {
//		[nameLock unlock];
//		return;
//	}
//	
//	
//	generatedName = YES;
//	[nameLock unlock];
}



@end






