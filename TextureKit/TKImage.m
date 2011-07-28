//
//  TKImage.m
//  Texture Kit
//
//  Created by Mark Douma on 11/5/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKImage.h>
#import <TextureKit/TextureKitDefines.h>
#import "TKFoundationAdditions.h"
#import <CoreServices/CoreServices.h>
#import <Quartz/Quartz.h>

// Notes:
// NSImage's initWithSize: appears to be the designated initializer.
// init, initWithContentsOfFile:, initWithData:, and initWithContentsOfURL:
// all call initWithSize:.



#define TK_DEBUG 1

TEXTUREKIT_STATIC_INLINE NSString *TKImageKey(NSUInteger anUInteger) {
	return [NSString stringWithFormat:@"%lu", anUInteger];
}


NSString * const TKSFTextureImageType			= @"com.markdouma.texture-image";
NSString * const TKSFTextureImageFileType		= @"sfti";
NSString * const TKSFTextureImagePboardType		= @"TKSFTextureImagePboardType";

NSString * const TKImageRepKey					= @"TKImageRep";

// NSCoding keys
NSString * const TKImageImageRepsKey			= @"TKImageImageReps";
NSString * const TKImageCompressionKey			= @"TKImageCompression";
NSString * const TKImageVersionKey				= @"TKImageVersion";
NSString * const TKImageTypeKey					= @"TKImageType";
NSString * const TKImageHasAlphaKey				= @"TKImageHasAlpha";

NSString * const TKImageFrameCountKey			= @"TKImageFrameCount";
NSString * const TKImageSliceCountKey			= @"TKImageSliceCount";
NSString * const TKImageFaceCountKey			= @"TKImageFaceCount";
NSString * const TKImageMipmapCountKey			= @"TKImageMipmapCount";



static NSString * const TKImageZeroKey = @"0";


const UInt8 TKSFTextureImageMagic[] = {
	'b', 'p', 'l', 'i', 's', 't', '0', '0'
};

NSData * TKSFTextureImageMagicData	= nil;


static NSString * const TKImageAllSliceIndexesKey	= @"allIndexes.sliceIndexes";
static NSString * const TKImageAllFaceIndexesKey	= @"allIndexes.faceIndexes";
static NSString * const TKImageAllFrameIndexesKey	= @"allIndexes.frameIndexes";
static NSString * const TKImageAllMipmapIndexesKey	= @"allIndexes.mipmapIndexes";



@interface TKImage ()

@property (retain) NSMutableDictionary *allIndexes;

- (void)removeObserverForImageRep:(TKImageRep *)anImageRep;
- (void)removeObserverForImageReps:(NSArray *)imageReps;
- (void)addObserverForImageRep:(TKImageRep *)anImageRep;
- (void)addObserverForImageReps:(NSArray *)imageReps;

- (TKImageRep *)representationForSliceIndex:(NSUInteger)sliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;
- (void)setRepresentation:(TKImageRep *)representation forSliceIndex:(NSUInteger)sliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;
- (void)removeRepresentationForSliceIndex:(NSUInteger)sliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;
@end



@implementation TKImage

+ (void)initialize {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (TKSFTextureImageMagicData == nil) {
		TKSFTextureImageMagicData = [[NSData alloc] initWithBytes:&TKSFTextureImageMagic length:sizeof(TKSFTextureImageMagic)];
	}
	
	[NSImageRep registerImageRepClass:[TKVTFImageRep class]];
	[NSImageRep registerImageRepClass:[TKDDSImageRep class]];
	[NSImageRep registerImageRepClass:[TKImageRep class]];
}

@synthesize isAnimated, frameCount, mipmapCount, faceCount, sliceCount, hasAlpha, hasMipmaps, version, compression, type, isDepthTexture, isCubemap, isSpheremap;

@synthesize allIndexes = _private;


- (id)initWithSize:(NSSize)aSize {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithSize:aSize])) {
		
#if TK_DEBUG
//	NSLog(@"[%@ %@] TKSFTextureImageMagicData == %@, length == %lu, sizeof(TKSFTextureImageMagic) == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), TKSFTextureImageMagicData, [TKSFTextureImageMagicData length], sizeof(TKSFTextureImageMagic));
#endif
		
		reps = [[NSMutableDictionary alloc] init];
		
		type = TKEmptyImageType;
		
		[self setAllIndexes:[NSMutableDictionary dictionary]];
		
		[self setValue:[NSMutableIndexSet indexSet] forKeyPath:TKImageAllSliceIndexesKey];
		[self setValue:[NSMutableIndexSet indexSet] forKeyPath:TKImageAllFaceIndexesKey];
		[self setValue:[NSMutableIndexSet indexSet] forKeyPath:TKImageAllFrameIndexesKey];
		[self setValue:[NSMutableIndexSet indexSet] forKeyPath:TKImageAllMipmapIndexesKey];
		
//		NSLog(@"[%@ %@] self.allIndexes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [self allIndexes]);
	
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	TKImage *copy = [[TKImage alloc] initWithSize:[self size]];
	NSArray *representations = [[self representations] deepMutableCopy];
	for (NSImageRep *imageRep in representations) {
		if ([imageRep isKindOfClass:[TKImageRep class]]) {
			[(TKImageRep *)imageRep setObserved:NO];
		}
	}
	[copy addRepresentations:representations];
	[representations release];
	return copy;
}


- (id)initWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithCoder:coder])) {
		
		sliceCount = [[coder decodeObjectForKey:TKImageSliceCountKey] unsignedIntegerValue];
		faceCount = [[coder decodeObjectForKey:TKImageFaceCountKey] unsignedIntegerValue];
		frameCount = [[coder decodeObjectForKey:TKImageFrameCountKey] unsignedIntegerValue];
		mipmapCount = [[coder decodeObjectForKey:TKImageMipmapCountKey] unsignedIntegerValue];
		
		isDepthTexture = (sliceCount > 1);
		isCubemap = (faceCount == 6);
		isSpheremap = (faceCount == 7);
		isAnimated = (frameCount > 1);
		hasMipmaps = (mipmapCount > 1);
		
		hasAlpha = [[coder decodeObjectForKey:TKImageHasAlphaKey] boolValue];
		
		[self setVersion:[coder decodeObjectForKey:TKImageVersionKey]];
		[self setCompression:[coder decodeObjectForKey:TKImageCompressionKey]];
		
		[self setType:[[coder decodeObjectForKey:TKImageTypeKey] unsignedIntegerValue]];
		
		NSDictionary *theReps = [coder decodeObjectForKey:TKImageImageRepsKey];
		reps = [theReps deepMutableCopy];
		
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super encodeWithCoder:coder];
	
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:sliceCount] forKey:TKImageSliceCountKey];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:faceCount] forKey:TKImageFaceCountKey];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:frameCount] forKey:TKImageFrameCountKey];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:mipmapCount] forKey:TKImageMipmapCountKey];
	
	[coder encodeObject:[NSNumber numberWithBool:hasAlpha] forKey:TKImageHasAlphaKey];
	[coder encodeObject:version forKey:TKImageVersionKey];
	[coder encodeObject:compression forKey:TKImageCompressionKey];
	
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:TKSFTIImageType] forKey:TKImageTypeKey];
	
	[coder encodeObject:reps forKey:TKImageImageRepsKey];
	
}


- (id)initWithContentsOfFile:(NSString *)fileName {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self initWithContentsOfURL:[NSURL fileURLWithPath:fileName]];
}

- (id)initWithContentsOfURL:(NSURL *)url {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self initWithData:[NSData dataWithContentsOfURL:url]];
}
		

- (id)initWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self initWithData:aData firstRepresentationOnly:NO];
}

- (id)initWithData:(NSData *)aData firstRepresentationOnly:(BOOL)firstRepOnly {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	// load only first rep if it's a TKImageRep subclass, otherwise, pass to super
	
	if (firstRepOnly) {
		Class imageRepClass = [NSImageRep imageRepClassForData:aData];
#if TK_DEBUG
		NSLog(@"[%@ %@] ******** singleRepOnly ****** imageRepClass == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromClass(imageRepClass));
#endif
		
		if ([imageRepClass isSubclassOfClass:[TKImageRep class]]) {
#if TK_DEBUG
			NSLog(@"[%@ %@] it's a TKImageRep subclass", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
			TKImageRep *imageRep = [imageRepClass imageRepWithData:aData];
			if (imageRep) {
				if ((self = [self initWithSize:[imageRep size]])) {
					[self addRepresentation:imageRep];
					
					if ([imageRep isKindOfClass:[TKVTFImageRep class]]) {
						[self setType:TKVTFImageType];
					} else if ([imageRep isKindOfClass:[TKDDSImageRep class]]) {
						[self setType:TKDDSImageType];
					} else {
						[self setType:TKRegularImageType];
					}
#if TK_DEBUG
					NSLog(@"[%@ %@] size == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromSize([self size]));
#endif
					[self setSize:[imageRep size]];
				}
			}
			return self;
		}
		// else, drop through
	} 
	
	NSUInteger dataLength = [aData length];
	
	if (dataLength < [TKSFTextureImageMagicData length]) {
		NSLog(@"[%@ %@] [data length] < 8 bytes!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		[self release];
		return nil;
	}
	
	NSData *magicData = [aData subdataWithRange:NSMakeRange(0, [TKSFTextureImageMagicData length])];
	
	OSType magic = 0;
	if (dataLength > sizeof(OSType)) {
		[aData getBytes:&magic length:sizeof(magic)];
		magic = NSSwapBigIntToHost(magic);
	}
	
	if (magic == TKVTFMagic || magic == TKDDSMagic) {
		// it's a TKVTFImageRep or TKDDSImageRep, let super handle it
		
		if ((self = [super initWithData:aData])) {
			NSArray *theReps = [self representations];
			if ([theReps count]) {
				
				NSImageRep *testImageRep = [theReps objectAtIndex:0];
				
				if ([testImageRep isKindOfClass:[TKVTFImageRep class]]) {
					[self setType:TKVTFImageType];
				} else {
					[self setType:TKDDSImageType];
				}
			}
		}
	} else if ([magicData isEqualToData:TKSFTextureImageMagicData]) {
		// it's a native, archived TKSFTextureImageType
		
		TKImage *archivedImage = [NSKeyedUnarchiver unarchiveObjectWithData:aData];
		if (archivedImage == nil) {
			[self release];
			return nil;
		}
		self = [archivedImage retain];
		return self;
		
	} else {
		
		// it's a regular image that ImageIO can handle
		// file in question is a generic image, use ImageIO to handle it
		// by creating CGImageRefs to create TKImageReps
		
		// it's a TKVTFImageRep or TKDDSImageRep, let super handle it
		
		if ((self = [super initWithData:aData])) {
			NSArray *theReps = [self representations];
			if ([theReps count]) {
				
				NSImageRep *testImageRep = [theReps objectAtIndex:0];
				
				if ([testImageRep isKindOfClass:[TKVTFImageRep class]]) {
					[self setType:TKVTFImageType];
				} else if ([testImageRep isKindOfClass:[TKDDSImageRep class]]) {
					[self setType:TKDDSImageType];
				} else {
					[self setType:TKRegularImageType];
				}
			}
		}
	}
	
	NSArray *theReps = [self representations];
	if ([theReps count]) {
		NSImageRep *largestRep = [TKImageRep largestRepresentationInArray:theReps];
		[self setSize:[largestRep size]];
	}
	return self;
}
		

- (void)dealloc {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[version release];
	[compression release];
	[reps release];
	
	[_private release];
	
	NSArray *representations = [self representations];
	for (NSImageRep *rep in representations) {
		if ([rep isKindOfClass:[TKImageRep class]]) {
			[self removeObserverForImageRep:(TKImageRep *)rep];
		}
	}
	
	[super dealloc];
}


- (void)addRepresentation:(NSImageRep *)imageRep {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self addRepresentations:[NSArray arrayWithObject:imageRep]];
}

- (void)addRepresentations:(NSArray *)imageReps {
#if TK_DEBUG
	NSLog(@"[%@ %@] representations == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), imageReps);
#endif
	
	for (NSImageRep *imageRep in imageReps) {
		if ([imageRep isKindOfClass:[TKImageRep class]]) {
			TKImageRep *tkImageRep = (TKImageRep *)imageRep;
			
			NSUInteger sliceIndex = [tkImageRep sliceIndex];
			NSUInteger faceIndex = [tkImageRep face];
			NSUInteger frameIndex = [tkImageRep frameIndex];
			NSUInteger mipmapIndex = [tkImageRep mipmapIndex];
			
			[self setRepresentation:tkImageRep forSliceIndex:sliceIndex face:faceIndex frameIndex:frameIndex mipmapIndex:mipmapIndex];
			
		} else {
			[super addRepresentations:[NSArray arrayWithObject:imageRep]];
		}
	}
	
#if TK_DEBUG
//	NSLog(@"[%@ %@] reps == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), reps);
#endif
}
	

- (void)removeRepresentations:(NSArray *)imageReps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	for (NSImageRep *imageRep in imageReps) {
		[self removeRepresentation:imageRep];
	}
}


- (void)removeRepresentation:(NSImageRep *)imageRep {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([imageRep isKindOfClass:[TKImageRep class]]) {
		
		[self removeRepresentationForSliceIndex:[(TKImageRep *)imageRep sliceIndex]
										   face:[(TKImageRep *)imageRep face]
									 frameIndex:[(TKImageRep *)imageRep frameIndex]
									mipmapIndex:[(TKImageRep *)imageRep mipmapIndex]];
		
	} else {
		[super removeRepresentation:imageRep];
	}

}


- (NSIndexSet *)allSliceIndexes {
	return [[[self valueForKeyPath:TKImageAllSliceIndexesKey] copy] autorelease];
}

- (NSIndexSet *)allFaceIndexes {
	return [[[self valueForKeyPath:TKImageAllFaceIndexesKey] copy] autorelease];
}

- (NSIndexSet *)allFrameIndexes {
	return [[[self valueForKeyPath:TKImageAllFrameIndexesKey] copy] autorelease];
}

- (NSIndexSet *)allMipmapIndexes {
	return [[[self valueForKeyPath:TKImageAllMipmapIndexesKey] copy] autorelease];
}


- (NSIndexSet *)firstSliceIndexSet {
	NSUInteger firstIndex = [[self allSliceIndexes] firstIndex];
	if (firstIndex == NSNotFound) {
		return [NSIndexSet indexSet];
	}
	return [NSIndexSet indexSetWithIndex:firstIndex];
}


- (NSIndexSet *)firstFaceIndexSet {
	NSUInteger firstIndex = [[self allFaceIndexes] firstIndex];
	if (firstIndex == NSNotFound) {
		return [NSIndexSet indexSet];
	}
	return [NSIndexSet indexSetWithIndex:firstIndex];
}


- (NSIndexSet *)firstFrameIndexSet {
	NSUInteger firstIndex = [[self allFrameIndexes] firstIndex];
	if (firstIndex == NSNotFound) {
		return [NSIndexSet indexSet];
	}
	return [NSIndexSet indexSetWithIndex:firstIndex];
	
}

- (NSIndexSet *)firstMipmapIndexSet {
	NSUInteger firstIndex = [[self allMipmapIndexes] firstIndex];
	if (firstIndex == NSNotFound) {
		return [NSIndexSet indexSet];
	}
	return [NSIndexSet indexSetWithIndex:firstIndex];
}



- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
#if TK_DEBUG
	NSLog(@"[%@ %@] keyPath == %@, object == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), keyPath, object);
#endif
	
}



static const NSUInteger TKMipmapIndexNone = NSNotFound;
static const NSUInteger TKFrameIndexNone = NSNotFound;

- (TKImageRep *)representationForSliceIndex:(NSUInteger)sliceIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self representationForSliceIndex:sliceIndex face:TKFaceNone frameIndex:TKFrameIndexNone mipmapIndex:TKMipmapIndexNone];
}


- (void)setRepresentation:(TKImageRep *)representation forSliceIndex:(NSUInteger)sliceIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self setRepresentation:representation forSliceIndex:sliceIndex face:TKFaceNone frameIndex:TKFrameIndexNone mipmapIndex:TKMipmapIndexNone];
}


- (void)removeRepresentationForSliceIndex:(NSUInteger)sliceIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self removeRepresentationForSliceIndex:sliceIndex face:TKFaceNone frameIndex:TKFrameIndexNone mipmapIndex:TKMipmapIndexNone];
}


- (TKImageRep *)representationForMipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self representationForSliceIndex:0 face:TKFaceNone frameIndex:0 mipmapIndex:mipmapIndex];
}

- (void)setRepresentation:(TKImageRep *)representation forMipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self setRepresentation:representation forSliceIndex:0 face:TKFaceNone frameIndex:0 mipmapIndex:mipmapIndex];
}

- (void)removeRepresentationForMipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self removeRepresentationForSliceIndex:0 face:TKFaceNone frameIndex:0 mipmapIndex:mipmapIndex];
}


- (TKImageRep *)representationForFrameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@] frameIndex == %lu mipmapIndex == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), frameIndex, mipmapIndex);
#endif
	return [self representationForSliceIndex:0 face:TKFaceNone frameIndex:frameIndex mipmapIndex:mipmapIndex];
}


- (void)setRepresentation:(TKImageRep *)representation forFrameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self setRepresentation:representation forSliceIndex:0 face:TKFaceNone frameIndex:frameIndex mipmapIndex:mipmapIndex];
}


- (void)removeRepresentationForFrameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self removeRepresentationForSliceIndex:0 face:TKFaceNone frameIndex:frameIndex mipmapIndex:mipmapIndex];
}


- (NSArray *)representationsForFrameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSMutableArray *representations = [NSMutableArray array];
	
	NSUInteger frameIndex = [frameIndexes firstIndex];
	
	while (frameIndex != NSNotFound) {
		
		NSUInteger mipmapIndex = [mipmapIndexes firstIndex];
		
		while (mipmapIndex != NSNotFound) {
			TKImageRep *imageRep = [self representationForSliceIndex:0 face:TKFaceNone frameIndex:frameIndex mipmapIndex:mipmapIndex];
			if (imageRep) {
				[representations addObject:imageRep];
			}
			mipmapIndex = [mipmapIndexes indexGreaterThanIndex:mipmapIndex];
		}
		
		frameIndex = [frameIndexes indexGreaterThanIndex:frameIndex];
	}
	return [[representations copy] autorelease];
	
}


- (void)setRepresentations:(NSArray *)representations forFrameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	
	
	
}


- (void)removeRepresentationsForFrameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}



//- (NSArray *)representationsForFrameIndexes:(NSIndexSet *)frameIndexes {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	return [self representationsForFrameIndexes:frameIndexes includeMipmaps:YES];
//}
//
//
//- (NSArray *)representationsForFrameIndexes:(NSIndexSet *)frameIndexes includeMipmaps:(BOOL)includeMipmaps {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	NSMutableArray *representations = [NSMutableArray array];
//	
//	NSMutableDictionary *sliceDict = [reps objectForKey:TKImageZeroKey];
//	if (sliceDict) {
//		NSMutableDictionary *faceDict = [sliceDict objectForKey:TKImageZeroKey];
//		if (faceDict) {
//			NSUInteger frameIndex = [frameIndexes firstIndex];
//			while (frameIndex != NSNotFound) {
//				NSMutableDictionary *frameDict = [faceDict objectForKey:TKImageKey(frameIndex)];
//				if (frameDict) {
//					if (includeMipmaps == NO) {
//						NSMutableDictionary *mipmapDict = [frameDict objectForKey:TKImageZeroKey];
//						if (mipmapDict) {
//							TKImageRep *textureImageRep = [mipmapDict objectForKey:TKImageRepKey];
//							if (textureImageRep) [representations addObject:textureImageRep];
//						}
//					} else {
//						NSArray *sortedKeys = [[frameDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
//						for (NSNumber *key in sortedKeys) {
//							NSMutableDictionary *mipmapDict = [frameDict objectForKey:key];
//							if (mipmapDict) {
//								TKImageRep *textureImageRep = [mipmapDict objectForKey:TKImageRepKey];
//								if (textureImageRep) [representations addObject:textureImageRep];
//							}
//						}
//						
//					}
//				}
//				
//				frameIndex = [frameIndexes indexGreaterThanIndex:frameIndex];
//			}
//		}
//	}
//	return [[representations copy] autorelease];
//}


- (TKImageRep *)representationForFace:(TKFace)aFace {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self representationForSliceIndex:0 face:aFace frameIndex:0 mipmapIndex:0];
}


- (void)setRepresentation:(TKImageRep *)representation forFace:(TKFace)aFace {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self setRepresentation:representation forSliceIndex:0 face:aFace frameIndex:0 mipmapIndex:0];
}


- (void)removeRepresentationForFace:(TKFace)aFace {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self removeRepresentationForSliceIndex:0 face:aFace frameIndex:0 mipmapIndex:0];
}

- (TKImageRep *)representationForFace:(TKFace)aFace mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self representationForSliceIndex:0 face:aFace frameIndex:0 mipmapIndex:mipmapIndex];
}

- (void)setRepresentation:(TKImageRep *)representation forFace:(TKFace)aFace mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self setRepresentation:representation forSliceIndex:0 face:aFace frameIndex:0 mipmapIndex:mipmapIndex];
}


- (void)removeRepresentationForFace:(TKFace)aFace mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self removeRepresentationForSliceIndex:0 face:aFace frameIndex:0 mipmapIndex:mipmapIndex];
}




- (TKImageRep *)representationForFace:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self representationForSliceIndex:0 face:aFace frameIndex:frameIndex mipmapIndex:mipmapIndex];
}


- (void)setRepresentation:(TKImageRep *)representation forFace:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self setRepresentation:representation forSliceIndex:0 face:aFace frameIndex:frameIndex mipmapIndex:mipmapIndex];
}


- (void)removeRepresentationForFace:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self removeRepresentationForSliceIndex:0 face:aFace frameIndex:frameIndex mipmapIndex:mipmapIndex];
}



#pragma mark -
#pragma mark primary accessors

- (TKImageRep *)representationForSliceIndex:(NSUInteger)sliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (frameIndex == TKFrameIndexNone && mipmapIndex == TKMipmapIndexNone) {
		// it's a depth texture
		NSMutableDictionary *sliceDict = [reps objectForKey:TKImageKey(sliceIndex)];
		if (sliceDict) {
			return [sliceDict objectForKey:TKImageRepKey];
		}
		
	} else {
		// it's a regular texture
		
		NSMutableDictionary *sliceDict = [reps objectForKey:TKImageZeroKey];
		if (sliceDict) {
			NSMutableDictionary *faceDict = [sliceDict objectForKey:TKImageKey(aFace)];
			if (faceDict) {
				NSMutableDictionary *frameDict = [faceDict objectForKey:TKImageKey(frameIndex)];
				if (frameDict) {
					NSMutableDictionary *mipmapDict = [frameDict objectForKey:TKImageKey(mipmapIndex)];
					if (mipmapDict) {
						return [mipmapDict objectForKey:TKImageRepKey];
					}
				}
			}
		}
		
	}
	return nil;
}


- (void)setRepresentation:(TKImageRep *)representation forSliceIndex:(NSUInteger)sliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (representation == nil) return;
	
	if (frameIndex == TKFrameIndexNone && mipmapIndex == TKMipmapIndexNone) {
		// it's a depth texture
		NSMutableDictionary *sliceDict = [reps objectForKey:TKImageKey(sliceIndex)];
		if (sliceDict == nil) {
			sliceDict = [NSMutableDictionary dictionary];
			[reps setObject:sliceDict forKey:TKImageKey(sliceIndex)];
		}
		
		[(NSMutableIndexSet *)[self valueForKeyPath:TKImageAllSliceIndexesKey] addIndex:sliceIndex];
		
		[self willChangeValueForKey:@"sliceCount"];
		[self willChangeValueForKey:@"isDepthTexture"];
		
		sliceCount += 1;
		isDepthTexture = (sliceCount > 1);
		
		[self didChangeValueForKey:@"sliceCount"];
		[self didChangeValueForKey:@"isDepthTexture"];
		
		[self removeObserverForImageRep:representation];
		[representation setSliceIndex:sliceIndex face:TKFaceNone frameIndex:0 mipmapIndex:0];
		
		
		[sliceDict setObject:representation forKey:TKImageRepKey];
		
	} else {
		// it's a regular texture
		
		[self removeObserverForImageRep:representation];
		
		[representation setSliceIndex:sliceIndex face:aFace frameIndex:frameIndex mipmapIndex:mipmapIndex];
		
		NSMutableDictionary *sliceDict = [reps objectForKey:TKImageZeroKey];
		if (sliceDict == nil) {
			sliceDict = [NSMutableDictionary dictionary];
			[reps setObject:sliceDict forKey:TKImageZeroKey];
		}
		NSMutableDictionary *faceDict = [sliceDict objectForKey:TKImageKey(aFace)];
		if (faceDict == nil) {
			faceDict = [NSMutableDictionary dictionary];
			[sliceDict setObject:faceDict forKey:TKImageKey(aFace)];
		}
		NSMutableDictionary *frameDict = [faceDict objectForKey:TKImageKey(frameIndex)];
		if (frameDict == nil) {
			frameDict = [NSMutableDictionary dictionary];
			[faceDict setObject:frameDict forKey:TKImageKey(frameIndex)];
		}
		NSMutableDictionary *mipmapDict = [frameDict objectForKey:TKImageKey(mipmapIndex)];
		if (mipmapDict == nil) {
			mipmapDict = [NSMutableDictionary dictionary];
			[frameDict setObject:mipmapDict forKey:TKImageKey(mipmapIndex)];
		}
		[mipmapDict setObject:representation forKey:TKImageRepKey];
		
		NSUInteger sliceCountBefore = [[self allSliceIndexes] count];
		NSUInteger faceCountBefore = [[self allFaceIndexes] count];
		NSUInteger frameCountBefore = [[self allFrameIndexes] count];
		NSUInteger mipmapCountBefore = [[self allMipmapIndexes] count];
		
		
		NSMutableIndexSet *sliceIndexes = (NSMutableIndexSet *)[self valueForKeyPath:TKImageAllSliceIndexesKey];
		[sliceIndexes removeAllIndexes];
		[sliceIndexes addIndex:0];
		
		[(NSMutableIndexSet *)[self valueForKeyPath:TKImageAllFaceIndexesKey] addIndex:aFace];
		[(NSMutableIndexSet *)[self valueForKeyPath:TKImageAllFrameIndexesKey] addIndex:frameIndex];
		[(NSMutableIndexSet *)[self valueForKeyPath:TKImageAllMipmapIndexesKey] addIndex:mipmapIndex];
		
		NSUInteger sliceCountAfter = [[self allSliceIndexes] count];
		NSUInteger faceCountAfter = [[self allFaceIndexes] count];
		NSUInteger frameCountAfter = [[self allFrameIndexes] count];
		NSUInteger mipmapCountAfter = [[self allMipmapIndexes] count];
		
		
		if (sliceCountAfter > sliceCountBefore) {
			[self willChangeValueForKey:@"sliceCount"];
			[self willChangeValueForKey:@"isDepthTexture"];
			
			sliceCount += 1;
			isDepthTexture = (sliceCount > 1);
			
			[self didChangeValueForKey:@"sliceCount"];
			[self didChangeValueForKey:@"isDepthTexture"];
			
		}
		
		if (faceCountAfter > faceCountBefore) {
			[self willChangeValueForKey:@"faceCount"];
			[self willChangeValueForKey:@"isCubemap"];
			[self willChangeValueForKey:@"isSpheremap"];
			
			faceCount += 1;
			isCubemap = (faceCount == 6);
			isSpheremap = (faceCount == 7);
			
			[self didChangeValueForKey:@"faceCount"];
			[self didChangeValueForKey:@"isCubemap"];
			[self didChangeValueForKey:@"isSpheremap"];
			
		}
		
		if (frameCountAfter > frameCountBefore) {
			[self willChangeValueForKey:@"frameCount"];
			[self willChangeValueForKey:@"isAnimated"];
			
			frameCount += 1;
			isAnimated = (frameCount > 1);
			
			[self didChangeValueForKey:@"frameCount"];
			[self didChangeValueForKey:@"isAnimated"];
			
		}
		
		if (mipmapCountAfter > mipmapCountBefore) {
			[self willChangeValueForKey:@"mipmapCount"];
			[self willChangeValueForKey:@"hasMipmaps"];
			
			mipmapCount += 1;
			hasMipmaps = (mipmapCount > 1);
			
			[self didChangeValueForKey:@"mipmapCount"];
			[self didChangeValueForKey:@"hasMipmaps"];
		}
		
	}
	
	[self addObserverForImageRep:representation];
	
//	NSLog(@"[%@ %@] ******** CALLING [super addRepresentation:representation] ********", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	[super addRepresentation:representation];
}


- (void)removeRepresentationForSliceIndex:(NSUInteger)sliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (frameIndex == TKFrameIndexNone && mipmapIndex == TKMipmapIndexNone) {
		// it's a depth texture
		NSMutableDictionary *sliceDict = [reps objectForKey:TKImageKey(sliceIndex)];
		if (sliceDict) {
			TKImageRep *representation = [sliceDict objectForKey:TKImageRepKey];
			
			if (representation) {
				[self removeObserverForImageRep:representation];
				[super removeRepresentation:representation];
			}
			
			[sliceDict removeObjectForKey:TKImageRepKey];
		}
	} else {
		// it's a regular texture
		
		NSMutableDictionary *sliceDict = [reps objectForKey:TKImageZeroKey];
		if (sliceDict) {
			NSMutableDictionary *faceDict = [sliceDict objectForKey:TKImageKey(aFace)];
			if (faceDict) {
				NSMutableDictionary *frameDict = [faceDict objectForKey:TKImageKey(frameIndex)];
				if (frameDict) {
					NSMutableDictionary *mipmapDict = [frameDict objectForKey:TKImageKey(mipmapIndex)];
					if (mipmapDict) {
						TKImageRep *representation = [mipmapDict objectForKey:TKImageRepKey];
						
						if (representation) {
							[self removeObserverForImageRep:representation];
							[super removeRepresentation:representation];
						}
						
						[mipmapDict removeObjectForKey:TKImageRepKey];
					}
				}
			}
		}
	}
	
}

#pragma mark END main accessors
#pragma mark -


- (void)removeObserverForImageRep:(TKImageRep *)anImageRep {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self removeObserverForImageReps:[NSArray arrayWithObject:anImageRep]];
}

- (void)removeObserverForImageReps:(NSArray *)imageReps {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	for (TKImageRep *imageRep in imageReps) {
		if ([imageRep isObserved]) {
			[imageRep removeObserver:self forKeyPath:@"sliceIndex"];
			[imageRep removeObserver:self forKeyPath:@"face"];
			[imageRep removeObserver:self forKeyPath:@"frameIndex"];
			[imageRep removeObserver:self forKeyPath:@"mipmapIndex"];
			[imageRep setObserved:NO];
		}
	}
}


- (void)addObserverForImageRep:(TKImageRep *)anImageRep {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self addObserverForImageReps:[NSArray arrayWithObject:anImageRep]];
}


- (void)addObserverForImageReps:(NSArray *)imageReps {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	for (TKImageRep *imageRep in imageReps) {
		[imageRep addObserver:self forKeyPath:@"sliceIndex" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
		[imageRep addObserver:self forKeyPath:@"face" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
		[imageRep addObserver:self forKeyPath:@"frameIndex" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
		[imageRep addObserver:self forKeyPath:@"mipmapIndex" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
		[imageRep setObserved:YES];
	}
}


- (NSData *)DDSRepresentation {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self DDSRepresentationUsingFormat:[TKDDSImageRep defaultFormat] quality:[TKImageRep defaultDXTCompressionQuality] createMipmaps:YES];
}


- (NSData *)DDSRepresentationUsingFormat:(TKDDSFormat)aFormat quality:(TKDXTCompressionQuality)aQuality createMipmaps:(BOOL)createMipmaps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [TKDDSImageRep DDSRepresentationOfImageRepsInArray:[self representations] usingFormat:aFormat quality:aQuality createMipmaps:createMipmaps];
}

- (NSData *)VTFRepresentation {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self VTFRepresentationUsingFormat:[TKVTFImageRep defaultFormat] quality:[TKImageRep defaultDXTCompressionQuality] createMipmaps:YES];
}


- (NSData *)VTFRepresentationUsingFormat:(TKVTFFormat)aFormat quality:(TKDXTCompressionQuality)aQuality createMipmaps:(BOOL)createMipmaps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [TKVTFImageRep VTFRepresentationOfImageRepsInArray:[self representations] usingFormat:aFormat quality:aQuality createMipmaps:createMipmaps];
}


- (NSData *)dataForType:(NSString *)utiType properties:(NSDictionary *)properties {
#if TK_DEBUG
	NSLog(@"[%@ %@] utiType == %@, properties == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), utiType, properties);
#endif
	NSMutableData *imageData = [NSMutableData data];
	
	CGImageDestinationRef imageDest = CGImageDestinationCreateWithData((CFMutableDataRef)imageData , (CFStringRef)utiType, 1, NULL);
	if (imageDest) {
		if ([[self representations] count]) {
			TKImageRep *imageRep = [[self representations] objectAtIndex:0];
			CGImageRef imageRef = [imageRep CGImage];
			if (imageRef) {
				CGImageDestinationAddImage(imageDest, imageRef, (CFDictionaryRef)properties);
				CGImageDestinationFinalize(imageDest);
			}
			
		}
		CFRelease(imageDest);
	}
	return [[imageData copy] autorelease];
}

typedef struct TKImageTypeDescription {
	TKImageType		imageType;
	NSString		*description;
} TKImageTypeDescription;

static const TKImageTypeDescription TKImageTypeDescriptionTable[] = {
	{ TKVTFImageType, @"TKVTFImageType" },
	{ TKDDSImageType, @"TKDDSImageType" },
	{ TKRegularImageType, @"MDRegularImageType" },
	{ TKEmptyImageType, @"MDEmptyImageType" },
	{ TKUnknownImageType, @"MDUnknownImageType" }
};
static const NSUInteger TKImageTypeDescriptionTableCount = sizeof(TKImageTypeDescriptionTable)/sizeof(TKImageTypeDescription);

static inline NSString *NSStringFromImageType(TKImageType aType) {
	for (NSUInteger i = 0; i < TKImageTypeDescriptionTableCount; i++) {
		if (aType == TKImageTypeDescriptionTable[i].imageType) {
			return TKImageTypeDescriptionTable[i].description;
		}
	}
	return @"<unknown>";
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithString:[super description]];
	[description appendFormat:@"\n"];
	[description appendFormat:@"imageType == %@\n", NSStringFromImageType(type)];
	[description appendFormat:@"sliceCount == %lu\n", sliceCount];
	[description appendFormat:@"faceCount == %lu\n", faceCount];
	[description appendFormat:@"frameCount == %lu\n", frameCount];
	[description appendFormat:@"mipmapCount == %lu\n", mipmapCount];
	[description appendFormat:@"reps == %@", reps];
	return description;
}

@end







