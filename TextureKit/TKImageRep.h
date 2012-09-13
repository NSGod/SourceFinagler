//
//  TKImageRep.h
//  Texture Kit
//
//  Created by Mark Douma on 11/5/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <AppKit/NSBitmapImageRep.h>
#import <Foundation/NSDictionary.h>
#import <TextureKit/TextureKitDefines.h>


enum {
	TKFaceNone				= 0,
	TKFaceRight				= 1,
	TKFaceLeft				= 2,
	TKFaceBack				= 3,
	TKFaceFront				= 4,
	TKFaceUp				= 5,
	TKFaceDown				= 6,
	TKFaceSphereMap			= 7
};
typedef NSUInteger TKFace;

enum {
	TKDXTCompressionLowQuality		= 0,
	TKDXTCompressionMediumQuality	= 1,
	TKDXTCompressionHighQuality		= 2,
	TKDXTCompressionHighestQuality	= 3,
	TKDXTCompressionDefaultQuality	= TKDXTCompressionHighQuality,
	TKDXTCompressionNotApplicable	= 1000
};
typedef NSUInteger TKDXTCompressionQuality;

TEXTUREKIT_EXTERN NSString *NSStringFromDXTCompressionQuality(TKDXTCompressionQuality aQuality);


enum {
	TKPixelFormatRGB				= 0,
	TKPixelFormatXRGB				= 1,
	TKPixelFormatRGBX				= 2,
	TKPixelFormatARGB				= 3,
	TKPixelFormatRGBA				= 4,
	TKPixelFormatRGBA16161616		= 5,
	TKPixelFormatRGBX16161616		= 6,
	TKPixelFormatRGBA32323232F		= 7,
	TKPixelFormatRGBX32323232F		= 8,
	TKPixelFormatUnknown			= NSNotFound
};
typedef NSUInteger TKPixelFormat;


enum {
	TKCompareSliceIndexes		= 1,
	TKCompareFaces				= 2,
	TKCompareFrameIndexes		= 4,
	TKCompareMipmapIndexes		= 8
};
typedef NSUInteger TKImageRepCompareOptions;


@interface TKImageRep : NSBitmapImageRep <NSCoding, NSCopying> {
	NSUInteger				sliceIndex;
	TKFace					face;
	NSUInteger				frameIndex;
	NSUInteger				mipmapIndex;
	
	CGBitmapInfo			bitmapInfo;
	CGImageAlphaInfo		alphaInfo;
	TKPixelFormat			pixelFormat;
	
	BOOL					isObserved;
}

+ (NSArray *)imageRepsWithData:(NSData *)aData;

+ (id)imageRepWithData:(NSData *)aData;
- (id)initWithData:(NSData *)aData;

- (id)initWithCGImage:(CGImageRef)cgImage sliceIndex:(NSUInteger)aSlice face:(TKFace)aFace frameIndex:(NSUInteger)aFrame mipmapIndex:(NSUInteger)aMipmap;


+ (TKDXTCompressionQuality)defaultDXTCompressionQuality;
+ (void)setDefaultDXTCompressionQuality:(TKDXTCompressionQuality)aQuality;

@property (assign) NSUInteger sliceIndex;
@property (assign) TKFace face;
@property (assign) NSUInteger frameIndex;
@property (assign) NSUInteger mipmapIndex;

@property (assign) CGBitmapInfo bitmapInfo;
@property (assign) CGImageAlphaInfo alphaInfo;
@property (assign) TKPixelFormat pixelFormat;

@property (assign, setter=setObserved:) BOOL isObserved;

- (void)setSliceIndex:(NSUInteger)aSliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)aFrameIndex mipmapIndex:(NSUInteger)aMipmapIndex;

- (NSData *)data;

- (NSData *)RGBAData;
- (NSData *)representationUsingPixelFormat:(TKPixelFormat)aPixelFormat;

//- (NSData *)representationForType:(NSString *)utiType;

- (NSComparisonResult)compare:(TKImageRep *)imageRep;
- (NSComparisonResult)compare:(TKImageRep *)imageRep options:(TKImageRepCompareOptions)options;

@end


@interface TKImageRep (IKImageBrowserItem)

- (NSString *)imageUID;					/* required */
- (NSString *)imageRepresentationType;	/* required */
- (id)imageRepresentation;				/* required */

- (NSString *)imageTitle;

//- (NSUInteger)imageVersion;
//- (NSString *)imageSubtitle;
//- (BOOL)isSelectable;

@end


@interface TKImageRep (IKImageProperties)
- (NSDictionary *)imageProperties;
@end


@interface TKImageRep (TKLargestRepresentationAdditions)
+ (TKImageRep *)largestRepresentationInArray:(NSArray *)tkImageReps;
@end


//TEXTUREKIT_EXTERN NSData *TKImageDataFromNSData(NSData *data, NSUInteger pixelCount, NSUInteger bitsPerPixel, CGBitmapInfo sourceBitmapInfo, CGBitmapInfo destinationBitmapInfo);
//
//TEXTUREKIT_EXTERN NSData *TKBGRADataFromImageData(NSData *data, NSUInteger pixelCount, NSUInteger bitsPerPixel, CGBitmapInfo aCGBitmapInfo);




