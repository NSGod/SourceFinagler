//
//  TKTexture.m
//  Texture Kit
//
//  Created by Mark Douma on 1/7/2011.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//


#import <TextureKit/TKTexture.h>

#import <TextureKit/TKImage.h>
#import <TextureKit/TKImageRep.h>
#import <TextureKit/TKDDSImageRep.h>
#import <TextureKit/TKVTFImageRep.h>

#import <TextureKit/TKDDSTexture.h>
#import <TextureKit/TKVTFTexture.h>


#define TK_DEBUG 1


typedef struct TKPixelFormatMapping {
	TKPixelFormat			tkPixelFormat;
	TKPixelFormat			tkNativePixelFormat;
	GLenum					pixelFormat;
	GLenum					dataType;
} TKPixelFormatMapping;

static const TKPixelFormatMapping TKPixelFormatMappingTable[] = {
	{TKPixelFormatXRGB1555,			TKPixelFormatRGBX5551,	GL_RGBA,				GL_UNSIGNED_SHORT_5_5_5_1},
	{TKPixelFormatL,				0,						GL_RED,					GL_UNSIGNED_BYTE},
	{TKPixelFormatLA,				0,						GL_RG,					GL_UNSIGNED_BYTE},
	{TKPixelFormatA,				0,						GL_ALPHA,				GL_UNSIGNED_BYTE},
	{TKPixelFormatRGB,				0,						GL_RGB,					GL_UNSIGNED_BYTE},
	{TKPixelFormatXRGB,				TKPixelFormatRGBA,		GL_RGBA,				GL_UNSIGNED_BYTE},
	{TKPixelFormatRGBX,				TKPixelFormatRGBA,		GL_RGBA,				GL_UNSIGNED_BYTE},
	{TKPixelFormatARGB,				TKPixelFormatRGBA,		GL_RGBA,				GL_UNSIGNED_BYTE},
	{TKPixelFormatRGBA,				0,						GL_RGBA,				GL_UNSIGNED_BYTE},
	{TKPixelFormatRGB161616,		0,						GL_RGB,					GL_UNSIGNED_SHORT},
	{TKPixelFormatRGBA16161616,		0,						GL_RGBA,				GL_UNSIGNED_SHORT},
	{TKPixelFormatL32F,				0,						GL_RED,					GL_FLOAT},
	{TKPixelFormatRGB323232F,		0,						GL_RGB,					GL_FLOAT},
	{TKPixelFormatRGBA32323232F,	0,						GL_RGBA,				GL_FLOAT},
	{TKPixelFormatRGB565,			0,						GL_RGB,					GL_UNSIGNED_SHORT_5_6_5},
	{TKPixelFormatBGR565,			0,						GL_BGR,					GL_UNSIGNED_SHORT_5_6_5},
	{TKPixelFormatBGRX5551,			0,						GL_BGRA,				GL_UNSIGNED_SHORT_5_5_5_1},
	{TKPixelFormatBGRA5551,			0,						GL_BGRA,				GL_UNSIGNED_SHORT_5_5_5_1},
	{TKPixelFormatBGRA,				0,						GL_BGRA,				GL_UNSIGNED_BYTE},
	{TKPixelFormatRGBA16161616F,	0,						GL_RGBA,				GL_HALF_FLOAT}
};
static const NSUInteger TKPixelFormatMappingTableCount = sizeof(TKPixelFormatMappingTable)/sizeof(TKPixelFormatMappingTable[0]);

static inline TKPixelFormatMapping TKPixelFormatMappingForPixelFormat(TKPixelFormat tkPixelFormat) {
	for (NSUInteger i = 0; i < TKPixelFormatMappingTableCount; i++) {
		if (TKPixelFormatMappingTable[i].tkPixelFormat == tkPixelFormat) {
			TKPixelFormatMapping formatMapping = TKPixelFormatMappingTable[i];
			return formatMapping;
		}
	}
	TKPixelFormatMapping formatMapping = {TKPixelFormatUnknown, 0, 0, 0};
	return formatMapping;
}



@implementation TKTexture

//@dynamic name;

//@synthesize name;

@synthesize data;
@synthesize size;
@synthesize width;
@synthesize height;
@synthesize pixelFormat;
@synthesize dataType;
@synthesize rowByteSize;


+ (id)textureWithContentsOfFile:(NSString *)aPath {
	return [[[[self class] alloc] initWithContentsOfFile:aPath] autorelease];
}


+ (id)textureWithContentsOfURL:(NSURL *)URL {
	return [[[[self class] alloc] initWithContentsOfURL:URL] autorelease];
}


+ (id)textureWithData:(NSData *)aData {
	return [[[[self class] alloc] initWithData:aData] autorelease];
}


+ (id)textureNamed:(NSString *)name {
	NSString *fullPath = [[NSBundle mainBundle] pathForImageResource:name];
	if (fullPath == nil) return nil;
	return [[[[self class] alloc] initWithContentsOfFile:fullPath] autorelease];
}


- (id)initWithContentsOfFile:(NSString *)aPath {
	return [self initWithContentsOfURL:[NSURL fileURLWithPath:aPath]];
}


- (id)initWithContentsOfURL:(NSURL *)URL {
	return [self initWithData:[NSData dataWithContentsOfURL:URL]];
}


- (id)initWithData:(NSData *)aData {
	NSParameterAssert(aData != nil);
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([aData length] < [TKSFTextureImageMagicData length]) {
		NSLog(@"[%@ %@] NOTICE: [aData length] < [TKSFTextureImageMagicData length]!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return nil;
	}
	
	NSData *magic8Data = [aData subdataWithRange:NSMakeRange(0, [TKSFTextureImageMagicData length])];
	
	if ([magic8Data isEqualToData:TKSFTextureImageMagicData]) {
		// TKImage
		
		
	} else {
		
		OSType magic = 0;
		[aData getBytes:&magic length:sizeof(magic)];
		magic = NSSwapBigIntToHost(magic);
		
		if (magic == TKVTFMagic) {
			TKVTFTexture *vtfTexture = [[TKVTFTexture alloc] initWithData:aData];
			[self release];
			self = (TKTexture *)vtfTexture;
			
			[self generateName];
			
			return self;
			
		} else if (magic == TKDDSMagic) {
			TKDDSTexture *ddsTexture = [[TKDDSTexture alloc] initWithData:aData];
			[self release];
			self = (TKTexture *)ddsTexture;
			
			[self generateName];

			return self;
			
		} else {
			if ((self = [super init])) {
				// TKImageRep
				TKImageRep *imageRep = [TKImageRep imageRepWithData:aData];
				if (imageRep == nil) {
					NSLog(@"[%@ %@] [TKImageRep imageRepWithData:] returned nil!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
					return nil;
				}
				
				width = [imageRep pixelsWide];
				height = [imageRep pixelsHigh];
				
				TKPixelFormat tkPixelFormat = [imageRep pixelFormat];
				
				TKPixelFormatMapping formatMapping = TKPixelFormatMappingForPixelFormat(tkPixelFormat);
				
				pixelFormat = formatMapping.pixelFormat;
				dataType = formatMapping.dataType;
				
				if (formatMapping.tkNativePixelFormat) {
					// needs conversion
					
					NSData *existingData = [imageRep data];
					
					NSData *convertedData = [TKImageRep dataRepresentationOfData:existingData inPixelFormat:[imageRep pixelFormat] size:NSMakeSize(width, height) usingPixelFormat:formatMapping.tkNativePixelFormat];
					
					if (convertedData == nil) {
						NSLog(@"[%@ %@] [TKImageRep imageRepWithData:] returned nil!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
						return nil;
					}
					
					data = (GLubyte *)[convertedData bytes];
					
				} else {
					data = (GLubyte *)[[imageRep data] bytes];
					
				}
				
				[self generateName];

			}
			
		}
	}
	return self;
}


- (void)dealloc {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	glDeleteTextures(1, &name);
	free(data);
//	glDeleteBuffers(1, &pixelBuffer);
	[super dealloc];
}


- (void)generateName {
#if TK_DEBUG
		NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[nameLock lock];
	if (generatedName) {
		[nameLock unlock];
		return;
	}
	
	// Create a texture object to apply to model
	glGenTextures(1, &name);
	glBindTexture(GL_TEXTURE_2D, name);
	
	// Set up filter and wrap modes for this texture object
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	
	// Indicate that pixel rows are tightly packed
	//  (defaults to stride of 4 which is kind of only good for
	//  RGBA or FLOAT data types)
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	
	// Allocate and load image data into texture
	glTexImage2D(GL_TEXTURE_2D, 0, pixelFormat, width, height, 0, pixelFormat, dataType, data);
	
	// Create mipmaps for this texture for better image quality
	glGenerateMipmap(GL_TEXTURE_2D);
	
	TKGetGLError();
	
	generatedName = YES;
	[nameLock unlock];
}
	
	
//	if (name == 0) {
//		
//		// Create a texture object to apply to model
//		glGenTextures(1, &name);
//		glBindTexture(GL_TEXTURE_2D, name);
//		
//		// Set up filter and wrap modes for this texture object
//		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
//		
//		// Indicate that pixel rows are tightly packed
//		//  (defaults to stride of 4 which is kind of only good for
//		//  RGBA or FLOAT data types)
//		glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
//		
//		// Allocate and load image data into texture
//		glTexImage2D(GL_TEXTURE_2D, 0, pixelFormat, width, height, 0, pixelFormat, dataType, data);
//		
//		// Create mipmaps for this texture for better image quality
//		glGenerateMipmap(GL_TEXTURE_2D);
//		
//		TKGetGLError();
//	}


- (void)bind {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	glBindTexture(GL_TEXTURE_2D, self.name);
	
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithFormat:@"%@,	", [super description]];
	[description appendFormat:@"{%u x %u},	", (unsigned int)width, (unsigned int)height];
	[description appendFormat:@"name == %u", (unsigned int)self.name];
	return description;
}



@end






