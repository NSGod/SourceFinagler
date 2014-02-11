//
//  TKImageRep.m
//  Texture Kit
//
//  Created by Mark Douma on 11/5/2010.
//  Copyright (c) 2010-2013 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKImageRep.h>
#import <CoreServices/CoreServices.h>

#import <TextureKit/TKDDSImageRep.h>
#import <TextureKit/TKVTFImageRep.h>

#import "TKFoundationAdditions.h"
#import "TKPrivateInterfaces.h"



#define TK_DEBUG 0


static NSString * const TKImageRepSliceIndexKey			= @"TKImageRepSliceIndex";
static NSString * const TKImageRepFaceKey				= @"TKImageRepFace";
static NSString * const TKImageRepFrameIndexKey			= @"TKImageRepFrameIndex";
static NSString * const TKImageRepMipmapIndexKey		= @"TKImageRepMipmapIndex";

static NSString * const TKImageRepBitmapInfoKey			= @"TKImageRepBitmapInfo";
static NSString * const TKImageRepPixelFormatKey		= @"TKImageRepPixelFormat";

static NSString * const TKImageRepImagePropertiesKey	= @"TKImageRepImageProperties";


NSString * const TKImageMipmapGenerationKey				= @"TKImageMipmapGeneration";
NSString * const TKImageWrapModeKey						= @"TKImageWrapMode";
NSString * const TKImageRoundModeKey					= @"TKImageRoundMode";



typedef struct TKDXTCompressionQualityDescription {
	TKDXTCompressionQuality		compressionQuality;
	NSString					*description;
} TKDXTCompressionQualityDescription;

static const TKDXTCompressionQualityDescription TKDXTCompressionQualityDescriptionTable[] = {
	{ TKDXTCompressionLowQuality, @"Low" },
	{ TKDXTCompressionMediumQuality, @"Medium" },
	{ TKDXTCompressionHighQuality, @"High" },
	{ TKDXTCompressionHighestQuality, @"Highest" },
	{ TKDXTCompressionDefaultQuality, @"Default" },
	{ TKDXTCompressionNotApplicable, @"N/A" }
};
static const NSUInteger TKDXTCompressionQualityDescriptionTableCount = sizeof(TKDXTCompressionQualityDescriptionTable)/sizeof(TKDXTCompressionQualityDescription);

NSString *NSStringFromDXTCompressionQuality(TKDXTCompressionQuality aQuality) {
	for (NSUInteger i = 0; i < TKDXTCompressionQualityDescriptionTableCount; i++) {
		if (TKDXTCompressionQualityDescriptionTable[i].compressionQuality == aQuality) {
			return TKDXTCompressionQualityDescriptionTable[i].description;
		}
	}
	return @"<Unknown>";
}

TKDXTCompressionQuality TKDXTCompressionQualityFromString(NSString *aQuality) {
	for (NSUInteger i = 0; i < TKDXTCompressionQualityDescriptionTableCount; i++) {
		if ([TKDXTCompressionQualityDescriptionTable[i].description isEqualToString:aQuality]) {
			return TKDXTCompressionQualityDescriptionTable[i].compressionQuality;
		}
	}
	return TKDXTCompressionDefaultQuality;
}


@interface TKImageRep ()

@property (nonatomic, assign) NSUInteger sliceIndex;
@property (nonatomic, assign) TKFace face;
@property (nonatomic, assign) NSUInteger frameIndex;
@property (nonatomic, assign) NSUInteger mipmapIndex;

@property (nonatomic, assign) TKPixelFormat pixelFormat;
@property (nonatomic, assign) CGBitmapInfo bitmapInfo;
@property (nonatomic, assign) CGImageAlphaInfo alphaInfo;


@end


@interface TKImageRep (TKPrivate)

+ (NSArray *)imageRepsWithData:(NSData *)aData firstRepresentationOnly:(BOOL)firstRepOnly;
- (void)getBitmapInfoAndPixelFormatIfNecessary;

@end


static NSArray *imageUnfilteredTypes = nil;
static NSArray *imageUnfilteredFileTypes = nil;


static TKDXTCompressionQuality defaultDXTCompressionQuality = TKDXTCompressionDefaultQuality;


@implementation TKImageRep

@synthesize sliceIndex;
@synthesize face;
@synthesize frameIndex;
@synthesize mipmapIndex;

@dynamic pixelFormat;
@dynamic bitmapInfo;
@dynamic alphaInfo;

@synthesize imageProperties;


/* Implemented by subclassers to indicate what UTI-identified data types they can deal with. */
+ (NSArray *)imageUnfilteredTypes {
	@synchronized(self) {
		if (imageUnfilteredTypes == nil) {
			imageUnfilteredTypes = (NSArray *)CGImageSourceCopyTypeIdentifiers();
#if TK_DEBUG
			NSArray *superTypes = [super imageUnfilteredTypes];
			NSLog(@"[%@ %@] super's %@ == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromSelector(_cmd), superTypes);
			NSLog(@"[%@ %@] *** FINAL *** imageUnfilteredTypes (CGImageSourceCopyTypeIdentifiers()) == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), imageUnfilteredTypes);
#endif
		}
	}
	return imageUnfilteredTypes;
}



+ (NSArray *)imageUnfilteredFileTypes {
	@synchronized(self) {
		if (imageUnfilteredFileTypes == nil) {
			NSMutableArray *mFileTypes = [NSMutableArray array];
			
			NSArray *utiTypes = [(NSArray *)CGImageSourceCopyTypeIdentifiers() autorelease];
			if (utiTypes && [utiTypes count]) {
				for (NSString *utiType in utiTypes) {
					NSDictionary *utiDeclarations = [(NSDictionary *)UTTypeCopyDeclaration((CFStringRef)utiType) autorelease];
					NSDictionary *utiSpec = [utiDeclarations objectForKey:(NSString *)kUTTypeTagSpecificationKey];
					if (utiSpec) {
						id extensions = [utiSpec objectForKey:(NSString *)kUTTagClassFilenameExtension];
						if ([extensions isKindOfClass:[NSString class]]) {
							[mFileTypes addObject:extensions];
						} else {
							[mFileTypes addObjectsFromArray:extensions];
						}
					}
				}
			}
			imageUnfilteredFileTypes = [mFileTypes copy];
#if TK_DEBUG
			NSArray *superTypes = [super imageUnfilteredFileTypes];
			NSLog(@"[%@ %@] super's %@ == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromSelector(_cmd), superTypes);
			NSLog(@"[%@ %@] CGImageSourceCopyTypeIdentifiers() == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), utiTypes);
			NSLog(@"[%@ %@] *** FINAL *** imageUnfilteredFileTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), imageUnfilteredFileTypes);
#endif
		}
	}
	return imageUnfilteredFileTypes;
}


+ (NSArray *)imageUnfilteredPasteboardTypes {
	static NSArray *imageUnfilteredPasteboardTypes = nil;
	
	@synchronized(self) {
		if (imageUnfilteredPasteboardTypes == nil) {
			imageUnfilteredPasteboardTypes = [[super imageUnfilteredPasteboardTypes] retain];
#if TK_DEBUG
			NSLog(@"[%@ %@] super's %@ == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromSelector(_cmd), imageUnfilteredPasteboardTypes);
#endif
		}
	}
	return imageUnfilteredPasteboardTypes;
}

//+ (BOOL)canInitWithPasteboard:(NSPasteboard *)pasteboard {
//	
//}


+ (BOOL)canInitWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([TKVTFImageRep canInitWithData:aData] ||
		[TKDDSImageRep canInitWithData:aData]) {
		return NO;
	}
	return YES;
}
	

+ (Class)imageRepClassForType:(NSString *)aType {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([imageUnfilteredTypes containsObject:aType]) {
		return [self class];
	}
	return [super imageRepClassForType:aType];
}

+ (Class)imageRepClassForFileType:(NSString *)fileType {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([imageUnfilteredFileTypes containsObject:fileType]) {
		return [self class];
	}
	return [super imageRepClassForFileType:fileType];
}


+ (TKDXTCompressionQuality)defaultDXTCompressionQuality {
	TKDXTCompressionQuality rDefaultDXTCompressionQuality = 0;
	@synchronized(self) {
		rDefaultDXTCompressionQuality = defaultDXTCompressionQuality;
	}
	return rDefaultDXTCompressionQuality;
}


+ (void)setDefaultDXTCompressionQuality:(TKDXTCompressionQuality)aQuality {
	@synchronized(self) {
		defaultDXTCompressionQuality = aQuality;
	}
}


+ (NSArray *)imageRepsWithData:(NSData *)aData firstRepresentationOnly:(BOOL)firstRepOnly {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)aData, NULL);
	if (source == NULL) {
		NSLog(@"[%@ %@] CGImageSourceCreateWithData() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return nil;
	}
	
	NSUInteger imageCount = (NSUInteger)CGImageSourceGetCount(source);
#if TK_DEBUG
	NSLog(@"[%@ %@] imageCount == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)imageCount);
#endif
	
	
	// build options dictionary for image creation that specifies: 
	//
	// kCGImageSourceShouldCache = kCFBooleanTrue
	//      Specifies that image should be cached in a decoded form.
	//
	// kCGImageSourceShouldAllowFloat = kCFBooleanTrue
	//      Specifies that image should be returned as a floating
	//      point CGImageRef if supported by the file format.
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:(id)kCFBooleanTrue,(id)kCGImageSourceShouldCache,
																	   (id)kCFBooleanTrue,(id)kCGImageSourceShouldAllowFloat, nil];
	
	NSMutableArray *imageReps = [NSMutableArray array];
	
	for (NSUInteger i = 0; i < imageCount; i++) {
		CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, i, (CFDictionaryRef)options);
		
		if (imageRef) {
			
			NSDictionary *properties = [(NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, i, (CFDictionaryRef)options) autorelease];
			
			TKImageRep *imageRep = [[TKImageRep alloc] initWithCGImage:imageRef
															sliceIndex:TKSliceIndexNone
																  face:TKFaceNone
															frameIndex:TKFrameIndexNone
														   mipmapIndex:i];
			
			if (imageRep) {
				[imageRep setImageProperties:properties];
				
				[imageReps addObject:imageRep];
				[imageRep release];
			}
			CGImageRelease(imageRef);
		}
		
		if (firstRepOnly && i == 0) {
			CFRelease(source);
			return [[imageReps copy] autorelease];
		}
	}
	CFRelease(source);
	return [[imageReps copy] autorelease];
}



+ (NSArray *)imageRepsWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] imageRepsWithData:aData firstRepresentationOnly:NO];
}

+ (id)imageRepWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *imageReps = [[self class] imageRepsWithData:aData firstRepresentationOnly:YES];
	if ([imageReps count]) return [imageReps objectAtIndex:0];
	return nil;
}


- (id)initWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *imageReps = [[self class] imageRepsWithData:aData firstRepresentationOnly:YES];
	if ((imageReps == nil) || !([imageReps count] > 0)) {
		[self release];
		return nil;
	}
	self = [[imageReps objectAtIndex:0] retain];
	return self;
}


- (id)init {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		sliceIndex = TKSliceIndexNone;
		face = TKFaceNone;
		frameIndex = TKFrameIndexNone;
		mipmapIndex = 0;
		bitmapInfo = UINT_MAX;
		alphaInfo = UINT_MAX;
		pixelFormat = TKPixelFormatUnknown;
	}
	return self;
}


/* create TKImageRep(s) from NSBitmapImageRep(s) */
+ (id)imageRepWithImageRep:(NSBitmapImageRep *)aBitmapImageRep {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([aBitmapImageRep isKindOfClass:[TKImageRep class]]) {
		return [[[[self class] alloc] initWithCGImage:[aBitmapImageRep CGImage]
										   sliceIndex:[(TKImageRep *)aBitmapImageRep sliceIndex]
												 face:[(TKImageRep *)aBitmapImageRep face]
										   frameIndex:[(TKImageRep *)aBitmapImageRep frameIndex]
										  mipmapIndex:[(TKImageRep *)aBitmapImageRep mipmapIndex]] autorelease];
	}
	return [[[[self class] alloc] initWithCGImage:[aBitmapImageRep CGImage]] autorelease];
}


+ (NSArray *)imageRepsWithImageReps:(NSArray *)bitmapImageReps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSMutableArray *imageReps = [NSMutableArray array];
	for (NSBitmapImageRep *imageRep in bitmapImageReps) {
		TKImageRep *tkImageRep = [[self class] imageRepWithImageRep:imageRep];
		if (tkImageRep) [imageReps addObject:tkImageRep];
	}
	return imageReps;
}


- (id)initWithCGImage:(CGImageRef)cgImage {
	return [self initWithCGImage:cgImage
					  sliceIndex:TKSliceIndexNone
							face:TKFaceNone
					  frameIndex:TKFrameIndexNone
					 mipmapIndex:0];
}



- (id)initWithCGImage:(CGImageRef)cgImage sliceIndex:(NSUInteger)aSlice face:(TKFace)aFace frameIndex:(NSUInteger)aFrame mipmapIndex:(NSUInteger)aMipmap {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithCGImage:cgImage])) {
		[self setFrameIndex:aFrame];
		[self setMipmapIndex:aMipmap];
		[self setFace:aFace];
		[self setSliceIndex:aSlice];
		[self setBitmapInfo:CGImageGetBitmapInfo(cgImage)];
		[self setAlphaInfo:CGImageGetAlphaInfo(cgImage)];
		[self setPixelFormat:TKPixelFormatFromCGImage(cgImage)];
	}
	return self;
}



- (id)initWithCoder:(NSCoder *)coder {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithCoder:coder])) {
		[self setSliceIndex:[[coder decodeObjectForKey:TKImageRepSliceIndexKey] unsignedIntegerValue]];
		[self setFace:[[coder decodeObjectForKey:TKImageRepFaceKey] unsignedIntegerValue]];
		[self setFrameIndex:[[coder decodeObjectForKey:TKImageRepFrameIndexKey] unsignedIntegerValue]];
		[self setMipmapIndex:[[coder decodeObjectForKey:TKImageRepMipmapIndexKey] unsignedIntegerValue]];
		
		[self setBitmapInfo:[[coder decodeObjectForKey:TKImageRepBitmapInfoKey] unsignedIntValue]];
		[self setPixelFormat:[[coder decodeObjectForKey:TKImageRepPixelFormatKey] unsignedIntegerValue]];
		
		[self setImageProperties:[coder decodeObjectForKey:TKImageRepImagePropertiesKey]];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super encodeWithCoder:coder];
	
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:sliceIndex] forKey:TKImageRepSliceIndexKey];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:face] forKey:TKImageRepFaceKey];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:frameIndex] forKey:TKImageRepFrameIndexKey];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:mipmapIndex] forKey:TKImageRepMipmapIndexKey];
	
	[coder encodeObject:[NSNumber numberWithUnsignedInt:bitmapInfo] forKey:TKImageRepBitmapInfoKey];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:pixelFormat] forKey:TKImageRepPixelFormatKey];
	
	[coder encodeObject:imageProperties forKey:TKImageRepImagePropertiesKey];

}


- (id)copyWithZone:(NSZone *)zone {
	TKImageRep *copy = (TKImageRep *)[super copyWithZone:zone];
#if TK_DEBUG
	NSLog(@"[%@ %@] copy == %@, class == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), copy, NSStringFromClass([copy class]));
#endif
	copy->imageProperties = nil;
	[copy setImageProperties:imageProperties];
	return copy;
}


- (void)dealloc {
	[imageProperties release];
	[super dealloc];
}


- (NSData *)data {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self getBitmapInfoAndPixelFormatIfNecessary];
	CGImageRef imageRef = [self CGImage];
	NSData *imageData = (NSData *)CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
	return [imageData autorelease];
}


- (void)getBitmapInfoAndPixelFormatIfNecessary {
	if (bitmapInfo == (CGBitmapInfo)UINT_MAX) {
		CGImageRef imageRef = [self CGImage];
		[self setBitmapInfo:CGImageGetBitmapInfo(imageRef)];
	}
	if (alphaInfo == (CGImageAlphaInfo)UINT_MAX) {
		CGImageRef imageRef = [self CGImage];
		[self setAlphaInfo:CGImageGetAlphaInfo(imageRef)];
	}
	if (pixelFormat == TKPixelFormatUnknown) {
		CGImageRef imageRef = [self CGImage];
		[self setPixelFormat:TKPixelFormatFromCGImage(imageRef)];
	}
}



- (CGBitmapInfo)bitmapInfo {
	[self getBitmapInfoAndPixelFormatIfNecessary];
	return bitmapInfo;
}

- (void)setBitmapInfo:(CGBitmapInfo)aBitmapInfo {
	bitmapInfo = aBitmapInfo;
}


- (CGImageAlphaInfo)alphaInfo {
	[self getBitmapInfoAndPixelFormatIfNecessary];
	return alphaInfo;
}

- (void)setAlphaInfo:(CGImageAlphaInfo)info {
	alphaInfo = info;
}


- (TKPixelFormat)pixelFormat {
	[self getBitmapInfoAndPixelFormatIfNecessary];
	return pixelFormat;
}

- (void)setPixelFormat:(TKPixelFormat)aFormat {
	pixelFormat = aFormat;
}


- (NSData *)RGBAData {
	return [self representationUsingPixelFormat:TKPixelFormatRGBA];
}


- (NSData *)representationUsingPixelFormat:(TKPixelFormat)aPixelFormat {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self getBitmapInfoAndPixelFormatIfNecessary];
	
	if (aPixelFormat == pixelFormat) return [self data];
	
	CGImageRef imageRef = [self CGImage];
	TKPixelFormatInfo pixelFormatInfo = TKPixelFormatInfoFromPixelFormat(aPixelFormat);
//	if (pixelFormatInfo == NULL) return nil;
	
	size_t newLength = CGImageGetWidth(imageRef) * (pixelFormatInfo.bitsPerPixel / 8) * CGImageGetHeight(imageRef);
	
	if (newLength == 0) return nil;
	
	void *bitmapData = malloc(newLength);
	if (bitmapData == NULL) {
		NSLog(@"[%@ %@] malloc(%llu) failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long long)newLength);
		return nil;
	}
	
	size_t imageWidth = CGImageGetWidth(imageRef);
	size_t imageHeight = CGImageGetHeight(imageRef);
	
	size_t bitsPerComponent = pixelFormatInfo.bitsPerPixel/4;
	size_t bytesPerRow = CGImageGetWidth(imageRef) * (pixelFormatInfo.bitsPerPixel / 8);
	
	CGColorSpaceRef colorspace = CGImageGetColorSpace(imageRef);
	if (colorspace == NULL) {
		NSLog(@"[%@ %@] CGImageGetColorSpace(imageRef) returned NULL", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//		colorspace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
		colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	} else {
		CGColorSpaceRetain(colorspace);
	}
	
	CGContextRef bitmapContext = CGBitmapContextCreate(bitmapData,
													   imageWidth,
													   imageHeight,
													   bitsPerComponent,
													   bytesPerRow,
													   colorspace,
													   pixelFormatInfo.bitmapInfo);
	if (bitmapContext == NULL) {
		NSLog(@"[%@ %@] CGBitmapContextCreate() returned NULL!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		CGColorSpaceRelease(colorspace);
		free(bitmapData);
		return nil;
	}
	
	CGContextDrawImage(bitmapContext, CGRectMake(0.0, 0.0, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef)), imageRef);
	NSData *repData = [NSData dataWithBytes:bitmapData length:newLength];
	CGContextRelease(bitmapContext);
	CGColorSpaceRelease(colorspace);
	free(bitmapData);
	return repData;
}


- (void)setSliceIndex:(NSUInteger)aSliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)aFrameIndex mipmapIndex:(NSUInteger)aMipmapIndex {
	[self setSliceIndex:aSliceIndex];
	[self setFace:aFace];
	[self setFrameIndex:aFrameIndex];
	[self setMipmapIndex:aMipmapIndex];
}


- (void)setProperty:(NSString *)property withValue:(id)value {
#if TK_DEBUG
//	NSLog(@"[%@ %@] property == %@, value == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), property, value);
#endif
	[super setProperty:property withValue:value];
}


- (NSComparisonResult)compare:(TKImageRep *)anImageRep {
	NSSize ourSize = [self size];
	NSSize theirSize = [anImageRep size];
	
	if (NSEqualSizes(ourSize, theirSize)) {
		NSUInteger theirSliceIndex = [anImageRep sliceIndex];
		TKFace theirFace = [anImageRep face];
		NSUInteger theirFrameIndex = [anImageRep frameIndex];
		NSUInteger theirMipmapIndex = [anImageRep mipmapIndex];
		
		NSUInteger ourIndexes[] = {sliceIndex, face, frameIndex, mipmapIndex};
		NSUInteger theirIndexes[] = {theirSliceIndex, theirFace, theirFrameIndex, theirMipmapIndex};
		
		NSIndexPath *ourIndexPath = [[NSIndexPath alloc] initWithIndexes:ourIndexes length:4];
		NSIndexPath *theirIndexPath = [[NSIndexPath alloc] initWithIndexes:theirIndexes length:4];
		
		NSComparisonResult comparisonResult = [ourIndexPath compare:theirIndexPath];
		
		[ourIndexPath release];
		[theirIndexPath release];
		
		return comparisonResult;
	}
	
	if ( (ourSize.width == theirSize.width && ourSize.height > theirSize.height) ||
		 (ourSize.width > theirSize.width && ourSize.height == theirSize.height) ||
		 (ourSize.width > theirSize.width && ourSize.height > theirSize.height) ||
		 (ourSize.width < theirSize.width && ourSize.height > theirSize.height && (ourSize.width * ourSize.height > theirSize.width * theirSize.height)) ||
		 (ourSize.width > theirSize.width && ourSize.height < theirSize.height && (ourSize.width * ourSize.height > theirSize.width * theirSize.height))) {
		
		return NSOrderedAscending;
	}
	return NSOrderedDescending;
}



+ (TKImageRep *)imageRepForFace:(TKFace)aFace ofImageRepsInArray:(NSArray *)imageReps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	for (TKImageRep *imageRep in imageReps) {
		if ([imageRep face] == aFace) return imageRep;
	}
	return nil;
}


- (BOOL)isEqual:(id)object {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
//	if ([object isKindOfClass:[self class]]) {
	if ([object isKindOfClass:[TKImageRep class]]) {
		if (TKGetSystemVersion() <= TKLeopard) {
#if TK_DEBUG
			NSLog(@"[%@ %@] (TKImageRepLeopardIsEqualCompatability)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
			return [super isEqual:object];
		}
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		BOOL isEqual = NO;
		
		NSData *otherImageRepData = [(TKImageRep *)object data];
		NSData *ourData = [self data];
		
		if ([ourData isEqualToData:otherImageRepData] &&
			sliceIndex == [(TKImageRep *)object sliceIndex] && 
			face == [(TKImageRep *)object face] &&
			frameIndex == [(TKImageRep *)object frameIndex] &&
			mipmapIndex == [(TKImageRep *)object mipmapIndex]) {
			isEqual = YES;
		}
		[pool release];
		return isEqual;
	}
	return NO;
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString string];
	[description appendFormat:@"%@ sliceIndex == %lu, ", [super description], (unsigned long)sliceIndex];
	[description appendFormat:@"face == %lu, ", (unsigned long)face];
	[description appendFormat:@"frameIndex == %lu, ", (unsigned long)frameIndex];
	[description appendFormat:@"mipmapIndex == %lu, ", (unsigned long)mipmapIndex];
	[description appendFormat:@"bitmapInfo == %lu, ", (unsigned long)[self bitmapInfo]];
	[description appendFormat:@"alphaInfo == %lu, ", (unsigned long)[self alphaInfo]];
	[description appendFormat:@"bitmapFormat == %lu, ", (unsigned long)[self bitmapFormat]];
	[description appendFormat:@"imageProperties == %@", [self imageProperties]];
	return description;
}


@end


@implementation TKImageRep (TKLargestRepresentationAdditions)

+ (TKImageRep *)largestRepresentationInArray:(NSArray *)imageReps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (imageReps == nil) return nil;
	
	NSUInteger repCount = [imageReps count];
	if (repCount == 1) return [imageReps objectAtIndex:0];
	
#if TK_DEBUG
	NSDate *theStartDate = [NSDate date];
#endif
	
	NSArray *sortedImageReps = [imageReps sortedArrayUsingSelector:@selector(compare:)];
	
#if TK_DEBUG
	NSTimeInterval elapsedTime = fabs([theStartDate timeIntervalSinceNow]);
	NSLog(@"[%@ %@] elapsed time to sort %lu TKImageReps == %.7f sec / %.4f ms", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)repCount, elapsedTime, elapsedTime * 1000.0);
#endif
	return [sortedImageReps objectAtIndex:0];
}


@end




