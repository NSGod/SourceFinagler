//
//  TKImageRep.m
//  Texture Kit
//
//  Created by Mark Douma on 11/5/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKImageRep.h>
#import <CoreServices/CoreServices.h>
#import <Quartz/Quartz.h>

#import <TextureKit/TKDDSImageRep.h>
#import <TextureKit/TKVTFImageRep.h>


#define TK_DEBUG 0


NSString * const TKImageRepSliceIndexKey		= @"TKImageRepSliceIndex";
NSString * const TKImageRepFaceKey				= @"TKImageRepFace";
NSString * const TKImageRepFrameIndexKey		= @"TKImageRepFrameIndex";
NSString * const TKImageRepMipmapIndexKey		= @"TKImageRepMipmapIndex";

NSString * const TKImageRepBitmapInfoKey		= @"TKImageRepBitmapInfo";
NSString * const TKImageRepPixelFormatKey		= @"TKImageRepPixelFormat";



typedef struct TKPixelFormatInfo {
	TKPixelFormat		pixelFormat;
	NSUInteger			bitsPerPixel;
	CGBitmapInfo		bitmapInfo;
} TKPixelFormatInfo;

static TKPixelFormatInfo TKPixelFormatInfoTable[] = {
	{TKPixelFormatRGB, 24, kCGImageAlphaNone},
	{TKPixelFormatXRGB, 32, kCGImageAlphaNoneSkipFirst},
	{TKPixelFormatRGBX, 32, kCGImageAlphaNoneSkipLast},
	{TKPixelFormatARGB, 32, kCGImageAlphaPremultipliedFirst},
	{TKPixelFormatRGBA, 32, kCGImageAlphaPremultipliedLast},
	{TKPixelFormatRGBA16161616, 64, kCGImageAlphaPremultipliedLast},
	{TKPixelFormatRGBX16161616, 64, kCGImageAlphaNoneSkipLast},
	{TKPixelFormatRGBA32323232F, 128, kCGImageAlphaPremultipliedLast | kCGBitmapFloatComponents},
	{TKPixelFormatRGBX32323232F, 128, kCGImageAlphaNoneSkipLast | kCGBitmapFloatComponents}
};
static const NSUInteger TKPixelFormatInfoTableCount = sizeof(TKPixelFormatInfoTable)/sizeof(TKPixelFormatInfo);

static inline TKPixelFormat TKGetPixelFormatForCGImage(CGImageRef imageRef) {
	if (imageRef == NULL) return TKPixelFormatUnknown;
	size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
	CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
	for (NSUInteger i = 0; i < TKPixelFormatInfoTableCount; i++) {
		if (TKPixelFormatInfoTable[i].bitsPerPixel == bitsPerPixel && TKPixelFormatInfoTable[i].bitmapInfo == bitmapInfo) {
			return TKPixelFormatInfoTable[i].pixelFormat;
		}
	}
	return TKPixelFormatUnknown;
}

static inline TKPixelFormatInfo *TKPixelFormatInfoForPixelFormat(TKPixelFormat aPixelFormat) {
	if (aPixelFormat > TKPixelFormatInfoTableCount) {
		NSLog(@"TKPixelFormatInfoForPixelFormat() invalid value passed for pixelFormat");
		return NULL;
	}
	for (NSUInteger i = 0; i < TKPixelFormatInfoTableCount; i++) {
		if (TKPixelFormatInfoTable[i].pixelFormat == aPixelFormat) {
			TKPixelFormatInfo *formatInfo = &TKPixelFormatInfoTable[i];
			return formatInfo;
		}
	}
	return NULL;
}

typedef struct TKDXTCompressionQualityDescription {
	TKDXTCompressionQuality		compressionQuality;
	NSString					*description;
} TKDXTCompressionQualityDescription;

//static const TKDXTCompressionQualityDescription TKDXTCompressionQualityDescriptionTable[] = {
//	{ TKDXTCompressionLowQuality, @"TKDXTCompressionLowQuality" },
//	{ TKDXTCompressionMediumQuality, @"TKDXTCompressionMediumQuality" },
//	{ TKDXTCompressionHighQuality, @"TKDXTCompressionHighQuality" },
//	{ TKDXTCompressionHighestQuality, @"TKDXTCompressionHighestQuality" },
//	{ TKDXTCompressionDefaultQuality, @"TKDXTCompressionDefaultQuality" },
//	{ TKDXTCompressionNotApplicable, @"TKDXTCompressionNotApplicable" }
//};

static const TKDXTCompressionQualityDescription TKDXTCompressionQualityDescriptionTable[] = {
	{ TKDXTCompressionLowQuality, @"Low" },
	{ TKDXTCompressionMediumQuality, @"Medium" },
	{ TKDXTCompressionHighQuality, @"High" },
	{ TKDXTCompressionHighestQuality, @"Highest" },
	{ TKDXTCompressionDefaultQuality, @"Default" },
	{ TKDXTCompressionNotApplicable, @"N/A" }
};

static NSUInteger TKDXTCompressionQualityDescriptionTableCount = sizeof(TKDXTCompressionQualityDescriptionTable)/sizeof(TKDXTCompressionQualityDescription);

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


@interface TKImageRep (TKPrivate)
+ (NSArray *)imageRepsWithData:(NSData *)aData firstRepresentationOnly:(BOOL)firstRepOnly;
- (void)getBitmapInfoAndPixelFormatIfNecessary;
@end

static NSArray *handledUTITypes = nil;
static NSArray *handledFileTypes = nil;

static TKDXTCompressionQuality defaultDXTCompressionQuality = TKDXTCompressionDefaultQuality;


@implementation TKImageRep

//@synthesize frameIndex, mipmapIndex, face, sliceIndex, isObserved, bitmapInfo, alphaInfo, pixelFormat;

@synthesize frameIndex, mipmapIndex, face, sliceIndex, isObserved;
@dynamic bitmapInfo, alphaInfo, pixelFormat;


/* Implemented by subclassers to indicate what UTI-identified data types they can deal with. */
+ (NSArray *)imageUnfilteredTypes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *superTypes = [super imageUnfilteredTypes];
	NSLog(@"[%@ %@] super's imageUnfilteredTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), superTypes);
	
	if (handledUTITypes == nil) {
		handledUTITypes = (NSArray *)CGImageSourceCopyTypeIdentifiers();
		NSLog(@"[%@ %@] CGImageSourceCopyTypeIdentifiers() == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), handledUTITypes);
	}
	return handledUTITypes;
}



+ (NSArray *)imageUnfilteredFileTypes {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
//	NSArray *superTypes = [super imageUnfilteredFileTypes];
//	NSLog(@"[%@ %@] super's imageUnfilteredFileTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), superTypes);
	
	if (handledFileTypes == nil) {
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
		
//		NSLog(@"[%@ %@] utiTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), utiTypes);
//		NSLog(@"[%@ %@] fileTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), fileTypes);
		
		handledFileTypes = [mFileTypes copy];
		
	}
//	NSLog(@"[%@ %@] handledFileTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), handledFileTypes);
	
	return handledFileTypes;
}


+ (NSArray *)imageUnfilteredPasteboardTypes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	static NSArray *imageUnfilteredPasteboardTypes = nil;
	
	if (imageUnfilteredPasteboardTypes == nil) {
		NSArray *types = [super imageUnfilteredPasteboardTypes];
		NSLog(@"[%@ %@] super's imageUnfilteredPasteboardTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), types);
		imageUnfilteredPasteboardTypes = [types retain];
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
	if ([handledUTITypes containsObject:aType]) {
		return [self class];
	}
	return [super imageRepClassForType:aType];
}

+ (Class)imageRepClassForFileType:(NSString *)fileType {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([handledFileTypes containsObject:fileType]) {
		return [self class];
	}
	return [super imageRepClassForFileType:fileType];
}


+ (TKDXTCompressionQuality)defaultDXTCompressionQuality {
	return defaultDXTCompressionQuality;
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
	NSLog(@"[%@ %@] imageCount == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)imageCount);
	
	
	// build options dictionary for image creation that specifies: 
	//
	// kCGImageSourceShouldCache = kCFBooleanTrue
	//      Specifies that image should be cached in a decoded form.
	//
	// kCGImageSourceShouldAllowFloat = kCFBooleanTrue
	//      Specifies that image should be returned as a floating
	//      point CGImageRef if supported by the file format.
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:(id)kCFBooleanTrue,(id)kCGImageSourceShouldCache,
							 (id)kCFBooleanTrue, (id)kCGImageSourceShouldAllowFloat, nil];
	
	NSMutableArray *imageReps = [NSMutableArray array];
	
	for (NSUInteger i = 0; i < imageCount; i++) {
		CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, i, (CFDictionaryRef)options);
		
		if (imageRef) {
			// Assign user preferred default profiles if image is not tagged with a profile
			//		imageRef = CGImageCreateCopyWithDefaultSpace(image);
			
			NSDictionary *metadata = [(NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, i, (CFDictionaryRef)options) autorelease];
			
			NSLog(@"[%@ %@] metadata == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), metadata);
			
			TKImageRep *imageRep = [[TKImageRep alloc] initWithCGImage:imageRef
															sliceIndex:0
																  face:TKFaceNone
															frameIndex:0
														   mipmapIndex:i];
			
			if (imageRep) {
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
	if ((self = [super init])) {
		sliceIndex = 0;
		face = TKFaceNone;
		frameIndex = 0;
		mipmapIndex = 0;
		bitmapInfo = UINT_MAX;
		alphaInfo = UINT_MAX;
		pixelFormat = TKPixelFormatUnknown;
		isObserved = NO;
	}
	return self;
}



- (id)initWithCGImage:(CGImageRef)cgImage {
	return [self initWithCGImage:cgImage
					  sliceIndex:0
							face:TKFaceNone
					  frameIndex:0
					 mipmapIndex:0];
}



- (id)initWithCGImage:(CGImageRef)cgImage sliceIndex:(NSUInteger)aSlice face:(TKFace)aFace frameIndex:(NSUInteger)aFrame mipmapIndex:(NSUInteger)aMipmap {
	
	if ((self = [super initWithCGImage:cgImage])) {
		[self setFrameIndex:aFrame];
		[self setMipmapIndex:aMipmap];
		[self setFace:aFace];
		[self setSliceIndex:aSlice];
		[self setBitmapInfo:CGImageGetBitmapInfo(cgImage)];
		[self setAlphaInfo:CGImageGetAlphaInfo(cgImage)];
		[self setPixelFormat:TKGetPixelFormatForCGImage(cgImage)];
	}
	return self;
}



- (id)initWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithCoder:coder])) {
		[self setSliceIndex:[[coder decodeObjectForKey:TKImageRepSliceIndexKey] unsignedIntegerValue]];
		[self setFace:[[coder decodeObjectForKey:TKImageRepFaceKey] unsignedIntegerValue]];
		[self setFrameIndex:[[coder decodeObjectForKey:TKImageRepFrameIndexKey] unsignedIntegerValue]];
		[self setMipmapIndex:[[coder decodeObjectForKey:TKImageRepMipmapIndexKey] unsignedIntegerValue]];
		
		[self setBitmapInfo:[[coder decodeObjectForKey:TKImageRepBitmapInfoKey] unsignedIntValue]];
		[self setPixelFormat:[[coder decodeObjectForKey:TKImageRepPixelFormatKey] unsignedIntegerValue]];
		
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super encodeWithCoder:coder];
	
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:sliceIndex] forKey:TKImageRepSliceIndexKey];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:face] forKey:TKImageRepFaceKey];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:frameIndex] forKey:TKImageRepFrameIndexKey];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:mipmapIndex] forKey:TKImageRepMipmapIndexKey];
	
	[coder encodeObject:[NSNumber numberWithUnsignedInt:bitmapInfo] forKey:TKImageRepBitmapInfoKey];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:pixelFormat] forKey:TKImageRepPixelFormatKey];

}

- (id)copyWithZone:(NSZone *)zone {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	TKImageRep *copy = (TKImageRep *)[super copyWithZone:zone];
	NSLog(@"[%@ %@] copy == %@, class == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), copy, NSStringFromClass([copy class]));
	return copy;
}


- (NSData *)data {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self getBitmapInfoAndPixelFormatIfNecessary];
	CGImageRef imageRef = [self CGImage];
	NSData *imageData = (NSData *)CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
	return [imageData autorelease];
//	return [(NSData *)CGDataProviderCopyData(CGImageGetDataProvider(imageRef)) autorelease];
}


- (void)getBitmapInfoAndPixelFormatIfNecessary {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (bitmapInfo == UINT_MAX) {
		NSLog(@"[%@ %@] bitmapInfo == UINT_MAX", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		CGImageRef imageRef = [self CGImage];
//		bitmapInfo = CGImageGetBitmapInfo(imageRef);
		[self setBitmapInfo:CGImageGetBitmapInfo(imageRef)];
	}
	if (alphaInfo == UINT_MAX) {
		CGImageRef imageRef = [self CGImage];
		[self setAlphaInfo:CGImageGetAlphaInfo(imageRef)];
	}
	if (pixelFormat == TKPixelFormatUnknown) {
		NSLog(@"[%@ %@] pixelFormat == TKPixelFormatUnknown", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		CGImageRef imageRef = [self CGImage];
		[self setPixelFormat:TKGetPixelFormatForCGImage(imageRef)];
	}
}



- (CGBitmapInfo)bitmapInfo {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self getBitmapInfoAndPixelFormatIfNecessary];
	return bitmapInfo;
}

- (void)setBitmapInfo:(CGBitmapInfo)aBitmapInfo {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	bitmapInfo = aBitmapInfo;
}


- (CGImageAlphaInfo)alphaInfo {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self getBitmapInfoAndPixelFormatIfNecessary];
	return alphaInfo;
}

- (void)setAlphaInfo:(CGImageAlphaInfo)info {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	alphaInfo = info;
}


- (TKPixelFormat)pixelFormat {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self getBitmapInfoAndPixelFormatIfNecessary];
	return pixelFormat;
}

- (void)setPixelFormat:(TKPixelFormat)aFormat {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
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
	TKPixelFormatInfo *pixelFormatInfo = TKPixelFormatInfoForPixelFormat(aPixelFormat);
	if (pixelFormatInfo == NULL) return nil;
	
	size_t newLength = CGImageGetWidth(imageRef) * (pixelFormatInfo->bitsPerPixel / 8) * CGImageGetHeight(imageRef);
	
	
	void *bitmapData = malloc(newLength);
	if (bitmapData == NULL) {
		NSLog(@"[%@ %@] malloc(%llu) failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long long)newLength);
		return nil;
	}
	
	size_t imageWidth = CGImageGetWidth(imageRef);
	size_t imageHeight = CGImageGetHeight(imageRef);
	
	size_t bitsPerComponent = pixelFormatInfo->bitsPerPixel/4;
	size_t bytesPerRow = CGImageGetWidth(imageRef) * (pixelFormatInfo->bitsPerPixel / 8);
	
	CGColorSpaceRef colorspace = CGImageGetColorSpace(imageRef);
	if (colorspace == NULL) {
		NSLog(@"[%@ %@] CGImageGetColorSpace(imageRef) returned NULL", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		colorspace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
//		colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	} else {
		CGColorSpaceRetain(colorspace);
	}
	
	CGContextRef bitmapContext = CGBitmapContextCreate(bitmapData,
													   imageWidth,
													   imageHeight,
													   bitsPerComponent,
													   bytesPerRow,
													   colorspace,
													   pixelFormatInfo->bitmapInfo);
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


//- (NSData *)representationForType:(NSString *)utiType {
//#if TK_DEBUG
//	NSLog(@"[%@ %@] utiType == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), utiType);
//#endif
//	NSMutableData *imageData = [NSMutableData data];
//	
//	CGImageDestinationRef imageDest = CGImageDestinationCreateWithData((CFMutableDataRef)imageData , (CFStringRef)utiType, 1, NULL);
//	if (imageDest == NULL) {
//		return nil;
//	}
//	
//	CGImageRef imageRef = [self CGImage];
//	CGImageDestinationAddImage(imageDest, imageRef, NULL);
//	CGImageDestinationFinalize(imageDest);
//	CFRelease(imageDest);
//	
//	return [[imageData copy] autorelease];
//}



- (void)setSliceIndex:(NSUInteger)aSliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)aFrameIndex mipmapIndex:(NSUInteger)aMipmapIndex {
	[self setSliceIndex:aSliceIndex];
	[self setFace:aFace];
	[self setFrameIndex:aFrameIndex];
	[self setMipmapIndex:aMipmapIndex];
}


- (NSComparisonResult)compare:(TKImageRep *)imageRep {
	return [self compare:imageRep options:0];
}


- (NSComparisonResult)compare:(TKImageRep *)imageRep options:(TKImageRepCompareOptions)options {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSSize ourSize = [self size];
	NSSize theirSize = [imageRep size];
	
	if (NSEqualSizes(ourSize, theirSize)) {
		return NSOrderedSame;
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


- (BOOL)isEqual:(id)object {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([object isKindOfClass:[self class]]) {
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



- (NSString *)imageUID {
	return [NSString stringWithFormat:@"%lu", [self hash]];
}


- (NSString *)imageRepresentationType {
	return IKImageBrowserNSBitmapImageRepresentationType;
}

- (id)imageRepresentation {
	return self;
}

- (NSString *)imageTitle {
	return [NSString stringWithFormat:@"%lupx x %lupx", (NSUInteger)[self size].width, (NSUInteger)[self size].height];
}


- (NSDictionary *)imageProperties {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	CGImageRef imageRef = [self CGImage];
	CGDataProviderRef provider = CGImageGetDataProvider(imageRef);
	CGImageSourceRef imageSource = CGImageSourceCreateWithDataProvider(provider, NULL);
	
	NSDictionary *imageProperties = [(NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL) autorelease];
	NSLog(@"[%@ %@] imageProperties == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), imageProperties);
	CFRelease(imageSource);
	
//	NSMutableDictionary *imageProperties = [NSMutableDictionary dictionary];
//	[imageProperties setObject:[NSNumber numberWithInteger:(NSInteger)[self size].width] forKey:(NSString *)kCGImagePropertyPixelWidth];
//	[imageProperties setObject:[NSNumber numberWithInteger:(NSInteger)[self size].height] forKey:(NSString *)kCGImagePropertyPixelHeight];
//	[imageProperties setObject:[NSNumber numberWithBool:[self hasAlpha]] forKey:(NSString *)kCGImagePropertyHasAlpha];
//	[imageProperties setObject:(NSString *)kCGImagePropertyColorModelRGB forKey:(NSString *)kCGImagePropertyColorModel];
	
	return imageProperties;
}

- (NSString *)description {
//	NSMutableString *description = [NSMutableString stringWithString:[super description]];
//	[description appendFormat:@"\n"];
	NSMutableString *description = [NSMutableString string];
	[description appendFormat:@"%@ sliceIndex == %lu, ", [super description], sliceIndex];
	[description appendFormat:@"face == %lu, ", face];
	[description appendFormat:@"frameIndex == %lu, ", frameIndex];
	[description appendFormat:@"mipmapIndex == %lu", mipmapIndex];
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
	
	NSDate *theStartDate = [NSDate date];
	NSArray *sortedImageReps = [imageReps sortedArrayUsingSelector:@selector(compare:)];
	NSTimeInterval elapsedTime = fabs([theStartDate timeIntervalSinceNow]);
	NSLog(@"[%@ %@] elapsed time to sort %lu TKImageReps == %.7f sec / %.4f ms", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)repCount, elapsedTime, elapsedTime * 1000.0);
	
	return [sortedImageReps objectAtIndex:0];
}


@end




