//
//  TKImage.m
//  Texture Kit
//
//  Created by Mark Douma on 11/5/2010.
//  Copyright (c) 2010-2014 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKImage.h>
#import <TextureKit/TextureKitDefines.h>
#import "TKFoundationAdditions.h"
#import <CoreServices/CoreServices.h>
#import "TKPrivateInterfaces.h"


// Notes:
// NSImage's initWithSize: appears to be the designated initializer.
// `init`, `initWithContentsOfFile:`, `initWithData:`, and `initWithContentsOfURL:`
// all call `initWithSize:`.



#define TK_DEBUG 1

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


static NSString * TKImageNotApplicableKey	= nil;


static const UInt8 TKSFTextureImageMagic[] = {
	'b', 'p', 'l', 'i', 's', 't', '0', '0'
};

NSData * TKSFTextureImageMagicData	= nil;


static NSString * const TKImageAllSliceIndexesKey	= @"allIndexes.sliceIndexes";
static NSString * const TKImageAllFaceIndexesKey	= @"allIndexes.faceIndexes";
static NSString * const TKImageAllFrameIndexesKey	= @"allIndexes.frameIndexes";
static NSString * const TKImageAllMipmapIndexesKey	= @"allIndexes.mipmapIndexes";




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

@synthesize isAnimated;
@synthesize frameCount;
@synthesize mipmapCount;
@synthesize faceCount;
@synthesize sliceCount;
@synthesize hasAlpha;
@synthesize hasMipmaps;
@synthesize version;
@synthesize compression;
@synthesize imageType;
@synthesize isDepthTexture;
@synthesize isEnvironmentMap;
@synthesize isCubemap;
@synthesize isSpheremap;

@synthesize allIndexes = _TK_private;

@dynamic hasDimensionsThatArePowerOfTwo;
@dynamic environmentMapSize;


#pragma mark - init/dealloc

- (id)initWithSize:(NSSize)aSize {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithSize:aSize])) {
		
		reps = [[NSMutableDictionary alloc] init];
		
		imageType = TKEmptyImageType;
		
		[self setAllIndexes:[NSMutableDictionary dictionary]];
		
		[self setValue:[NSMutableIndexSet indexSet] forKeyPath:TKImageAllSliceIndexesKey];
		[self setValue:[NSMutableIndexSet indexSet] forKeyPath:TKImageAllFaceIndexesKey];
		[self setValue:[NSMutableIndexSet indexSet] forKeyPath:TKImageAllFrameIndexesKey];
		[self setValue:[NSMutableIndexSet indexSet] forKeyPath:TKImageAllMipmapIndexesKey];
		
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
	
	copy.imageType = self.imageType;
	
	return copy;
}


- (id)initWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithCoder:coder])) {
		
		hasAlpha = [[coder decodeObjectForKey:TKImageHasAlphaKey] boolValue];

		version = [[coder decodeObjectForKey:TKImageVersionKey] retain];
		compression = [[coder decodeObjectForKey:TKImageCompressionKey] retain];
		
		imageType = [[coder decodeObjectForKey:TKImageTypeKey] unsignedIntegerValue];
		
		reps = [[NSMutableDictionary alloc] init];
		
		[self setAllIndexes:[NSMutableDictionary dictionary]];
		
		[self setValue:[NSMutableIndexSet indexSet] forKeyPath:TKImageAllSliceIndexesKey];
		[self setValue:[NSMutableIndexSet indexSet] forKeyPath:TKImageAllFaceIndexesKey];
		[self setValue:[NSMutableIndexSet indexSet] forKeyPath:TKImageAllFrameIndexesKey];
		[self setValue:[NSMutableIndexSet indexSet] forKeyPath:TKImageAllMipmapIndexesKey];
		
		[self addRepresentations:[coder decodeObjectForKey:TKImageImageRepsKey]];
		
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super encodeWithCoder:coder];
	
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
	return [self initWithContentsOfFile:fileName error:NULL];
}


- (id)initWithContentsOfFile:(NSString *)fileName error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self initWithContentsOfURL:[NSURL fileURLWithPath:fileName] error:outError];
}


- (id)initWithContentsOfURL:(NSURL *)url {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self initWithContentsOfURL:url error:NULL];
}


- (id)initWithContentsOfURL:(NSURL *)url error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self initWithData:[NSData dataWithContentsOfURL:url] error:outError];
}


- (id)initWithData:(NSData *)data {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self initWithData:data error:NULL];
}


- (id)initWithData:(NSData *)aData error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self initWithData:aData firstRepresentationOnly:NO error:outError];
}


- (id)initWithData:(NSData *)aData firstRepresentationOnly:(BOOL)firstRepOnly error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (firstRepOnly) {
		// load only first rep if it's a TKImageRep subclass, otherwise, pass to super
		
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
						self.compression = [TKVTFImageRep localizedNameOfFormat:[(TKVTFImageRep *)imageRep format]];
						self.version = [imageRep.imageProperties objectForKey:TKImagePropertyVersion];
						
					} else if ([imageRep isKindOfClass:[TKDDSImageRep class]]) {
						[self setImageType:TKDDSImageType];
						self.compression = [TKDDSImageRep localizedNameOfFormat:[(TKDDSImageRep *)imageRep format]];
						
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
	
	if ([magicData isEqualToData:TKSFTextureImageMagicData]) {
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
		/* 
		 It's one of the following:
		 •	DDS data that will be handled by TKDDSImageRep
		 •	VTF data that will be handled by TKVTFImageRep
		 •	regular image data that will be handled by TKImageRep (via ImageIO.framework) 
		 
		 
		 Whichever the case, we used to allow super (NSImage) to handle the creation of the image reps from the data. NSImage will then call `addRepresentations:` to add the reps to the image. We override `addRepresentations:` to examine the incoming image reps and set the properties of the TKImage properly.
		 
		 UPDATE: Instead of allowing NSImage to handle the creation, we create the image reps ourselves which allows us to retrieve back an NSError if there is a problem (for example, an unsupported VTF or DDS format).
		 
		 */
		
		Class imageRepClass = [NSImageRep imageRepClassForData:aData];
		
		if (![imageRepClass isSubclassOfClass:[TKImageRep class]]) {
			NSLog(@"[%@ %@] [NSImageRep imageRepClassForData:] returned <%@> %@, which is not a TKImageRep or one of its subclasses. Bailing....", NSStringFromClass([self class]), NSStringFromSelector(_cmd), imageRepClass, NSStringFromClass(imageRepClass));
			[self release];
			return nil;
		}
		
		NSArray *imageReps = [imageRepClass imageRepsWithData:aData error:outError];
		
		if (imageReps == nil) {
			[self release];
			return nil;
		}
		
		TKImageRep *largestRep = [TKImageRep largestRepresentationInArray:imageReps];
		
		if ((self = [self initWithSize:largestRep.size])) {
			[self addRepresentations:imageReps];
			
			if ([largestRep isKindOfClass:[TKVTFImageRep class]]) {
				imageType = TKVTFImageType;
				self.compression = [TKVTFImageRep localizedNameOfFormat:[(TKVTFImageRep *)largestRep format]];
				self.version = [largestRep.imageProperties objectForKey:TKImagePropertyVersion];
				
			} else if ([largestRep isKindOfClass:[TKDDSImageRep class]]) {
				imageType = TKDDSImageType;
				self.compression = [TKDDSImageRep localizedNameOfFormat:[(TKDDSImageRep *)largestRep format]];
			} else {
				imageType = TKRegularImageType;
			}
			[self setSize:largestRep.size];
			[self setAlpha:largestRep.hasAlpha];
		}
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
	
	[_TK_private release];
	
	[super dealloc];
}

#pragma mark - Add/Remove representations


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
		([imageRep isKindOfClass:[TKImageRep class]] ? [tkRepsToAdd addObject:imageRep] : [repsToAdd addObject:imageRep]);
	}
	
	if ([tkRepsToAdd count]) {
		NSMutableIndexSet *sliceIndexes = [NSMutableIndexSet indexSet];
		NSMutableIndexSet *faceIndexes = [NSMutableIndexSet indexSet];
		NSMutableIndexSet *frameIndexes = [NSMutableIndexSet indexSet];
		NSMutableIndexSet *mipmapIndexes = [NSMutableIndexSet indexSet];
		
		for (TKImageRep *anImageRep in tkRepsToAdd) {
			if (anImageRep.sliceIndex != TKSliceIndexNone) [sliceIndexes addIndex:anImageRep.sliceIndex];
			if (anImageRep.face != TKFaceNone) [faceIndexes addIndex:anImageRep.face];
			if (anImageRep.frameIndex != TKFrameIndexNone) [frameIndexes addIndex:anImageRep.frameIndex];
			if (anImageRep.mipmapIndex != TKMipmapIndexNone) [mipmapIndexes addIndex:anImageRep.mipmapIndex];
		}
		
#if TK_DEBUG
//		NSLog(@"[%@ %@] sliceIndexes == %@, faceIndexes == %@, frameIndexes == %@, mipmapIndexes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sliceIndexes, faceIndexes, frameIndexes, mipmapIndexes);
#endif
		NSUInteger sliceIndexesCount = sliceIndexes.count;
		NSUInteger faceIndexesCount = faceIndexes.count;
		NSUInteger frameIndexesCount = frameIndexes.count;
		
		for (TKImageRep *tkImageRep in tkRepsToAdd) {
			
			if (sliceIndexesCount > 1) {
				// depth texture
				
				[self setRepresentation:tkImageRep forSliceIndex:tkImageRep.sliceIndex face:tkImageRep.face frameIndex:tkImageRep.frameIndex mipmapIndex:tkImageRep.mipmapIndex];
				
			} else if (faceIndexesCount && frameIndexesCount) {
				// animated environment map
				[self setRepresentation:tkImageRep forSliceIndex:TKSliceIndexNone face:tkImageRep.face frameIndex:tkImageRep.frameIndex mipmapIndex:tkImageRep.mipmapIndex];
				
			} else if (faceIndexesCount) {
				// regular environment map
				[self setRepresentation:tkImageRep forSliceIndex:TKSliceIndexNone face:tkImageRep.face frameIndex:TKFrameIndexNone mipmapIndex:tkImageRep.mipmapIndex];
				
			} else if (frameIndexesCount) {
				// animated texture
				[self setRepresentation:tkImageRep forSliceIndex:TKSliceIndexNone face:TKFaceNone frameIndex:tkImageRep.frameIndex mipmapIndex:tkImageRep.mipmapIndex];
				
			} else {
				// mipmapped texture
				[self setRepresentation:tkImageRep forSliceIndex:TKSliceIndexNone face:TKFaceNone frameIndex:TKFrameIndexNone mipmapIndex:tkImageRep.mipmapIndex];
				
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


- (void)removeRepresentations:(NSArray *)imageReps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	for (NSImageRep *imageRep in imageReps) {
		[self removeRepresentation:imageRep];
	}
}


#pragma mark -


- (NSImageRep *)bestRepresentationForDevice:(NSDictionary *)deviceDescription {
	NSImageRep *bestRep = [super bestRepresentationForDevice:deviceDescription];
#if TK_DEBUG
	NSLog(@"[%@ %@] deviceDescription == %@, super's bestRep == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), deviceDescription, bestRep);
#endif
	return bestRep;
}


- (NSImageRep *)bestRepresentationForRect:(NSRect)rect context:(NSGraphicsContext *)referenceContext hints:(NSDictionary *)hints {
	NSImageRep *bestRep = [super bestRepresentationForRect:rect context:referenceContext hints:hints];
#if TK_DEBUG
	NSLog(@"[%@ %@] rect == %@, context == %@, hints == %@, bestRep == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(rect), referenceContext, hints, bestRep);
#endif
	return bestRep;
}


#pragma mark - drawing environment map images

- (NSSize)environmentMapSize {
	if (self.isEnvironmentMap) {
		return NSMakeSize(self.size.width * 4, self.size.height * 3);
	}
	return NSZeroSize;
}


- (void)drawEnvironmentMapInRect:(NSRect)rect {
	NSAssert(self.isEnvironmentMap, @"self.isEnvironmentMap");
#if TK_DEBUG
	NSLog(@"[%@ %@] rect == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(rect));
#endif
	NSArray *faceReps = nil;
	
	if (self.isAnimated) {
		faceReps = [self representationsForFaceIndexes:[self allFaceIndexes] frameIndexes:[self firstFrameIndexSet] mipmapIndexes:[self firstMipmapIndexSet]];
	} else {
		faceReps = [self representationsForFaceIndexes:[self allFaceIndexes] mipmapIndexes:[self firstMipmapIndexSet]];
	}
	
#if TK_DEBUG
	NSLog(@"[%@ %@] faceReps == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), faceReps);
#endif
	
	NSSize environmentMapSize = self.environmentMapSize;
	NSRect environmentMapRect = NSMakeRect(0.0, 0.0, environmentMapSize.width, environmentMapSize.height);
	
	for (TKImageRep *faceRep in faceReps) {
		if (faceRep.face < TKFaceSphereMap) {
			[faceRep drawInRect:[TKImageRep rectForFace:faceRep.face inEnvironmentMapRect:environmentMapRect]];
		}
	}
}

#pragma mark -


- (BOOL)hasDimensionsThatArePowerOfTwo {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	for (NSImageRep *imageRep in self.representations) {
		if ([imageRep isKindOfClass:[TKImageRep class]]) {
			if ([(TKImageRep *)imageRep hasDimensionsThatArePowerOfTwo] == NO) return NO;
		}
	}
	return YES;
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


#pragma mark - depth texture images

/* for depth texture images */
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



#pragma mark - non-animated texture images

/* for static, non-animated texture images */
- (TKImageRep *)representationForMipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
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


#pragma mark - animated (multi-frame) texture images

/* for animated (multi-frame) texture images */
- (TKImageRep *)representationForFrameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex {
#if TK_DEBUG
//	NSLog(@"[%@ %@] frameIndex == %lu, mipmapIndex == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)frameIndex, (unsigned long)mipmapIndex);
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
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
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


#pragma mark - multi-sided texture images

/* for multi-sided texture images */
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


#pragma mark - animated (multi-frame), multi-sided texture images

/* for animated (multi-frame), multi-sided texture images */
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
#pragma mark primitive accessors

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
			[self willChangeValueForKey:@"isEnvironmentMap"];
			
			faceCount += 1;
			isCubemap = (faceCount == 6);
			isSpheremap = (faceCount == 7);
			isEnvironmentMap = (faceCount > 0);
			
			[self didChangeValueForKey:@"faceCount"];
			[self didChangeValueForKey:@"isCubemap"];
			[self didChangeValueForKey:@"isSpheremap"];
			[self didChangeValueForKey:@"isEnvironmentMap"];
			
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
		if (sliceDict == nil) return;
		
		TKImageRep *rep = [sliceDict objectForKey:TKImageRepKey];
		if (rep == nil) return;
		
		[(NSMutableIndexSet *)[self valueForKeyPath:TKImageAllSliceIndexesKey] removeIndex:aSliceIndex];
		
		[self willChangeValueForKey:@"sliceCount"];
		[self willChangeValueForKey:@"isDepthTexture"];
		
		sliceCount -= 1;
		isDepthTexture = (sliceCount > 0);
		
		[self didChangeValueForKey:@"sliceCount"];
		[self didChangeValueForKey:@"isDepthTexture"];
		
		[super removeRepresentation:rep];
		
		[sliceDict removeObjectForKey:TKImageRepKey];
		
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
		
		
		NSUInteger sliceCountBefore = [[self allSliceIndexes] count];
		NSUInteger faceCountBefore = [[self allFaceIndexes] count];
		NSUInteger frameCountBefore = [[self allFrameIndexes] count];
		NSUInteger mipmapCountBefore = [[self allMipmapIndexes] count];
		
		NSMutableIndexSet *sliceIndexes = (NSMutableIndexSet *)[self valueForKeyPath:TKImageAllSliceIndexesKey];
		[sliceIndexes removeAllIndexes];
		
		
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
			[self willChangeValueForKey:@"isEnvironmentMap"];
			
			faceCount -= 1;
			isCubemap = (faceCount == 6);
			isSpheremap = (faceCount == 7);
			isEnvironmentMap = (faceCount > 0);
			
			[self didChangeValueForKey:@"isEnvironmentMap"];
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
	}
	
	if ([[self representations] count] == 0) {
		[self setImageType:TKEmptyImageType];
	}
}


#pragma mark END primitive accessors
#pragma mark -
#pragma mark DDS


- (NSData *)DDSRepresentationWithOptions:(NSDictionary *)options error:(NSError **)outError {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self DDSRepresentationUsingFormat:[TKDDSImageRep defaultFormat] quality:[TKImageRep defaultDXTCompressionQuality] container:[TKDDSImageRep defaultContainer] options:options error:outError];
}


- (NSData *)DDSRepresentationUsingFormat:(TKDDSFormat)aFormat quality:(TKDXTCompressionQuality)aQuality container:(TKDDSContainer)container options:(NSDictionary *)options error:(NSError **)outError {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [TKDDSImageRep DDSRepresentationOfImageRepsInArray:[self representations] usingFormat:aFormat quality:aQuality container:container options:options error:outError];
}


#pragma mark - VTF

- (NSData *)VTFRepresentationWithOptions:(NSDictionary *)options error:(NSError **)outError {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self VTFRepresentationUsingFormat:[TKVTFImageRep defaultFormat] quality:[TKImageRep defaultDXTCompressionQuality] options:options error:outError];
}


- (NSData *)VTFRepresentationUsingFormat:(TKVTFFormat)aFormat quality:(TKDXTCompressionQuality)aQuality options:(NSDictionary *)options error:(NSError **)outError {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [TKVTFImageRep VTFRepresentationOfImageRepsInArray:[self representations] usingFormat:aFormat quality:aQuality options:options error:outError];
}


#pragma mark - standard image formats

- (NSData *)representationUsingImageType:(NSString *)utiType properties:(NSDictionary *)properties {
#if TK_DEBUG
	NSLog(@"[%@ %@] utiType == %@, properties == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), utiType, properties);
#endif
	if ([[self representations] count] == 0) {
		NSLog(@"[%@ %@] NOTICE: image has no representations; returning nil!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return nil;
	}
	
	NSArray *imageRepsForWriting = nil;
	
	if ([utiType isEqualToString:(NSString *)kUTTypeTIFF]) {
		if (self.faceCount && self.frameCount) {
			imageRepsForWriting = [self representationsForFaceIndexes:[self allFaceIndexes] frameIndexes:[self allFrameIndexes] mipmapIndexes:[self firstMipmapIndexSet]];
		} else if (self.faceCount) {
			imageRepsForWriting = [self representationsForFaceIndexes:[self allFaceIndexes] mipmapIndexes:[self firstMipmapIndexSet]];
		} else if (self.frameCount) {
			imageRepsForWriting = [self representationsForFrameIndexes:[self allFrameIndexes] mipmapIndexes:[self firstMipmapIndexSet]];
		} else {
			imageRepsForWriting = [self representations];
		}
	} else {
		imageRepsForWriting = [NSArray arrayWithObject:[TKImageRep largestRepresentationInArray:[self representations]]];
	}
	
#if TK_DEBUG
	NSLog(@"[%@ %@] imageRepsForWriting == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), imageRepsForWriting);
#endif
	
	return [TKImageRep representationOfImageRepsInArray:imageRepsForWriting usingImageType:utiType properties:properties];
}



#pragma mark - resizing

- (void)resizeRepresentationsUsingResizeMode:(TKResizeMode)resizeMode resizeFilter:(TKResizeFilter)resizeFilter {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSArray *oldRepresentations = [[self representations] retain];
	
	[self removeRepresentations:self.representations];
	
	NSMutableArray *resizedReps = [NSMutableArray array];
	
	for (NSImageRep *imageRep in oldRepresentations) {
		if (![imageRep isKindOfClass:[TKImageRep class]]) continue;
		
		TKImageRep *resizedImageRep = [(TKImageRep *)imageRep imageRepByResizingUsingResizeMode:resizeMode resizeFilter:resizeFilter];
		if (resizedImageRep) [resizedReps addObject:resizedImageRep];
		
	}
	
	[self addRepresentations:resizedReps];
	
	[oldRepresentations release];
	
	[self setSize:[TKImageRep powerOfTwoSizeForSize:self.size usingResizeMode:resizeMode]];
}



- (TKImage *)imageByResizingRepresentationsUsingResizeMode:(TKResizeMode)resizeMode resizeFilter:(TKResizeFilter)resizeFilter {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(resizeMode <= TKResizeModePreviousPowerOfTwo);
	NSParameterAssert(resizeFilter <= TKResizeFilterMitchell);
	
	TKImage *copiedImage = [[self copy] autorelease];
	[copiedImage resizeRepresentationsUsingResizeMode:resizeMode resizeFilter:resizeFilter];
	return copiedImage;
}



- (void)generateMipmapsUsingFilter:(TKMipmapGenerationType)filterType {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(filterType != TKMipmapGenerationNoMipmaps);
	
	[self removeMipmaps];
	
	if (isDepthTexture) {
		// illegal operation
		
	} else if ((isCubemap || isSpheremap) && isAnimated) {
		
		NSArray *sourceImageReps = [self representationsForFaceIndexes:[self allFaceIndexes] frameIndexes:[self allFrameIndexes] mipmapIndexes:[self firstMipmapIndexSet]];
		
		for (TKImageRep *imageRep in sourceImageReps) {
			NSArray *mipmapImageReps = [imageRep mipmapImageRepsUsingFilter:filterType];
			
			if (mipmapImageReps) {
				[self setRepresentations:mipmapImageReps
						  forFaceIndexes:[NSIndexSet indexSetWithIndex:[imageRep face]]
							frameIndexes:[NSIndexSet indexSetWithIndex:[imageRep frameIndex]]
						   mipmapIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [mipmapImageReps count])]];
			}
		}
		
	} else if ((isCubemap || isSpheremap) && !isAnimated) {
		
		NSArray *sourceImageReps = [self representationsForFaceIndexes:[self allFaceIndexes] mipmapIndexes:[self firstMipmapIndexSet]];
		
		for (TKImageRep *imageRep in sourceImageReps) {
			NSArray *mipmapImageReps = [imageRep mipmapImageRepsUsingFilter:filterType];
			
			if (mipmapImageReps) {
				[self setRepresentations:mipmapImageReps
						  forFaceIndexes:[NSIndexSet indexSetWithIndex:[imageRep face]]
						   mipmapIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [mipmapImageReps count])]];
			}
		}
		
	} else if (isAnimated) {
		NSArray *sourceImageReps = [self representationsForFrameIndexes:[self allFrameIndexes] mipmapIndexes:[self firstMipmapIndexSet]];
		
		for (TKImageRep *imageRep in sourceImageReps) {
			NSArray *mipmapImageReps = [imageRep mipmapImageRepsUsingFilter:filterType];
			
			if (mipmapImageReps) {
				[self setRepresentations:mipmapImageReps
						 forFrameIndexes:[NSIndexSet indexSetWithIndex:[imageRep frameIndex]]
						   mipmapIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [mipmapImageReps count])]];
			}
		}
	} else {
		TKImageRep *sourceImageRep = [self representationForMipmapIndex:0];
		NSArray *mipmapImageReps = [sourceImageRep mipmapImageRepsUsingFilter:filterType];
		if (mipmapImageReps) {
			[self setRepresentations:mipmapImageReps forMipmapIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [mipmapImageReps count])]];
		}
	}
	
	
}


- (void)removeMipmaps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (isDepthTexture) {
		// illegal operation
		
	} else if ((isCubemap || isSpheremap) && isAnimated) {
		
		[self removeRepresentationsForFaceIndexes:[self allFaceIndexes] frameIndexes:[self allFrameIndexes] mipmapIndexes:[self mipmapIndexes]];
		
	} else if ((isCubemap || isSpheremap) && !isAnimated) {
		
		[self removeRepresentationsForFaceIndexes:[self allFaceIndexes] mipmapIndexes:[self mipmapIndexes]];
		
	} else if (isAnimated) {
		
		[self removeRepresentationsForFrameIndexes:[self allFrameIndexes] mipmapIndexes:[self mipmapIndexes]];
		
	} else {
		
		[self removeRepresentationsForMipmapIndexes:[self mipmapIndexes]];
	}
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
static const NSUInteger TKImageTypeDescriptionTableCount = TK_ARRAY_SIZE(TKImageTypeDescriptionTable);

TEXTUREKIT_STATIC_INLINE NSString *TKStringFromImageType(TKImageType aType) {
	NSCParameterAssert(aType < TKImageTypeDescriptionTableCount);
	return TKImageTypeDescriptionTable[aType].description;
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithFormat:@"<%@ %p> size == %@", NSStringFromClass([self class]), self, NSStringFromSize([self size])];
	[description appendFormat:@"\n"];
	[description appendFormat:@"	imageType == %@\n", TKStringFromImageType(imageType)];
	[description appendFormat:@"	sliceCount == %lu\n", (unsigned long)sliceCount];
	[description appendFormat:@"	faceCount == %lu\n", (unsigned long)faceCount];
	[description appendFormat:@"	frameCount == %lu\n", (unsigned long)frameCount];
	[description appendFormat:@"	mipmapCount == %lu\n", (unsigned long)mipmapCount];
	[description appendFormat:@"	reps == %@", reps];
	return description;
}

@end



