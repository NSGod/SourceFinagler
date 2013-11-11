//
//  TKImage.m
//  Texture Kit
//
//  Created by Mark Douma on 11/5/2010.
//  Copyright (c) 2010-2013 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKImage.h>
#import <TextureKit/TextureKitDefines.h>
#import "TKFoundationAdditions.h"
#import <CoreServices/CoreServices.h>

// Notes:
// NSImage's initWithSize: appears to be the designated initializer.
// init, initWithContentsOfFile:, initWithData:, and initWithContentsOfURL:
// all call initWithSize:.



#define TK_DEBUG 0

TEXTUREKIT_INLINE NSString *TKImageKey(NSUInteger anUInteger) {
	return [NSString stringWithFormat:@"%lu", (unsigned long)anUInteger];
}


NSString * const TKSFTextureImageType			= @"com.markdouma.texture-image";
NSString * const TKSFTextureImageFileType		= @"sfti";
NSString * const TKSFTextureImagePboardType		= @"com.markdouma.texture-image";


static NSString * const TKImageRepKey					= @"TKImageRep";

// NSCoding keys
static NSString * const TKImageImageRepsKey				= @"TKImageImageReps";
static NSString * const TKImageCompressionKey			= @"TKImageCompression";
static NSString * const TKImageVersionKey				= @"TKImageVersion";
static NSString * const TKImageTypeKey					= @"TKImageType";
static NSString * const TKImageHasAlphaKey				= @"TKImageHasAlpha";

static NSString * const TKImageFrameCountKey			= @"TKImageFrameCount";
static NSString * const TKImageSliceCountKey			= @"TKImageSliceCount";
static NSString * const TKImageFaceCountKey				= @"TKImageFaceCount";
static NSString * const TKImageMipmapCountKey			= @"TKImageMipmapCount";



static NSString * TKImageNotApplicableKey	= nil;


static const UInt8 TKSFTextureImageMagic[] = {
	'b', 'p', 'l', 'i', 's', 't', '0', '0'
};

NSData * TKSFTextureImageMagicData	= nil;


static NSString * const TKImageAllSliceIndexesKey	= @"allIndexes.sliceIndexes";
static NSString * const TKImageAllFaceIndexesKey	= @"allIndexes.faceIndexes";
static NSString * const TKImageAllFrameIndexesKey	= @"allIndexes.frameIndexes";
static NSString * const TKImageAllMipmapIndexesKey	= @"allIndexes.mipmapIndexes";



@interface TKImage ()

@property (retain) NSMutableDictionary *allIndexes;

- (TKImageRep *)representationForSliceIndex:(NSUInteger)sliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;
- (void)setRepresentation:(TKImageRep *)representation forSliceIndex:(NSUInteger)sliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;
- (void)removeRepresentationForSliceIndex:(NSUInteger)sliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;
@end



@implementation TKImage

+ (void)initialize {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (TKImageNotApplicableKey == nil) {
		TKImageNotApplicableKey = [[NSString stringWithFormat:@"%lu", (unsigned long)NSNotFound] retain];
	}
	
	if (TKSFTextureImageMagicData == nil) {
		TKSFTextureImageMagicData = [[NSData alloc] initWithBytes:&TKSFTextureImageMagic length:sizeof(TKSFTextureImageMagic)];
	}
	
	[NSImageRep registerImageRepClass:[TKVTFImageRep class]];
	[NSImageRep registerImageRepClass:[TKDDSImageRep class]];
	[NSImageRep registerImageRepClass:[TKImageRep class]];
}

@synthesize isAnimated, frameCount, mipmapCount, faceCount, sliceCount, hasAlpha, hasMipmaps, version, compression, imageType, isDepthTexture, isCubemap, isSpheremap;

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
		
		imageType = TKEmptyImageType;
		
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
		
		[self setImageType:[[coder decodeObjectForKey:TKImageTypeKey] unsignedIntegerValue]];
		
		reps = [[NSMutableDictionary alloc] init];
		
		[self setAllIndexes:[NSMutableDictionary dictionary]];
		
		[self setValue:[NSMutableIndexSet indexSet] forKeyPath:TKImageAllSliceIndexesKey];
		[self setValue:[NSMutableIndexSet indexSet] forKeyPath:TKImageAllFaceIndexesKey];
		[self setValue:[NSMutableIndexSet indexSet] forKeyPath:TKImageAllFrameIndexesKey];
		[self setValue:[NSMutableIndexSet indexSet] forKeyPath:TKImageAllMipmapIndexesKey];
		
		NSArray *imageReps = [coder decodeObjectForKey:TKImageImageRepsKey];
		[self addRepresentations:imageReps];
		
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
	
	[coder encodeObject:[self representations] forKey:TKImageImageRepsKey];
	
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
						[self setImageType:TKVTFImageType];
					} else if ([imageRep isKindOfClass:[TKDDSImageRep class]]) {
						[self setImageType:TKDDSImageType];
					} else {
						[self setImageType:TKRegularImageType];
					}
#if TK_DEBUG
					NSLog(@"[%@ %@] size == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromSize([self size]));
#endif
					[self setSize:[imageRep size]];
					[self setAlpha:[imageRep hasAlpha]];
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
					[self setImageType:TKVTFImageType];
				} else {
					[self setImageType:TKDDSImageType];
				}
				
				[self setAlpha:[testImageRep hasAlpha]];
			}
		}
	} else if ([magicData isEqualToData:TKSFTextureImageMagicData]) {
		// it's a native, archived TKSFTextureImageType
		
		TKImage *archivedImage = [NSKeyedUnarchiver unarchiveObjectWithData:aData];
		if (archivedImage == nil) {
			NSLog(@"[%@ %@] TKImage *archivedImage = [NSKeyedUnarchiver unarchiveObjectWithData:aData] failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			[self release];
			return nil;
		}
		self = [archivedImage retain];
		return self;
		
	} else {
		
		// it's a regular image that ImageIO can handle
		// let super handle it to create TKImageReps
		
		if ((self = [super initWithData:aData])) {
			NSArray *theReps = [self representations];
			if ([theReps count]) {
				
				NSImageRep *testImageRep = [theReps objectAtIndex:0];
				
				if ([testImageRep isKindOfClass:[TKVTFImageRep class]]) {
					[self setImageType:TKVTFImageType];
				} else if ([testImageRep isKindOfClass:[TKDDSImageRep class]]) {
					[self setImageType:TKDDSImageType];
				} else {
					[self setImageType:TKRegularImageType];
				}
				
				[self setAlpha:[testImageRep hasAlpha]];
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
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//	NSLog(@"[%@ %@] representations == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), imageReps);
#endif
	NSMutableArray *repsToAdd = [NSMutableArray array];
	NSMutableArray *tkRepsToAdd = [NSMutableArray array];
	
	for (NSImageRep *imageRep in imageReps) {
		if ([imageRep isKindOfClass:[TKImageRep class]]) {
			[tkRepsToAdd addObject:imageRep];
		} else {
			[repsToAdd addObject:imageRep];
		}
	}
	
	if ([tkRepsToAdd count]) {
		NSMutableIndexSet *sliceIndexes = [NSMutableIndexSet indexSet];
		NSMutableIndexSet *faceIndexes = [NSMutableIndexSet indexSet];
		NSMutableIndexSet *frameIndexes = [NSMutableIndexSet indexSet];
		NSMutableIndexSet *mipmapIndexes = [NSMutableIndexSet indexSet];
		
		for (TKImageRep *anImageRep in tkRepsToAdd) {
			if ([anImageRep sliceIndex] != NSNotFound) [sliceIndexes addIndex:[anImageRep sliceIndex]];
			if ([anImageRep face] != NSNotFound) [faceIndexes addIndex:[anImageRep face]];
			if ([anImageRep frameIndex] != NSNotFound) [frameIndexes addIndex:[anImageRep frameIndex]];
			if ([anImageRep mipmapIndex] != NSNotFound) [mipmapIndexes addIndex:[anImageRep mipmapIndex]];
		}
		
#if TK_DEBUG
		NSLog(@"[%@ %@] sliceIndexes == %@, faceIndexes == %@, frameIndexes == %@, mipmapIndexes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sliceIndexes, faceIndexes, frameIndexes, mipmapIndexes);
#endif
		NSUInteger slicesCount = [sliceIndexes count];
		NSUInteger facesCount = [faceIndexes count];
		NSUInteger framesCount = [frameIndexes count];
		
		for (TKImageRep *tkImageRep in tkRepsToAdd) {
			
			if (slicesCount > 1) {
				// depth texture
				
				[self setRepresentation:tkImageRep forSliceIndex:[tkImageRep sliceIndex] face:[tkImageRep face] frameIndex:[tkImageRep frameIndex] mipmapIndex:[tkImageRep mipmapIndex]];
				
			} else if (facesCount > 1 && framesCount > 1) {
				// ordinary texture
				[self setRepresentation:tkImageRep forSliceIndex:TKSliceIndexNone face:[tkImageRep face] frameIndex:[tkImageRep frameIndex] mipmapIndex:[tkImageRep mipmapIndex]];
				
			} else if (facesCount > 1) {
				[self setRepresentation:tkImageRep forSliceIndex:TKSliceIndexNone face:[tkImageRep face] frameIndex:TKFrameIndexNone mipmapIndex:[tkImageRep mipmapIndex]];
				
			} else if (framesCount > 1) {
				[self setRepresentation:tkImageRep forSliceIndex:TKSliceIndexNone face:TKFaceNone frameIndex:[tkImageRep frameIndex] mipmapIndex:[tkImageRep mipmapIndex]];
				
			} else {
				
				[self setRepresentation:tkImageRep forSliceIndex:TKSliceIndexNone face:TKFaceNone frameIndex:TKFrameIndexNone mipmapIndex:[tkImageRep mipmapIndex]];
				
			}
		}
	}
	
	if ([repsToAdd count]) {
		[super addRepresentations:repsToAdd];
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


- (NSIndexSet *)mipmapIndexes {
	NSMutableIndexSet *mipmapIndexes = [[[NSMutableIndexSet alloc] initWithIndexSet:[self allMipmapIndexes]] autorelease];
	[mipmapIndexes removeIndexes:[self firstMipmapIndexSet]];
	return [[mipmapIndexes copy] autorelease];
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
	return [self representationForSliceIndex:TKSliceIndexNone face:TKFaceNone frameIndex:TKFrameIndexNone mipmapIndex:mipmapIndex];
}

- (void)setRepresentation:(TKImageRep *)representation forMipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self setRepresentation:representation forSliceIndex:TKSliceIndexNone face:TKFaceNone frameIndex:TKFrameIndexNone mipmapIndex:mipmapIndex];
}

- (void)removeRepresentationForMipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self removeRepresentationForSliceIndex:TKSliceIndexNone face:TKFaceNone frameIndex:TKFrameIndexNone mipmapIndex:mipmapIndex];
}


- (NSArray *)representationsForMipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@] mipmapIndexes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), mipmapIndexes);
#endif
	NSParameterAssert(mipmapIndexes != nil);
//	NSParameterAssert([mipmapIndexes count] > 0);
	
	NSMutableArray *representations = [NSMutableArray array];
	
	NSUInteger mipmapIndex = [mipmapIndexes firstIndex];
	
	while (mipmapIndex != NSNotFound) {
		
		TKImageRep *imageRep = [self representationForMipmapIndex:mipmapIndex];
		if (imageRep) [representations addObject:imageRep];
		
		mipmapIndex = [mipmapIndexes indexGreaterThanIndex:mipmapIndex];
	}
	
	return [[representations copy] autorelease];
}


- (void)setRepresentations:(NSArray *)representations forMipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(representations != nil);
	NSParameterAssert(mipmapIndexes != nil);
	NSParameterAssert([mipmapIndexes count] > 0);
	NSParameterAssert([representations count] == [mipmapIndexes count]);
	
	NSUInteger mipmapIndexesCount = [mipmapIndexes count];
	
	NSUInteger mipmapIndex = [mipmapIndexes firstIndex];
	
	for (NSUInteger m = 0; m < mipmapIndexesCount; m++) {
		
		if (m == 0) {
			mipmapIndex = [mipmapIndexes firstIndex];
		}
		
		TKImageRep *imageRep = [representations objectAtIndex:m];
		
		[self setRepresentation:imageRep forMipmapIndex:mipmapIndex];
		
		mipmapIndex = [mipmapIndexes indexGreaterThanIndex:mipmapIndex];
		
	}
}


- (void)removeRepresentationsForMipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSUInteger mipmapIndex = [mipmapIndexes lastIndex];
	
	while (mipmapIndex != NSNotFound) {
		
		[self removeRepresentationForMipmapIndex:mipmapIndex];
		
		mipmapIndex = [mipmapIndexes indexLessThanIndex:mipmapIndex];
	}
}
	


- (TKImageRep *)representationForFrameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@] frameIndex == %lu mipmapIndex == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)frameIndex, (unsigned long)mipmapIndex);
#endif
	return [self representationForSliceIndex:TKSliceIndexNone face:TKFaceNone frameIndex:frameIndex mipmapIndex:mipmapIndex];
}


- (void)setRepresentation:(TKImageRep *)representation forFrameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self setRepresentation:representation forSliceIndex:TKSliceIndexNone face:TKFaceNone frameIndex:frameIndex mipmapIndex:mipmapIndex];
}


- (void)removeRepresentationForFrameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self removeRepresentationForSliceIndex:TKSliceIndexNone face:TKFaceNone frameIndex:frameIndex mipmapIndex:mipmapIndex];
}


- (NSArray *)representationsForFrameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(frameIndexes != nil);
	NSParameterAssert(mipmapIndexes != nil);
	NSParameterAssert(!([frameIndexes count] == 0 && [mipmapIndexes count] == 0));

	NSMutableArray *representations = [NSMutableArray array];
	
	NSUInteger frameIndex = [frameIndexes firstIndex];
	
	while (frameIndex != NSNotFound) {
		
		NSUInteger mipmapIndex = [mipmapIndexes firstIndex];
		
		while (mipmapIndex != NSNotFound) {
			
			TKImageRep *imageRep = [self representationForFrameIndex:frameIndex mipmapIndex:mipmapIndex];
			if (imageRep) [representations addObject:imageRep];
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
	
	NSParameterAssert(representations != nil);
	NSParameterAssert(frameIndexes != nil);
	NSParameterAssert(mipmapIndexes != nil);
	NSParameterAssert([representations count] > 0);
	NSParameterAssert([representations count] == [frameIndexes count] * [mipmapIndexes count]);

	
	NSUInteger frameIndexesCount = [frameIndexes count];
	NSUInteger mipmapIndexesCount = [mipmapIndexes count];
	
	NSUInteger frameIndex = [frameIndexes firstIndex];
	NSUInteger mipmapIndex = [mipmapIndexes firstIndex];
	
	
	for (NSUInteger f = 0; f < frameIndexesCount; f++) {
		
		for (NSUInteger m = 0; m < mipmapIndexesCount; m++) {
			
			if (m == 0) {
				mipmapIndex = [mipmapIndexes firstIndex];
			}
			
			TKImageRep *imageRep = [representations objectAtIndex:((f * mipmapIndexesCount) + m)];
			
			[self setRepresentation:imageRep forFrameIndex:frameIndex mipmapIndex:mipmapIndex];
			
			mipmapIndex = [mipmapIndexes indexGreaterThanIndex:mipmapIndex];
		}
		
		frameIndex = [frameIndexes indexGreaterThanIndex:frameIndex];
	}
}


- (void)removeRepresentationsForFrameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSUInteger frameIndex = [frameIndexes lastIndex];
	
	while (frameIndex != NSNotFound) {
		
		NSUInteger mipmapIndex = [mipmapIndexes lastIndex];
		
		while (mipmapIndex != NSNotFound) {
			
			[self removeRepresentationForFrameIndex:frameIndex mipmapIndex:mipmapIndex];
			
			mipmapIndex = [mipmapIndexes indexLessThanIndex:mipmapIndex];
			
		}
		
		frameIndex = [frameIndexes indexLessThanIndex:frameIndex];
	}
}



- (TKImageRep *)representationForFace:(TKFace)aFace mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self representationForSliceIndex:TKSliceIndexNone face:aFace frameIndex:TKFrameIndexNone mipmapIndex:mipmapIndex];
}

- (void)setRepresentation:(TKImageRep *)representation forFace:(TKFace)aFace mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self setRepresentation:representation forSliceIndex:TKSliceIndexNone face:aFace frameIndex:TKFrameIndexNone mipmapIndex:mipmapIndex];
}


- (void)removeRepresentationForFace:(TKFace)aFace mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self removeRepresentationForSliceIndex:TKSliceIndexNone face:aFace frameIndex:TKFrameIndexNone mipmapIndex:mipmapIndex];
}



- (NSArray *)representationsForFaceIndexes:(NSIndexSet *)faceIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(faceIndexes != nil);
	NSParameterAssert(mipmapIndexes != nil);
	NSParameterAssert(!([faceIndexes count] == 0 && [mipmapIndexes count] == 0));
	
	NSMutableArray *representations = [NSMutableArray array];
	
	NSUInteger faceIndex = [faceIndexes firstIndex];
	
	while (faceIndex != NSNotFound) {
		
		NSUInteger mipmapIndex = [mipmapIndexes firstIndex];
		
		while (mipmapIndex != NSNotFound) {
			TKImageRep *imageRep = [self representationForFace:faceIndex mipmapIndex:mipmapIndex];
			if (imageRep) [representations addObject:imageRep];
			mipmapIndex = [mipmapIndexes indexGreaterThanIndex:mipmapIndex];
			
		}
		
		faceIndex = [faceIndexes indexGreaterThanIndex:faceIndex];
	}
	return [[representations copy] autorelease];
}


- (void)setRepresentations:(NSArray *)representations forFaceIndexes:(NSIndexSet *)faceIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(representations != nil);
	NSParameterAssert(faceIndexes != nil);
	NSParameterAssert(mipmapIndexes != nil);
	NSParameterAssert([representations count] > 0);
	NSParameterAssert([representations count] == [faceIndexes count] * [mipmapIndexes count]);
	
	NSUInteger faceIndexesCount = [faceIndexes count];
	NSUInteger mipmapIndexesCount = [mipmapIndexes count];
	
	NSUInteger faceIndex = [faceIndexes firstIndex];
	NSUInteger mipmapIndex = [mipmapIndexes firstIndex];
	
	for (NSUInteger f = 0; f < faceIndexesCount; f++) {
		
		for (NSUInteger m = 0; m < mipmapIndexesCount; m++) {
			
			if (m == 0) {
				mipmapIndex = [mipmapIndexes firstIndex];
			}
			
			TKImageRep *imageRep = [representations objectAtIndex:((f * mipmapIndexesCount) + m)];
			
			[self setRepresentation:imageRep forFace:faceIndex mipmapIndex:mipmapIndex];
			
			mipmapIndex = [mipmapIndexes indexGreaterThanIndex:mipmapIndex];
		}
		
		faceIndex = [faceIndexes indexGreaterThanIndex:faceIndex];
	}
	
}


- (void)removeRepresentationsForFaceIndexes:(NSIndexSet *)faceIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSUInteger faceIndex = [faceIndexes lastIndex];
	
	while (faceIndex != NSNotFound) {
		
		NSUInteger mipmapIndex = [mipmapIndexes lastIndex];
		
		while (mipmapIndex != NSNotFound) {
			
			[self removeRepresentationForFace:faceIndex mipmapIndex:mipmapIndex];
			
			mipmapIndex = [mipmapIndexes indexLessThanIndex:mipmapIndex];
		}
		
		faceIndex = [faceIndexes indexLessThanIndex:faceIndex];
	}
}



- (TKImageRep *)representationForFace:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self representationForSliceIndex:TKSliceIndexNone face:aFace frameIndex:frameIndex mipmapIndex:mipmapIndex];
}


- (void)setRepresentation:(TKImageRep *)representation forFace:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self setRepresentation:representation forSliceIndex:TKSliceIndexNone face:aFace frameIndex:frameIndex mipmapIndex:mipmapIndex];
}


- (void)removeRepresentationForFace:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self removeRepresentationForSliceIndex:TKSliceIndexNone face:aFace frameIndex:frameIndex mipmapIndex:mipmapIndex];
}


- (NSArray *)representationsForFaceIndexes:(NSIndexSet *)faceIndexes frameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(faceIndexes != nil);
	NSParameterAssert(frameIndexes != nil);
	NSParameterAssert(mipmapIndexes != nil);
	NSParameterAssert(!([faceIndexes count] == 0 && [frameIndexes count] == 0 && [mipmapIndexes count] == 0));
	
	NSMutableArray *representations = [NSMutableArray array];
	
	NSUInteger faceIndex = [faceIndexes firstIndex];
	
	while (faceIndex != NSNotFound) {
		
		NSUInteger frameIndex = [frameIndexes firstIndex];
		
		while (frameIndex != NSNotFound) {
			
			NSUInteger mipmapIndex = [mipmapIndexes firstIndex];
			
			while (mipmapIndex != NSNotFound) {
				TKImageRep *imageRep = [self representationForFace:faceIndex frameIndex:frameIndex mipmapIndex:mipmapIndex];
				if (imageRep) [representations addObject:imageRep];
				
				mipmapIndex = [mipmapIndexes indexGreaterThanIndex:mipmapIndex];
			}
			
			frameIndex = [frameIndexes indexGreaterThanIndex:frameIndex];
			
		}
		
		faceIndex = [faceIndexes indexGreaterThanIndex:faceIndex];
		
	}
	return [[representations copy] autorelease];
}


- (void)setRepresentations:(NSArray *)representations forFaceIndexes:(NSIndexSet *)faceIndexes frameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(representations != nil);
	NSParameterAssert(faceIndexes != nil);
	NSParameterAssert(frameIndexes != nil);
	NSParameterAssert(mipmapIndexes != nil);
	NSParameterAssert([representations count] > 0);
	NSParameterAssert([representations count] == [faceIndexes count] * [frameIndexes count] * [mipmapIndexes count]);
	
	NSUInteger faceIndexesCount = [faceIndexes count];
	NSUInteger frameIndexesCount = [frameIndexes count];
	NSUInteger mipmapIndexesCount = [mipmapIndexes count];
	
	NSUInteger faceIndex = [faceIndexes firstIndex];
	NSUInteger frameIndex = [frameIndexes firstIndex];
	NSUInteger mipmapIndex = [mipmapIndexes firstIndex];
	
	for (NSUInteger face = 0; face < faceIndexesCount; face++) {
		
		for (NSUInteger frame = 0; frame < frameIndexesCount; frame++) {
			
			for (NSUInteger m = 0; m < mipmapIndexesCount; m++) {
				
				if (m == 0) {
					mipmapIndex = [mipmapIndexes firstIndex];
				}
				
				TKImageRep *imageRep = [representations objectAtIndex:((face * frame * mipmapIndexesCount) + m)];
				
				[self setRepresentation:imageRep forFace:faceIndex frameIndex:frameIndex mipmapIndex:mipmapIndex];
				
				mipmapIndex = [mipmapIndexes indexGreaterThanIndex:mipmapIndex];
				
			}
			
			frameIndex = [frameIndexes indexGreaterThanIndex:frameIndex];
			
		}
		
		faceIndex = [faceIndexes indexGreaterThanIndex:faceIndex];
		
	}
	
}


- (void)removeRepresentationsForFaceIndexes:(NSIndexSet *)faceIndexes frameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(faceIndexes != nil);
	NSParameterAssert(frameIndexes != nil);
	NSParameterAssert(mipmapIndexes != nil);
	NSParameterAssert(!([faceIndexes count] == 0 && [frameIndexes count] == 0 && [mipmapIndexes count] == 0));
	
	NSUInteger faceIndex = [faceIndexes lastIndex];
	
	while (faceIndex != NSNotFound) {
		
		NSUInteger frameIndex = [frameIndexes lastIndex];
		
		while (frameIndex != NSNotFound) {
			
			NSUInteger mipmapIndex = [mipmapIndexes lastIndex];
			
			while (mipmapIndex != NSNotFound) {
				
				[self removeRepresentationForFace:faceIndex frameIndex:frameIndex mipmapIndex:mipmapIndex];
				
				mipmapIndex = [mipmapIndexes indexLessThanIndex:mipmapIndex];
				
			}
			
			frameIndex = [frameIndexes indexLessThanIndex:frameIndex];
		}
		
		faceIndex = [faceIndexes indexLessThanIndex:faceIndex];
	}
}



#pragma mark -
#pragma mark primary accessors

- (TKImageRep *)representationForSliceIndex:(NSUInteger)aSliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)aFrameIndex mipmapIndex:(NSUInteger)aMipmapIndex {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (aSliceIndex != TKSliceIndexNone) {
		// it's a depth texture
		NSMutableDictionary *sliceDict = [reps objectForKey:TKImageKey(aSliceIndex)];
		if (sliceDict) return [sliceDict objectForKey:TKImageRepKey];
		
	} else {
		// it's a regular texture
		
		NSMutableDictionary *sliceDict = [reps objectForKey:TKImageNotApplicableKey];
		if (sliceDict) {
			NSMutableDictionary *faceDict = [sliceDict objectForKey:TKImageKey(aFace)];
			if (faceDict) {
				NSMutableDictionary *frameDict = [faceDict objectForKey:TKImageKey(aFrameIndex)];
				if (frameDict) {
					NSMutableDictionary *mipmapDict = [frameDict objectForKey:TKImageKey(aMipmapIndex)];
					if (mipmapDict) return [mipmapDict objectForKey:TKImageRepKey];
				}
			}
		}
	}
	return nil;
}



- (void)setRepresentation:(TKImageRep *)aRepresentation forSliceIndex:(NSUInteger)aSliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)aFrameIndex mipmapIndex:(NSUInteger)aMipmapIndex {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(aRepresentation != nil);
	
	if (aSliceIndex != TKSliceIndexNone) {
		// it's a depth texture
		
		NSMutableDictionary *sliceDict = [reps objectForKey:TKImageKey(aSliceIndex)];
		if (sliceDict == nil) {
			sliceDict = [NSMutableDictionary dictionary];
			[reps setObject:sliceDict forKey:TKImageKey(aSliceIndex)];
		}
		
		[(NSMutableIndexSet *)[self valueForKeyPath:TKImageAllSliceIndexesKey] addIndex:aSliceIndex];
		
		[self willChangeValueForKey:@"sliceCount"];
		[self willChangeValueForKey:@"isDepthTexture"];
		
		sliceCount += 1;
		isDepthTexture = (sliceCount > 0);
		
		[self didChangeValueForKey:@"sliceCount"];
		[self didChangeValueForKey:@"isDepthTexture"];
		
		[aRepresentation setSliceIndex:aSliceIndex face:TKFaceNone frameIndex:TKFrameIndexNone mipmapIndex:TKMipmapIndexNone];
		
		[sliceDict setObject:aRepresentation forKey:TKImageRepKey];
		
	} else {
		// it's a regular texture
		
		[aRepresentation setSliceIndex:aSliceIndex face:aFace frameIndex:aFrameIndex mipmapIndex:aMipmapIndex];
		
		NSMutableDictionary *sliceDict = [reps objectForKey:TKImageNotApplicableKey];
		if (sliceDict == nil) {
			sliceDict = [NSMutableDictionary dictionary];
			[reps setObject:sliceDict forKey:TKImageNotApplicableKey];
		}
		NSMutableDictionary *faceDict = [sliceDict objectForKey:TKImageKey(aFace)];
		if (faceDict == nil) {
			faceDict = [NSMutableDictionary dictionary];
			[sliceDict setObject:faceDict forKey:TKImageKey(aFace)];
		}
		NSMutableDictionary *frameDict = [faceDict objectForKey:TKImageKey(aFrameIndex)];
		if (frameDict == nil) {
			frameDict = [NSMutableDictionary dictionary];
			[faceDict setObject:frameDict forKey:TKImageKey(aFrameIndex)];
		}
		NSMutableDictionary *mipmapDict = [frameDict objectForKey:TKImageKey(aMipmapIndex)];
		if (mipmapDict == nil) {
			mipmapDict = [NSMutableDictionary dictionary];
			[frameDict setObject:mipmapDict forKey:TKImageKey(aMipmapIndex)];
		}
		[mipmapDict setObject:aRepresentation forKey:TKImageRepKey];
		
		
		NSUInteger sliceCountBefore = [[self allSliceIndexes] count];
		NSUInteger faceCountBefore = [[self allFaceIndexes] count];
		NSUInteger frameCountBefore = [[self allFrameIndexes] count];
		NSUInteger mipmapCountBefore = [[self allMipmapIndexes] count];
		
		
		NSMutableIndexSet *sliceIndexes = (NSMutableIndexSet *)[self valueForKeyPath:TKImageAllSliceIndexesKey];
		[sliceIndexes removeAllIndexes];
		
		if (aFace != TKFaceNone) [(NSMutableIndexSet *)[self valueForKeyPath:TKImageAllFaceIndexesKey] addIndex:aFace];
		if (aFrameIndex != TKFrameIndexNone) [(NSMutableIndexSet *)[self valueForKeyPath:TKImageAllFrameIndexesKey] addIndex:aFrameIndex];
		if (aMipmapIndex != TKMipmapIndexNone) [(NSMutableIndexSet *)[self valueForKeyPath:TKImageAllMipmapIndexesKey] addIndex:aMipmapIndex];
		
		
		NSUInteger sliceCountAfter = [[self allSliceIndexes] count];
		NSUInteger faceCountAfter = [[self allFaceIndexes] count];
		NSUInteger frameCountAfter = [[self allFrameIndexes] count];
		NSUInteger mipmapCountAfter = [[self allMipmapIndexes] count];
		
		
		if (sliceCountAfter > sliceCountBefore) {
			[self willChangeValueForKey:@"sliceCount"];
			[self willChangeValueForKey:@"isDepthTexture"];
			
			sliceCount += 1;
			isDepthTexture = (sliceCount > 0);
			
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
			isAnimated = (frameCount > 0);
			
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
		
//	NSLog(@"[%@ %@] ******** CALLING [super addRepresentation:representation] ********", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	[super addRepresentation:aRepresentation];
	
	if (imageType == TKEmptyImageType) {
		[self setImageType:TKSFTIImageType];
	}
}


- (void)removeRepresentationForSliceIndex:(NSUInteger)aSliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)aFrameIndex mipmapIndex:(NSUInteger)aMipmapIndex {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (aSliceIndex != TKSliceIndexNone) {
		// it's a depth texture
		NSMutableDictionary *sliceDict = [reps objectForKey:TKImageKey(aSliceIndex)];
		if (sliceDict) {
			TKImageRep *rep = [sliceDict objectForKey:TKImageRepKey];
			if (rep) {
				[super removeRepresentation:rep];
			}
			[sliceDict removeObjectForKey:TKImageRepKey];
		}
	} else {
		// it's a regular texture
		
		NSMutableDictionary *sliceDict = [reps objectForKey:TKImageNotApplicableKey];
		if (sliceDict == nil) return;
		
		NSMutableDictionary *faceDict = [sliceDict objectForKey:TKImageKey(aFace)];
		if (faceDict == nil) return;
		
		NSMutableDictionary *frameDict = [faceDict objectForKey:TKImageKey(aFrameIndex)];
		if (frameDict == nil) return;
		
		NSMutableDictionary *mipmapDict = [frameDict objectForKey:TKImageKey(aMipmapIndex)];
		if (mipmapDict == nil) return;
		
		TKImageRep *rep = [mipmapDict objectForKey:TKImageRepKey];
		if (rep == nil) return;
		
//		NSIndexPath
		
		
		NSUInteger sliceCountBefore = [[self allSliceIndexes] count];
		NSUInteger faceCountBefore = [[self allFaceIndexes] count];
		NSUInteger frameCountBefore = [[self allFrameIndexes] count];
		NSUInteger mipmapCountBefore = [[self allMipmapIndexes] count];
		
		NSMutableIndexSet *sliceIndexes = (NSMutableIndexSet *)[self valueForKeyPath:TKImageAllSliceIndexesKey];
		[sliceIndexes removeAllIndexes];
		
		if (aFace != TKFaceNone) {
			
		}
		
		if (aFrameIndex != TKFrameIndexNone) {
			
		}
		
		if (aMipmapIndex != TKMipmapIndexNone) {
			
			
		}
		
		
		if (aFace != TKFaceNone) [(NSMutableIndexSet *)[self valueForKeyPath:TKImageAllFaceIndexesKey] removeIndex:aFace];
		if (aFrameIndex != TKFrameIndexNone) [(NSMutableIndexSet *)[self valueForKeyPath:TKImageAllFrameIndexesKey] removeIndex:aFrameIndex];
		if (aMipmapIndex != TKMipmapIndexNone) [(NSMutableIndexSet *)[self valueForKeyPath:TKImageAllMipmapIndexesKey] removeIndex:aMipmapIndex];
		
		NSUInteger sliceCountAfter = [[self allSliceIndexes] count];
		NSUInteger faceCountAfter = [[self allFaceIndexes] count];
		NSUInteger frameCountAfter = [[self allFrameIndexes] count];
		NSUInteger mipmapCountAfter = [[self allMipmapIndexes] count];
		
		if (sliceCountAfter < sliceCountBefore) {
			[self willChangeValueForKey:@"sliceCount"];
			[self willChangeValueForKey:@"isDepthTexture"];
			
			sliceCount -= 1;
			isDepthTexture = (sliceCount > 0);
			
			[self didChangeValueForKey:@"isDepthTexture"];
			[self didChangeValueForKey:@"sliceCount"];
		}
		
		if (faceCountAfter < faceCountBefore) {
			[self willChangeValueForKey:@"faceCount"];
			[self willChangeValueForKey:@"isCubemap"];
			[self willChangeValueForKey:@"isSpheremap"];
			
			faceCount -= 1;
			isCubemap = (faceCount == 6);
			isSpheremap = (faceCount == 7);
			
			[self didChangeValueForKey:@"isSpheremap"];
			[self didChangeValueForKey:@"isCubemap"];
			[self didChangeValueForKey:@"faceCount"];
		}
		
		if (frameCountAfter < frameCountBefore) {
			[self willChangeValueForKey:@"frameCount"];
			[self willChangeValueForKey:@"isAnimated"];
			
			frameCount -= 1;
			isAnimated = (frameCount > 0);
			
			[self didChangeValueForKey:@"isAnimated"];
			[self didChangeValueForKey:@"frameCount"];
		}
		
		if (mipmapCountAfter < mipmapCountBefore) {
			[self willChangeValueForKey:@"mipmapCount"];
			[self willChangeValueForKey:@"hasMipmaps"];
			
			mipmapCount -= 1;
			hasMipmaps = (mipmapCount > 1);
			
			[self didChangeValueForKey:@"hasMipmaps"];
			[self didChangeValueForKey:@"mipmapCount"];
		}
		
		[super removeRepresentation:rep];
		
		[frameDict removeObjectForKey:TKImageKey(aMipmapIndex)];
		
//		[mipmapDict removeObjectForKey:TKImageRepKey];
	}
	
	if ([[self representations] count] == 0) {
		[self setImageType:TKEmptyImageType];
	}
}



//- (void)removeRepresentationForSliceIndex:(NSUInteger)aSliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)aFrameIndex mipmapIndex:(NSUInteger)aMipmapIndex {
//#if TK_DEBUG
////	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	if (aSliceIndex != TKSliceIndexNone) {
//		// it's a depth texture
//		NSMutableDictionary *sliceDict = [reps objectForKey:TKImageKey(aSliceIndex)];
//		if (sliceDict) {
//			TKImageRep *rep = [sliceDict objectForKey:TKImageRepKey];
//			if (rep) {
//				[self removeObserverForImageRep:rep];
//				[super removeRepresentation:rep];
//			}
//			[sliceDict removeObjectForKey:TKImageRepKey];
//		}
//	} else {
//		// it's a regular texture
//		
//		NSMutableDictionary *sliceDict = [reps objectForKey:TKImageNotApplicableKey];
//		if (sliceDict) {
//			NSMutableDictionary *faceDict = [sliceDict objectForKey:TKImageKey(aFace)];
//			if (faceDict) {
//				NSMutableDictionary *frameDict = [faceDict objectForKey:TKImageKey(aFrameIndex)];
//				if (frameDict) {
//					NSMutableDictionary *mipmapDict = [frameDict objectForKey:TKImageKey(aMipmapIndex)];
//					if (mipmapDict) {
//						TKImageRep *rep = [mipmapDict objectForKey:TKImageRepKey];
//						
//						if (rep) {
//							
//							NSUInteger sliceCountBefore = [[self allSliceIndexes] count];
//							NSUInteger faceCountBefore = [[self allFaceIndexes] count];
//							NSUInteger frameCountBefore = [[self allFrameIndexes] count];
//							NSUInteger mipmapCountBefore = [[self allMipmapIndexes] count];
//							
//							NSMutableIndexSet *sliceIndexes = (NSMutableIndexSet *)[self valueForKeyPath:TKImageAllSliceIndexesKey];
//							[sliceIndexes removeAllIndexes];
//							
//							if (aFace != TKFaceNone) [(NSMutableIndexSet *)[self valueForKeyPath:TKImageAllFaceIndexesKey] removeIndex:aFace];
//							if (aFrameIndex != TKFrameIndexNone) [(NSMutableIndexSet *)[self valueForKeyPath:TKImageAllFrameIndexesKey] removeIndex:aFrameIndex];
//							if (aMipmapIndex != TKMipmapIndexNone) [(NSMutableIndexSet *)[self valueForKeyPath:TKImageAllMipmapIndexesKey] removeIndex:aMipmapIndex];
//							
//							NSUInteger sliceCountAfter = [[self allSliceIndexes] count];
//							NSUInteger faceCountAfter = [[self allFaceIndexes] count];
//							NSUInteger frameCountAfter = [[self allFrameIndexes] count];
//							NSUInteger mipmapCountAfter = [[self allMipmapIndexes] count];
//							
//							if (sliceCountAfter < sliceCountBefore) {
//								[self willChangeValueForKey:@"sliceCount"];
//								[self willChangeValueForKey:@"isDepthTexture"];
//								
//								sliceCount -= 1;
//								isDepthTexture = (sliceCount > 0);
//								
//								[self didChangeValueForKey:@"isDepthTexture"];
//								[self didChangeValueForKey:@"sliceCount"];
//							}
//							
//							if (faceCountAfter < faceCountBefore) {
//								[self willChangeValueForKey:@"faceCount"];
//								[self willChangeValueForKey:@"isCubemap"];
//								[self willChangeValueForKey:@"isSpheremap"];
//								
//								faceCount -= 1;
//								isCubemap = (faceCount == 6);
//								isSpheremap = (faceCount == 7);
//								
//								[self didChangeValueForKey:@"isSpheremap"];
//								[self didChangeValueForKey:@"isCubemap"];
//								[self didChangeValueForKey:@"faceCount"];
//							}
//							
//							if (frameCountAfter < frameCountBefore) {
//								[self willChangeValueForKey:@"frameCount"];
//								[self willChangeValueForKey:@"isAnimated"];
//								
//								frameCount -= 1;
//								isAnimated = (frameCount > 0);
//								
//								[self didChangeValueForKey:@"isAnimated"];
//								[self didChangeValueForKey:@"frameCount"];
//							}
//							
//							if (mipmapCountAfter < mipmapCountBefore) {
//								[self willChangeValueForKey:@"mipmapCount"];
//								[self willChangeValueForKey:@"hasMipmaps"];
//								
//								mipmapCount -= 1;
//								hasMipmaps = (mipmapCount > 1);
//								
//								[self didChangeValueForKey:@"hasMipmaps"];
//								[self didChangeValueForKey:@"mipmapCount"];
//							}
//							
//							
//							
//							[self removeObserverForImageRep:rep];
//							[super removeRepresentation:rep];
//						}
//						
//						[mipmapDict removeObjectForKey:TKImageRepKey];
//					}
//				}
//			}
//		}
//		
//	}
//	
//}
//

#pragma mark END primary accessors
#pragma mark -



//- (void)generateMipmapsUsingFilter:(TKMipmapGenerationType)filterType {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	NSParameterAssert(filterType != TKMipmapGenerationNoMipmaps);
//	
//	[self removeMipmaps];
//	
//	if (isDepthTexture) {
//		// illegal operation
//		
//	} else if ((isCubemap || isSpheremap) && isAnimated) {
//		
//		NSArray *sourceImageReps = [self representationsForFaceIndexes:[self allFaceIndexes] frameIndexes:[self allFrameIndexes] mipmapIndexes:[self firstMipmapIndexSet]];
//		
//		for (TKImageRep *imageRep in sourceImageReps) {
//			NSArray *mipmapImageReps = [imageRep mipmapImageRepsUsingFilter:filterType];
//			
//			if (mipmapImageReps) {
//				[self setRepresentations:mipmapImageReps
//						  forFaceIndexes:[NSIndexSet indexSetWithIndex:[imageRep face]]
//							frameIndexes:[NSIndexSet indexSetWithIndex:[imageRep frameIndex]]
//						   mipmapIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [mipmapImageReps count])]];
//			}
//		}
//		
//	} else if ((isCubemap || isSpheremap) && !isAnimated) {
//		
//		NSArray *sourceImageReps = [self representationsForFaceIndexes:[self allFaceIndexes] mipmapIndexes:[self firstMipmapIndexSet]];
//		
//		for (TKImageRep *imageRep in sourceImageReps) {
//			NSArray *mipmapImageReps = [imageRep mipmapImageRepsUsingFilter:filterType];
//			
//			if (mipmapImageReps) {
//				[self setRepresentations:mipmapImageReps
//						  forFaceIndexes:[NSIndexSet indexSetWithIndex:[imageRep face]]
//						   mipmapIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [mipmapImageReps count])]];
//			}
//		}
//		
//	} else if (isAnimated) {
//		NSArray *sourceImageReps = [self representationsForFrameIndexes:[self allFrameIndexes] mipmapIndexes:[self firstMipmapIndexSet]];
//		
//		for (TKImageRep *imageRep in sourceImageReps) {
//			NSArray *mipmapImageReps = [imageRep mipmapImageRepsUsingFilter:filterType];
//			
//			if (mipmapImageReps) {
//				[self setRepresentations:mipmapImageReps
//						 forFrameIndexes:[NSIndexSet indexSetWithIndex:[imageRep frameIndex]]
//						   mipmapIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [mipmapImageReps count])]];
//			}
//		}
//	} else {
//		TKImageRep *sourceImageRep = [self representationForMipmapIndex:0];
//		NSArray *mipmapImageReps = [sourceImageRep mipmapImageRepsUsingFilter:filterType];
//		if (mipmapImageReps) {
//			[self setRepresentations:mipmapImageReps forMipmapIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [mipmapImageReps count])]];
//		}
//	}
//	
//	
//}
//
//
//- (void)removeMipmaps {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	if (isDepthTexture) {
//		// illegal operation
//		
//	} else if ((isCubemap || isSpheremap) && isAnimated) {
//		
//		[self removeRepresentationsForFaceIndexes:[self allFaceIndexes] frameIndexes:[self allFrameIndexes] mipmapIndexes:[self mipmapIndexes]];
//		
//	} else if ((isCubemap || isSpheremap) && !isAnimated) {
//		
//		[self removeRepresentationsForFaceIndexes:[self allFaceIndexes] mipmapIndexes:[self mipmapIndexes]];
//		
//	} else if (isAnimated) {
//		
//		[self removeRepresentationsForFrameIndexes:[self allFrameIndexes] mipmapIndexes:[self mipmapIndexes]];
//		
//	} else {
//		
//		[self removeRepresentationsForMipmapIndexes:[self mipmapIndexes]];
//	}
//}
//



- (NSData *)DDSRepresentationWithOptions:(NSDictionary *)options {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self DDSRepresentationUsingFormat:[TKDDSImageRep defaultFormat] quality:[TKImageRep defaultDXTCompressionQuality] options:options];
}


- (NSData *)DDSRepresentationUsingFormat:(TKDDSFormat)aFormat quality:(TKDXTCompressionQuality)aQuality options:(NSDictionary *)options {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [TKDDSImageRep DDSRepresentationOfImageRepsInArray:[self representations] usingFormat:aFormat quality:aQuality options:options];
}



- (NSData *)VTFRepresentationWithOptions:(NSDictionary *)options {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self VTFRepresentationUsingFormat:[TKVTFImageRep defaultFormat] quality:[TKImageRep defaultDXTCompressionQuality] options:options];
}


- (NSData *)VTFRepresentationUsingFormat:(TKVTFFormat)aFormat quality:(TKDXTCompressionQuality)aQuality options:(NSDictionary *)options {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [TKVTFImageRep VTFRepresentationOfImageRepsInArray:[self representations] usingFormat:aFormat quality:aQuality options:options];
}


- (NSData *)dataForType:(NSString *)utiType properties:(NSDictionary *)properties {
#if TK_DEBUG
	NSLog(@"[%@ %@] utiType == %@, properties == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), utiType, properties);
#endif
	if ([[self representations] count] == 0) {
		NSLog(@"[%@ %@] NOTICE: image has no representations; returning nil!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return nil;
	}
	
	NSMutableDictionary *mProperties = [[properties deepMutableCopy] autorelease];
	TKImageRep *targetImageRep = [TKImageRep largestRepresentationInArray:[self representations]];
	
#if TK_DEBUG
	NSLog(@"[%@ %@] targetImageRep == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), targetImageRep);
#endif
	
	[mProperties setObject:(id)kCGImagePropertyColorModelRGB forKey:(id)kCGImagePropertyColorModel];
	NSMutableDictionary *TIFFDictionary = [mProperties objectForKey:(id)kCGImagePropertyTIFFDictionary];
	if (TIFFDictionary == nil) {
		TIFFDictionary = [NSMutableDictionary dictionary];
		[mProperties setObject:TIFFDictionary forKey:(id)kCGImagePropertyTIFFDictionary];
	}
	
	[TIFFDictionary setObject:[NSString stringWithFormat:@"%@ %@ (%@)",
							   [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"],
							   [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
							   [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]]
	 
					   forKey:(id)kCGImagePropertyTIFFSoftware];
	
	NSMutableData *imageData = [NSMutableData data];
	
	CGImageDestinationRef imageDest = CGImageDestinationCreateWithData((CFMutableDataRef)imageData , (CFStringRef)utiType, 1, NULL);
	if (imageDest == NULL) {
		NSLog(@"[%@ %@] ERROR: CGImageDestinationCreateWithData() returned NULL", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return nil;
	}
	
	CGImageRef targetImageRef = [targetImageRep CGImage];
	
	CGImageDestinationAddImage(imageDest, targetImageRef, (CFDictionaryRef)mProperties);
	CGImageDestinationFinalize(imageDest);
	
	CFRelease(imageDest);
	return [[imageData copy] autorelease];
}



typedef struct TKImageTypeDescription {
	TKImageType		imageType;
	NSString		*description;
} TKImageTypeDescription;

static const TKImageTypeDescription TKImageTypeDescriptionTable[] = {
	{ TKVTFImageType, @"TKVTFImageType" },
	{ TKDDSImageType, @"TKDDSImageType" },
	{ TKSFTIImageType, @"TKSFTIImageType" },
	{ TKRegularImageType, @"TKRegularImageType" },
	{ TKEmptyImageType, @"TKEmptyImageType" },
	{ TKUnknownImageType, @"TKUnknownImageType" }
};
static const NSUInteger TKImageTypeDescriptionTableCount = sizeof(TKImageTypeDescriptionTable)/sizeof(TKImageTypeDescriptionTable[0]);

static inline NSString *NSStringFromImageType(TKImageType aType) {
	for (NSUInteger i = 0; i < TKImageTypeDescriptionTableCount; i++) {
		if (aType == TKImageTypeDescriptionTable[i].imageType) {
			return TKImageTypeDescriptionTable[i].description;
		}
	}
	return @"<unknown>";
}


- (NSString *)description {
//	NSMutableString *description = [NSMutableString stringWithString:[super description]];
	NSMutableString *description = [NSMutableString stringWithFormat:@"<%@ %p> size == %@", NSStringFromClass([self class]), self, NSStringFromSize([self size])];
	[description appendFormat:@"\n"];
	[description appendFormat:@"imageType == %@\n", NSStringFromImageType(imageType)];
	[description appendFormat:@"sliceCount == %lu\n", (unsigned long)sliceCount];
	[description appendFormat:@"faceCount == %lu\n", (unsigned long)faceCount];
	[description appendFormat:@"frameCount == %lu\n", (unsigned long)frameCount];
	[description appendFormat:@"mipmapCount == %lu\n", (unsigned long)mipmapCount];
	[description appendFormat:@"reps == %@", reps];
	return description;
}

@end



