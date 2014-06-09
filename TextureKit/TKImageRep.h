//
//  TKImageRep.h
//  Texture Kit
//
//  Created by Mark Douma on 11/5/2010.
//  Copyright (c) 2010-2014 Mark Douma LLC. All rights reserved.
//

#import <AppKit/NSBitmapImageRep.h>
#import <Foundation/NSDictionary.h>
#import <TextureKit/TextureKitDefines.h>

@class NSError;


enum {
	TKFaceRight				= 0,	// +x
	TKFaceLeft				= 1,	// -x
	TKFaceBack				= 2,	// +y
	TKFaceFront				= 3,	// -y
	TKFaceUp				= 4,	// +z
	TKFaceDown				= 5,	// -z
	TKFaceSphereMap			= 6,	// fall back
	TKFaceNone				= NSNotFound
};
typedef NSUInteger TKFace;


enum {
	TKSliceIndexNone	= NSNotFound,
	TKFrameIndexNone	= NSNotFound,
	TKMipmapIndexNone	= NSNotFound,
};


enum {
	TKDXTCompressionLowQuality		= 0,
	TKDXTCompressionMediumQuality	= 1,
	TKDXTCompressionHighQuality		= 2,
	TKDXTCompressionHighestQuality	= 3,
	TKDXTCompressionDefaultQuality	= TKDXTCompressionHighQuality,
	TKDXTCompressionNotApplicable	= 4,
};
typedef NSUInteger TKDXTCompressionQuality;


enum {
	
	TKPixelFormatUnknown					= 0,
	
	TKPixelFormatXRGB1555					= 1,
	TKPixelFormatRGBX5551					= 2,
	
	TKPixelFormatBGRX5551					= 3,
	TKPixelFormatXBGR1555					= 4,
	
	TKPixelFormatA							= 5,
	TKPixelFormatL							= 6,
	TKPixelFormatLA							= 7,
	TKPixelFormatPremultipliedLA			= 8,
	
	TKPixelFormatRGB						= 9,
	TKPixelFormatXRGB						= 10,
	TKPixelFormatRGBX						= 11,
	
	TKPixelFormatBGRX						= 12,
	TKPixelFormatXBGR						= 13,
	
	TKPixelFormatARGB						= 14,
	TKPixelFormatPremultipliedARGB			= 15,
	TKPixelFormatRGBA						= 16,
	TKPixelFormatPremultipliedRGBA			= 17,
	
	TKPixelFormatBGRA						= 18,
	TKPixelFormatPremultipliedBGRA			= 19,
	TKPixelFormatABGR						= 20,
	TKPixelFormatPremultipliedABGR			= 21,
	
	TKPixelFormatL16						= 22,
	TKPixelFormatLA1616						= 23,
	TKPixelFormatPremultipliedLA1616		= 24,
	
	TKPixelFormatRGB161616					= 25,
	TKPixelFormatRGBA16161616				= 26,
	TKPixelFormatPremultipliedRGBA16161616	= 27,
	
	TKPixelFormatR32F						= 28,
	TKPixelFormatRGB323232F					= 29,
	TKPixelFormatRGBA32323232F				= 30,
	
};
typedef NSUInteger TKPixelFormat;


enum {
	TKMipmapGenerationNoMipmaps				= 0,
	TKMipmapGenerationUsingBoxFilter		= 1,
	TKMipmapGenerationUsingTriangleFilter	= 2,
	TKMipmapGenerationUsingKaiserFilter		= 3,
};
typedef NSUInteger TKMipmapGenerationType;


enum {
	TKWrapModeClamp					= 0,
	TKWrapModeRepeat				= 1,
	TKWrapModeMirror				= 2,
};
typedef NSUInteger TKWrapMode;


enum {
	TKResizeModeNone				= 0,
	TKResizeModeNextPowerOfTwo		= 1,
	TKResizeModeNearestPowerOfTwo	= 2,
	TKResizeModePreviousPowerOfTwo	= 3,
};
typedef NSUInteger TKResizeMode;


/* References: */
// https://code.google.com/p/nvidia-texture-tools/wiki/ResizeFilters
// Mipmapping Part 1: http://number-none.com/product/Mipmapping,%20Part%201/
// Mipmapping Part 2: http://number-none.com/product/Mipmapping,%20Part%202/

enum {
	TKResizeFilterBox				= 0,
	TKResizeFilterTriangle			= 1,
	TKResizeFilterKaiser			= 2,
	TKResizeFilterMitchell			= 3,
};
typedef NSUInteger TKResizeFilter;



/* The following are the keys that can be used in TKImage's `*RepresentationWithOptions:error:`, and TKImageRep subclasses' `*RepresentationOfImageRepsInArray:options:error:` methods. */

TEXTUREKIT_EXTERN NSString * const TKImageMipmapGenerationKey;	// NSNumber containing a `TKMipmapGenerationType` enum value; default is `TKMipmapGenerationNoMipmaps`
TEXTUREKIT_EXTERN NSString * const TKImageWrapModeKey;			// NSNumber containing a `TKWrapMode` enum value; default is `TKWrapModeClamp`
TEXTUREKIT_EXTERN NSString * const TKImageResizeModeKey;		// NSNumber containing a `TKResizeMode` enum value; default is `TKResizeModeNone`
TEXTUREKIT_EXTERN NSString * const TKImageResizeFilterKey;		// NSNumber containing a `TKResizeFilter` enum value; only used if the value for `TKImageResizeModeKey` is something other than `TKResizeModeNone`, default is `TKResizeFilterBox`


/* The following are the key(s) that can be used to access values in the `imageProperties` property of a TKImageRep. */

TEXTUREKIT_EXTERN NSString * const TKImagePropertyVersion;		// NSString



@interface TKImageRep : NSBitmapImageRep <NSCoding, NSCopying> {
	NSUInteger				sliceIndex;
	TKFace					face;
	NSUInteger				frameIndex;
	NSUInteger				mipmapIndex;
	
	TKPixelFormat			pixelFormat;
	CGBitmapInfo			bitmapInfo;
	CGImageAlphaInfo		alphaInfo;
	
	NSDictionary			*imageProperties;
	
}

+ (NSArray *)imageRepsWithData:(NSData *)containerData error:(NSError **)outError;

+ (id)imageRepWithData:(NSData *)containerData error:(NSError **)outError;
- (id)initWithData:(NSData *)containerData error:(NSError **)outError;

- (id)initWithCGImage:(CGImageRef)cgImage sliceIndex:(NSUInteger)aSlice face:(TKFace)aFace frameIndex:(NSUInteger)aFrame mipmapIndex:(NSUInteger)aMipmap;


/* create TKImageRep(s) from NSBitmapImageRep(s) */
+ (id)imageRepWithImageRep:(NSBitmapImageRep *)aBitmapImageRep;
+ (NSArray *)imageRepsWithImageReps:(NSArray *)bitmapImageReps;


/* Returns a human-readable string giving the name of the given compression quality. */
+ (NSString *)localizedNameOfCompressionQuality:(TKDXTCompressionQuality)compressionQuality;


+ (TKDXTCompressionQuality)defaultDXTCompressionQuality;
+ (void)setDefaultDXTCompressionQuality:(TKDXTCompressionQuality)aQuality;


@property (readonly, nonatomic, assign) NSUInteger sliceIndex;
@property (readonly, nonatomic, assign) TKFace face;
@property (readonly, nonatomic, assign) NSUInteger frameIndex;
@property (readonly, nonatomic, assign) NSUInteger mipmapIndex;

@property (readonly, nonatomic, assign) TKPixelFormat pixelFormat;
@property (readonly, nonatomic, assign) CGBitmapInfo bitmapInfo;
@property (readonly, nonatomic, assign) CGImageAlphaInfo alphaInfo;


@property (readonly, nonatomic, assign) BOOL hasDimensionsThatArePowerOfTwo;


/* The following property contains key value pairs of various metadata of the image. If this image rep was a native image
 obtained through the ImageIO.framework, the `imageProperties` will contain key/value pairs associated with the 
 `CGImageSourceCopyPropertiesAtIndex()` function. This dictionary may also contain values for any of the 
 `TKImageProperty*` keys defined above in this header. */

@property (readonly, nonatomic, copy) NSDictionary *imageProperties;


- (NSData *)data;


/* For creating images in standard formats: kUTTypePNG, kUTTypeTIFF, etc. */
- (NSData *)representationUsingImageType:(NSString *)utiType properties:(NSDictionary *)properties;




- (NSComparisonResult)compare:(TKImageRep *)imageRep;



+ (TKImageRep *)imageRepForFace:(TKFace)aFace ofImageRepsInArray:(NSArray *)imageReps;

+ (TKImageRep *)largestRepresentationInArray:(NSArray *)tkImageReps;


+ (BOOL)sizeIsPowerOfTwo:(NSSize)aSize;

+ (NSSize)powerOfTwoSizeForSize:(NSSize)aSize usingResizeMode:(TKResizeMode)resizeMode;

+ (NSRect)rectForFace:(TKFace)face inEnvironmentMapRect:(NSRect)environmentMapRect;


@end


