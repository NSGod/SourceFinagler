//
//  TKImage.h
//  Texture Kit
//
//  Created by Mark Douma on 11/5/2010.
//  Copyright (c) 2010-2014 Mark Douma LLC. All rights reserved.
//

#import <AppKit/NSImage.h>
#import <TextureKit/TKDDSImageRep.h>
#import <TextureKit/TKVTFImageRep.h>

@class NSIndexSet;

enum {
	TKVTFImageType			= 0, // loaded image is a VTF
	TKDDSImageType			= 1, // loaded image is a DDS
	TKSFTIImageType			= 2, // Source Finagler Texture Image type (NSCoding)
	TKRegularImageType		= 3, // loaded image is a native type (anything ImageIO.framework supports)
	TKEmptyImageType		= 4, // when a TKImage is created with initWithSize:
	TKUnknownImageType		= 5,
};
typedef NSUInteger TKImageType;

// In VTF images:
// if sliceCount (depth) > 0, the image must have a single face, frame, and mipmap level

TEXTUREKIT_EXTERN NSString * const TKSFTextureImageType;		// UTI Type
TEXTUREKIT_EXTERN NSString * const TKSFTextureImageFileType;	// filename extension
TEXTUREKIT_EXTERN NSString * const TKSFTextureImagePboardType;

TEXTUREKIT_EXTERN NSData * TKSFTextureImageMagicData;


@interface TKImage : NSImage <NSCoding, NSCopying> {
	
@private
	id _TK_private;
	
@protected
	
	NSMutableDictionary		*reps;
	
	NSString				*version;
	NSString				*compression;
	
	NSUInteger				sliceCount;
	
	NSUInteger				faceCount;
	
	NSUInteger				frameCount;
	
	NSUInteger				mipmapCount;
	
	TKImageType				imageType;
	
	BOOL					isDepthTexture;
	
	BOOL					isEnvironmentMap;
	BOOL					isCubemap;
	BOOL					isSpheremap;
	
	BOOL					isAnimated;
	
	BOOL					hasMipmaps;
	
	BOOL					hasAlpha;
	
}


- (id)initWithContentsOfFile:(NSString *)fileName error:(NSError **)outError;
- (id)initWithContentsOfURL:(NSURL *)url error:(NSError **)outError;

- (id)initWithData:(NSData *)data error:(NSError **)outError;
- (id)initWithData:(NSData *)data firstRepresentationOnly:(BOOL)firstRepOnly error:(NSError **)outError;


/* See TKImageRep.h for more info on the allowed key/value pairs for the `options` dictionary in the following 4 methods. */

- (NSData *)DDSRepresentationWithOptions:(NSDictionary *)options error:(NSError **)outError;
/* Will raise an exception if `aFormat` is an unsupported format	*/
- (NSData *)DDSRepresentationUsingFormat:(TKDDSFormat)aFormat quality:(TKDXTCompressionQuality)aQuality container:(TKDDSContainer)container options:(NSDictionary *)options error:(NSError **)outError;


- (NSData *)VTFRepresentationWithOptions:(NSDictionary *)options error:(NSError **)outError;
/* Will raise an exception if `aFormat` is an unsupported format	*/
- (NSData *)VTFRepresentationUsingFormat:(TKVTFFormat)aFormat quality:(TKDXTCompressionQuality)aQuality options:(NSDictionary *)options error:(NSError **)outError;


/* For creating images in standard formats: kUTTypePNG, kUTTypeTIFF, etc. */
- (NSData *)representationUsingImageType:(NSString *)utiType properties:(NSDictionary *)properties;




@property (readonly, nonatomic, assign) NSUInteger sliceCount;
@property (readonly, nonatomic, assign) NSUInteger faceCount;
@property (readonly, nonatomic, assign) NSUInteger frameCount;
@property (readonly, nonatomic, assign) NSUInteger mipmapCount;



@property (readonly, nonatomic, assign) BOOL isDepthTexture;	// true if sliceCount > 0

@property (readonly, nonatomic, assign) BOOL isEnvironmentMap;	// true if faceCount > 0
@property (readonly, nonatomic, assign) BOOL isCubemap;			// true if faceCount == 6
@property (readonly, nonatomic, assign) BOOL isSpheremap;		// true if faceCount == 7

@property (readonly, nonatomic, assign) BOOL isAnimated;		// true if frameCount > 0

@property (readonly, nonatomic, assign) BOOL hasMipmaps;		// true if mipmapCount > 1


@property (readonly, nonatomic, assign) BOOL hasDimensionsThatArePowerOfTwo;


@property (nonatomic, assign, setter=setAlpha:) BOOL hasAlpha;
@property (nonatomic, retain) NSString *version;
@property (nonatomic, retain) NSString *compression;

@property (nonatomic, assign) TKImageType imageType;



@property (readonly, nonatomic, assign) NSSize environmentMapSize;

/* Will raise an exception if image is not an environment map */
- (void)drawEnvironmentMapInRect:(NSRect)rect;



- (NSIndexSet *)allSliceIndexes;
- (NSIndexSet *)allFaceIndexes;
- (NSIndexSet *)allFrameIndexes;
- (NSIndexSet *)allMipmapIndexes;

- (NSIndexSet *)mipmapIndexes;

- (NSIndexSet *)firstSliceIndexSet;
- (NSIndexSet *)firstFaceIndexSet;
- (NSIndexSet *)firstFrameIndexSet;
- (NSIndexSet *)firstMipmapIndexSet;



- (void)removeRepresentations:(NSArray *)imageReps;


/* for depth texture images */
- (TKImageRep *)representationForSliceIndex:(NSUInteger)sliceIndex;
- (void)setRepresentation:(TKImageRep *)representation forSliceIndex:(NSUInteger)sliceIndex;
- (void)removeRepresentationForSliceIndex:(NSUInteger)sliceIndex;


/* for static, non-animated texture images */
- (TKImageRep *)representationForMipmapIndex:(NSUInteger)mipmapIndex;
- (void)setRepresentation:(TKImageRep *)representation forMipmapIndex:(NSUInteger)mipmapIndex;
- (void)removeRepresentationForMipmapIndex:(NSUInteger)mipmapIndex;

- (NSArray *)representationsForMipmapIndexes:(NSIndexSet *)mipmapIndexes;
- (void)setRepresentations:(NSArray *)representations forMipmapIndexes:(NSIndexSet *)mipmapIndexes;
- (void)removeRepresentationsForMipmapIndexes:(NSIndexSet *)mipmapIndexes;


/* for animated (multi-frame) texture images */
- (TKImageRep *)representationForFrameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;
- (void)setRepresentation:(TKImageRep *)representation forFrameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;
- (void)removeRepresentationForFrameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;

- (NSArray *)representationsForFrameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes;
- (void)setRepresentations:(NSArray *)representations forFrameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes;
- (void)removeRepresentationsForFrameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes;


/* for multi-sided texture images */
- (TKImageRep *)representationForFace:(TKFace)aFace mipmapIndex:(NSUInteger)mipmapIndex;
- (void)setRepresentation:(TKImageRep *)representation forFace:(TKFace)aFace mipmapIndex:(NSUInteger)mipmapIndex;
- (void)removeRepresentationForFace:(TKFace)aFace mipmapIndex:(NSUInteger)mipmapIndex;

- (NSArray *)representationsForFaceIndexes:(NSIndexSet *)faceIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes;
- (void)setRepresentations:(NSArray *)representations forFaceIndexes:(NSIndexSet *)faceIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes;
- (void)removeRepresentationsForFaceIndexes:(NSIndexSet *)faceIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes;


/* for animated (multi-frame), multi-sided texture images */
- (TKImageRep *)representationForFace:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;
- (void)setRepresentation:(TKImageRep *)representation forFace:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;
- (void)removeRepresentationForFace:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;

- (NSArray *)representationsForFaceIndexes:(NSIndexSet *)faceIndexes frameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes;
- (void)setRepresentations:(NSArray *)representations forFaceIndexes:(NSIndexSet *)faceIndexes frameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes;
- (void)removeRepresentationsForFaceIndexes:(NSIndexSet *)faceIndexes frameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes;




- (void)generateMipmapsUsingFilter:(TKMipmapGenerationType)filterType;

- (void)removeMipmaps;

@end



