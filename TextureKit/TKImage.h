//
//  TKImage.h
//  Texture Kit
//
//  Created by Mark Douma on 11/5/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
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
	TKEmptyImageType		= 4, // when an TKImage is created with initWithSize: ??
	TKUnknownImageType		= NSNotFound
};
typedef NSUInteger TKImageType;

// In VTF images:
// 
// if sliceCount (depth) > 1, the image must have a single face, frame, and mipmap level

TEXTUREKIT_EXTERN NSString * const TKSFTextureImageType;
TEXTUREKIT_EXTERN NSString * const TKSFTextureImageFileType;
TEXTUREKIT_EXTERN NSString * const TKSFTextureImagePboardType;

extern NSData * TKSFTextureImageMagicData;


@interface TKImage : NSImage <NSCoding, NSCopying> {
	NSUInteger				sliceCount;
	BOOL					isDepthTexture;
	
	NSUInteger				faceCount;
	BOOL					isCubemap;
	BOOL					isSpheremap;
	
	NSUInteger				frameCount;
	BOOL					isAnimated;
	
	NSUInteger				mipmapCount;
	BOOL					hasMipmaps;
	
	BOOL					hasAlpha;
	
	NSString				*version;
	NSString				*compression;
	
	NSMutableDictionary		*reps;
	
	TKImageType				type;
	
@private
	id _private;
}

- (id)initWithData:(NSData *)aData firstRepresentationOnly:(BOOL)firstRepOnly;

- (void)removeRepresentations:(NSArray *)imageReps;

@property (assign, readonly) NSUInteger sliceCount;
@property (assign, readonly) NSUInteger faceCount;
@property (assign, readonly) NSUInteger frameCount;
@property (assign, readonly) NSUInteger mipmapCount;

@property (assign, readonly) BOOL isDepthTexture;
@property (assign, readonly) BOOL isAnimated;
@property (assign, readonly) BOOL isSpheremap;
@property (assign, readonly) BOOL isCubemap;
@property (assign, readonly) BOOL hasMipmaps;


@property (assign, setter=setAlpha:) BOOL hasAlpha;
@property (retain) NSString *version;
@property (retain) NSString *compression;

@property (assign) TKImageType type;


- (NSIndexSet *)allSliceIndexes;
- (NSIndexSet *)allFaceIndexes;
- (NSIndexSet *)allFrameIndexes;
- (NSIndexSet *)allMipmapIndexes;

- (NSIndexSet *)firstSliceIndexSet;
- (NSIndexSet *)firstFaceIndexSet;
- (NSIndexSet *)firstFrameIndexSet;
- (NSIndexSet *)firstMipmapIndexSet;




- (TKImageRep *)representationForSliceIndex:(NSUInteger)sliceIndex;
- (void)setRepresentation:(TKImageRep *)representation forSliceIndex:(NSUInteger)sliceIndex;
- (void)removeRepresentationForSliceIndex:(NSUInteger)sliceIndex;



- (TKImageRep *)representationForMipmapIndex:(NSUInteger)mipmapIndex;
- (void)setRepresentation:(TKImageRep *)representation forMipmapIndex:(NSUInteger)mipmapIndex;
- (void)removeRepresentationForMipmapIndex:(NSUInteger)mipmapIndex;

//- (NSArray *)representationsForMipmapIndexes:(NSIndexSet *)mipmapIndexes;
//- (void)setRepresentations:(NSArray *)representations forMipmapIndexes:(NSIndexSet *)mipmapIndexes;
//- (void)removeRepresentationsForMipmapIndexes:(NSIndexSet *)mipmapIndexes;



- (TKImageRep *)representationForFrameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;
- (void)setRepresentation:(TKImageRep *)representation forFrameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;
- (void)removeRepresentationForFrameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;


- (NSArray *)representationsForFrameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes;
- (void)setRepresentations:(NSArray *)representations forFrameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes;
- (void)removeRepresentationsForFrameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes;

//- (NSArray *)representationsForFrameIndexes:(NSIndexSet *)frameIndexes;
//- (NSArray *)representationsForFrameIndexes:(NSIndexSet *)frameIndexes includeMipmaps:(BOOL)includeMipmaps;


- (TKImageRep *)representationForFace:(TKFace)aFace;
- (void)setRepresentation:(TKImageRep *)representation forFace:(TKFace)aFace;
- (void)removeRepresentationForFace:(TKFace)aFace;

- (TKImageRep *)representationForFace:(TKFace)aFace mipmapIndex:(NSUInteger)mipmapIndex;
- (void)setRepresentation:(TKImageRep *)representation forFace:(TKFace)aFace mipmapIndex:(NSUInteger)mipmapIndex;
- (void)removeRepresentationForFace:(TKFace)aFace mipmapIndex:(NSUInteger)mipmapIndex;

- (TKImageRep *)representationForFace:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;
- (void)setRepresentation:(TKImageRep *)representation forFace:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;
- (void)removeRepresentationForFace:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;



- (NSData *)DDSRepresentation;
- (NSData *)DDSRepresentationUsingFormat:(TKDDSFormat)aFormat quality:(TKDXTCompressionQuality)aQuality createMipmaps:(BOOL)createMipmaps;

- (NSData *)VTFRepresentation;
- (NSData *)VTFRepresentationUsingFormat:(TKVTFFormat)aFormat quality:(TKDXTCompressionQuality)aQuality createMipmaps:(BOOL)createMipmaps;


- (NSData *)dataForType:(NSString *)utiType properties:(NSDictionary *)properties;

@end






