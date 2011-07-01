//
//  TKTexture.h
//  Texture Kit
//
//  Created by Mark Douma on 1/7/2011.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TKTexture : NSObject {
	GLuint		name;
	GLuint		pixelBuffer;
	GLubyte		*bytes;
}

+ (id)textureWithContentsOfFile:(NSString *)aPath;
+ (id)textureWithData:(NSData *)aData;

- (id)initWithContentsOfFile:(NSString *)aPath;
- (id)initWithData:(NSData *)aData;



@property (nonatomic, assign, readonly) GLuint name;

@end
