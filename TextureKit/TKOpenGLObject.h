//
//  TKOpenGLObject.h
//  Texture Kit
//
//  Created by Mark Douma on 1/7/2011.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//


#import <TextureKit/TKOpenGLBase.h>
#import <Foundation/NSObject.h>


@interface TKOpenGLObject : NSObject {
	NSRecursiveLock			*nameLock;
	
	GLuint					name;
	
	BOOL					generatedName;
	
}


@property (readonly, assign) GLuint name;

//@property (readonly, nonatomic, assign) GLuint name;

- (void)generateName;


@end



