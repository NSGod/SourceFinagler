//
//  TKOBJParts.m
//  Texture Kit
//
//  Created by Mark Douma on 12/8/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKOBJParts.h>


NSString * const TKOBJVertexKey				= @"v";
NSString * const TKOBJTextureVertexKey		= @"vt";
NSString * const TKOBJVertexNormalKey		= @"vn";


@implementation TKOBJVertex

@synthesize vertex;

+ (id)vertexWithString:(NSString *)string {
	return [[[[self class] alloc] initWithString:string] autorelease];
}

- (id)initWithString:(NSString *)string {
	NSParameterAssert([string hasPrefix:TKOBJVertexKey]);
	
	if ((self = [super init])) {
		NSMutableString *mString = [NSMutableString stringWithString:string];
		[mString replaceOccurrencesOfString:TKOBJVertexKey withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mString length])];
		
		float x = 0;
		float y = 0;
		float z = 0;
		
		NSScanner *scanner = [NSScanner scannerWithString:mString];
		
		[scanner scanFloat:&x];
		[scanner scanFloat:&y];
		[scanner scanFloat:&z];
		
		vertex = TKVector3Make(x, y, z);
		
	}
	return self;
}

+ (NSData *)dataWithVerticesInArray:(NSArray *)vertices {
	NSParameterAssert(vertices != nil);
	
	NSMutableData *mData = [NSMutableData data];
	
	for (TKOBJVertex *vertex in vertices) {
		TKVector3 v = [vertex vertex];
		[mData appendBytes:&v.v length:sizeof(TKVector3)];
	}
	return [[mData copy] autorelease];
}

@end


@implementation TKOBJTextureVertex

@synthesize textureVertex;

+ (id)textureVertexWithString:(NSString *)string {
	return [[[[self class] alloc] initWithString:string] autorelease];
}


- (id)initWithString:(NSString *)string {
	NSParameterAssert([string hasPrefix:TKOBJTextureVertexKey]);
	
	if ((self = [super init])) {
		NSMutableString *mString = [NSMutableString stringWithString:string];
		[mString replaceOccurrencesOfString:TKOBJTextureVertexKey withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mString length])];
		float s = 0;
		float t = 0;
		
		NSScanner *scanner = [NSScanner scannerWithString:mString];
		
		[scanner scanFloat:&s];
		[scanner scanFloat:&t];
		
		textureVertex = TKVector2Make(s, t);
	}
	return self;
}


+ (NSData *)dataWithTextureVerticesInArray:(NSArray *)textureVertices {
	NSParameterAssert(textureVertices != nil);
	
	NSMutableData *mData = [NSMutableData data];
	
	for (TKOBJTextureVertex *textureVertex in textureVertices) {
		TKVector2 v = [textureVertex textureVertex];
		[mData appendBytes:&v.v length:sizeof(TKVector2)];
	}
	return [[mData copy] autorelease];
}

@end



@implementation TKOBJVertexNormal

@synthesize vertexNormal;

+ (id)vertexNormalWithString:(NSString *)string {
	return [[[[self class] alloc] initWithString:string] autorelease];
}

- (id)initWithString:(NSString *)string {
	NSParameterAssert([string hasPrefix:TKOBJVertexNormalKey]);
	
	if ((self = [super init])) {
		NSMutableString *mString = [NSMutableString stringWithString:string];
		[mString replaceOccurrencesOfString:TKOBJVertexNormalKey withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mString length])];
		
		float x = 0;
		float y = 0;
		float z = 0;
		
		NSScanner *scanner = [NSScanner scannerWithString:mString];
		
		[scanner scanFloat:&x];
		[scanner scanFloat:&y];
		[scanner scanFloat:&z];
		
		vertexNormal = TKVector3Make(x, y, z);
	}
	return self;
}

+ (NSData *)dataWithVertexNormalsInArray:(NSArray *)vertexNormals {
	NSParameterAssert(vertexNormals != nil);
	
	NSMutableData *mData = [NSMutableData data];
	
	for (TKOBJVertexNormal *vertexNormal in vertexNormals) {
		TKVector3 v = [vertexNormal vertexNormal];
		[mData appendBytes:&v.v length:sizeof(TKVector3)];
	}
	return [[mData copy] autorelease];
}


@end



@implementation TKOBJTriplet

@synthesize vertex;
@synthesize textureVertex;
@synthesize vertexNormal;


+ (id)tripletWithVertex:(TKOBJVertex *)aVertex textureVertex:(TKOBJTextureVertex *)aTextureVertex vertexNormal:(TKOBJVertexNormal *)aVertexNormal {
	return [[[[self class] alloc] initWithVertex:aVertex textureVertex:aTextureVertex vertexNormal:aVertexNormal] autorelease];
}


- (id)initWithVertex:(TKOBJVertex *)aVertex textureVertex:(TKOBJTextureVertex *)aTextureVertex vertexNormal:(TKOBJVertexNormal *)aVertexNormal {
	if ((self = [super init])) {
		vertex = [aVertex retain];
		textureVertex = [aTextureVertex retain];
		vertexNormal = [aVertexNormal retain];
	}
	return self;
}


- (void)dealloc {
	[vertex release];
	[textureVertex release];
	[vertexNormal release];
	[super dealloc];
}


@end


@implementation TKOBJFace




@end








