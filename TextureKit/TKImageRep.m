//
//  TKImageRep.m
//  Texture Kit
//
//  Created by Mark Douma on 11/5/2010.
//  Copyright (c) 2010-2014 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKImageRep.h>
#import <CoreServices/CoreServices.h>
#import <Cocoa/Cocoa.h>
#import <TextureKit/TKDDSImageRep.h>
#import <TextureKit/TKVTFImageRep.h>
#import <TextureKit/TKError.h>

#import "TKFoundationAdditions.h"
#import "TKPrivateInterfaces.h"
#import "MDFoundationAdditions.h"



#define TK_DEBUG 0


static NSString * const TKImageRepSliceIndexKey			= @"TKImageRepSliceIndex";
static NSString * const TKImageRepFaceKey				= @"TKImageRepFace";
static NSString * const TKImageRepFrameIndexKey			= @"TKImageRepFrameIndex";
static NSString * const TKImageRepMipmapIndexKey		= @"TKImageRepMipmapIndex";

static NSString * const TKImageRepBitmapInfoKey			= @"TKImageRepBitmapInfo";
static NSString * const TKImageRepAlphaInfoKey			= @"TKImageRepAlphaInfo";
static NSString * const TKImageRepPixelFormatKey		= @"TKImageRepPixelFormat";

static NSString * const TKImageRepImagePropertiesKey	= @"TKImageRepImageProperties";


NSString * const TKImageMipmapGenerationKey				= @"TKImageMipmapGeneration";
NSString * const TKImageWrapModeKey						= @"TKImageWrapMode";
NSString * const TKImageResizeModeKey					= @"TKImageResizeMode";
NSString * const TKImageResizeFilterKey					= @"TKImageResizeFilter";

NSString * const TKImagePropertyVersion					= @"TKImagePropertyVersion";



@interface TKImageRep (TKPrivate)

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

@dynamic hasDimensionsThatArePowerOfTwo;


/* Implemented by subclassers to indicate what UTI-identified data types they can deal with. */
+ (NSArray *)imageUnfilteredTypes {
	@synchronized(self) {
		if (imageUnfilteredTypes == nil) {
			imageUnfilteredTypes = (NSArray *)CGImageSourceCopyTypeIdentifiers();
#if TK_DEBUG
//			NSArray *superTypes = [super imageUnfilteredTypes];
//			NSLog(@"[%@ %@] super's %@ == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromSelector(_cmd), superTypes);
//			NSLog(@"[%@ %@] *** FINAL *** imageUnfilteredTypes (CGImageSourceCopyTypeIdentifiers()) == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), imageUnfilteredTypes);
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
//			NSArray *superTypes = [super imageUnfilteredFileTypes];
//			NSLog(@"[%@ %@] super's %@ == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromSelector(_cmd), superTypes);
//			NSLog(@"[%@ %@] CGImageSourceCopyTypeIdentifiers() == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), utiTypes);
//			NSLog(@"[%@ %@] *** FINAL *** imageUnfilteredFileTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), imageUnfilteredFileTypes);
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
//			NSLog(@"[%@ %@] super's %@ == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromSelector(_cmd), imageUnfilteredPasteboardTypes);
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


+ (NSString *)localizedNameOfCompressionQuality:(TKDXTCompressionQuality)compressionQuality {
	NSParameterAssert(compressionQuality <= TKDXTCompressionNotApplicable);
	switch (compressionQuality) {
		case TKDXTCompressionLowQuality : return NSLocalizedString(@"Low", @"Low Compression Quality");
		case TKDXTCompressionMediumQuality: return NSLocalizedString(@"Medium", @"Medium Compression Quality");
		case TKDXTCompressionHighQuality: return NSLocalizedString(@"High", @"High Compression Quality");
		case TKDXTCompressionHighestQuality: return NSLocalizedString(@"Highest", @"Highest Compression Quality");
		case TKDXTCompressionNotApplicable:
		default:
			return NSLocalizedString(@"N/A", @"Compression quality doesn't apply");
	}
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



#pragma mark - reading

+ (NSArray *)imageRepsWithData:(NSData *)containerData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] imageRepsWithData:containerData error:NULL];
}


+ (NSArray *)imageRepsWithData:(NSData *)containerData error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] imageRepsWithData:containerData firstRepresentationOnly:NO error:outError];
}


+ (NSArray *)imageRepsWithData:(NSData *)containerData firstRepresentationOnly:(BOOL)firstRepOnly error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)containerData, NULL);
	if (source == NULL) {
		NSLog(@"[%@ %@] CGImageSourceCreateWithData() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return nil;
	}
	
	NSUInteger imageCount = (NSUInteger)CGImageSourceGetCount(source);
#if TK_DEBUG
	NSLog(@"[%@ %@] imageCount == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)imageCount);
#endif
	
	if (imageCount == 0) {
		CGImageSourceStatus status = CGImageSourceGetStatus(source);
		
		NSLog(@"[%@ %@] CGImageSourceGetCount() == 0; CGImageSourceGetStatus() == %ld", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (long)status);
		
		if (outError) {
			
			NSInteger code = 0;
			
			switch (status) {
				case kCGImageStatusUnexpectedEOF: code = TKErrorCGImageSourceUnexpectedEOF;
					break;
				case kCGImageStatusInvalidData: code = TKErrorCGImageSourceInvalidData;
					break;
				case kCGImageStatusUnknownType: code = TKErrorCGImageSourceUnknownType;
					break;
				default:
					code = TKErrorUnknown;
					break;
			}
			
			NSString *description = TKLocalizedStringFromImageSourceStatus(status);
			
			*outError = [NSError errorWithDomain:TKErrorDomain code:code userInfo:(description == nil ? nil : [NSDictionary dictionaryWithObjectsAndKeys:description,NSLocalizedDescriptionKey, nil])];
		}
		CFRelease(source);
		return nil;
	}
	
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
		
		if (imageRef == NULL) {
			CGImageSourceStatus status = CGImageSourceGetStatus(source);
			CGImageSourceStatus indexStatus = CGImageSourceGetStatusAtIndex(source, i);
			
			NSLog(@"[%@ %@] CGImageSourceCreateImageAtIndex() returned NULL; CGImageSourceGetStatus() == %ld, CGImageSourceGetStatusAtIndex() == %ld", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (long)status, (long)indexStatus);
			
			if (outError) {
				
				NSInteger code = 0;
				
				switch (indexStatus) {
					case kCGImageStatusUnexpectedEOF: code = TKErrorCGImageSourceUnexpectedEOF;
						break;
					case kCGImageStatusInvalidData: code = TKErrorCGImageSourceInvalidData;
						break;
					case kCGImageStatusUnknownType: code = TKErrorCGImageSourceUnknownType;
						break;
					default:
						code = TKErrorUnknown;
						break;
				}
				
				NSString *description = TKLocalizedStringFromImageSourceStatus(indexStatus);
				
				*outError = [NSError errorWithDomain:TKErrorDomain code:code userInfo:(description == nil ? nil : [NSDictionary dictionaryWithObjectsAndKeys:description,NSLocalizedDescriptionKey, nil])];
			}
			CFRelease(source);
			return nil;
		}
		
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
		
		if (firstRepOnly && i == 0) {
			CFRelease(source);
			return [[imageReps copy] autorelease];
		}
	}
	CFRelease(source);
	return [[imageReps copy] autorelease];
}


+ (id)imageRepWithData:(NSData *)containerData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] imageRepWithData:containerData error:NULL];
}


+ (id)imageRepWithData:(NSData *)containerData error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *imageReps = [[self class] imageRepsWithData:containerData firstRepresentationOnly:YES error:outError];
	if ([imageReps count]) return [imageReps objectAtIndex:0];
	return nil;
}


- (id)initWithData:(NSData *)containerData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self initWithData:containerData error:NULL];
}


- (id)initWithData:(NSData *)containerData error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *imageReps = [[self class] imageRepsWithData:containerData firstRepresentationOnly:YES error:outError];
	if ((imageReps == nil) || imageReps.count == 0) {
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
		frameIndex = aFrame;
		mipmapIndex = aMipmap;
		face = aFace;
		sliceIndex = aSlice;
		bitmapInfo = CGImageGetBitmapInfo(cgImage);
		alphaInfo = CGImageGetAlphaInfo(cgImage);
		pixelFormat = TKPixelFormatFromCGImage(cgImage);
	}
	return self;
}



- (id)initWithPixelData:(NSData *)pixelData pixelFormat:(TKPixelFormat)aPixelFormat pixelsWide:(NSInteger)width pixelsHigh:(NSInteger)height sliceIndex:(NSUInteger)aSliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)aFrameIndex mipmapIndex:(NSUInteger)aMipmapIndex {
#if TK_DEBUG
//    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	TKPixelFormatInfo formatInfo = TKPixelFormatInfoFromPixelFormat(aPixelFormat);
	
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)pixelData);
//	CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName((CFStringRef)formatInfo.colorSpaceName);
	CGColorSpaceRef colorSpace = TKCreateColorSpaceFromColorSpace(formatInfo.colorSpace);
	
	CGImageRef imageRef = CGImageCreate(width,
										height,
										formatInfo.bitsPerComponent,
										formatInfo.bitsPerPixel,
										((formatInfo.bitsPerPixel + 7) / 8) * width,
										colorSpace,
										formatInfo.bitmapInfo,
										provider,
										NULL,
										false,
										kCGRenderingIntentDefault);
	
	CGColorSpaceRelease(colorSpace);
	CGDataProviderRelease(provider);
	
	if (imageRef == NULL) {
		NSLog(@"[%@ %@] *** ERROR: CGImageCreate() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		[self release];
		return nil;
	}
	
	if ((self = [self initWithCGImage:imageRef sliceIndex:aSliceIndex face:aFace frameIndex:aFrameIndex mipmapIndex:aMipmapIndex])) {
		
	}
	CGImageRelease(imageRef);
	return self;
}



- (id)initWithCoder:(NSCoder *)coder {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithCoder:coder])) {
		
		sliceIndex = [[coder decodeObjectForKey:TKImageRepSliceIndexKey] unsignedIntegerValue];
		face = [[coder decodeObjectForKey:TKImageRepFaceKey] unsignedIntegerValue];
		frameIndex = [[coder decodeObjectForKey:TKImageRepFrameIndexKey] unsignedIntegerValue];
		mipmapIndex = [[coder decodeObjectForKey:TKImageRepMipmapIndexKey] unsignedIntegerValue];
		
		bitmapInfo = [[coder decodeObjectForKey:TKImageRepBitmapInfoKey] unsignedIntValue];
		alphaInfo = [[coder decodeObjectForKey:TKImageRepAlphaInfoKey] unsignedIntValue];
		pixelFormat = [[coder decodeObjectForKey:TKImageRepPixelFormatKey] unsignedIntegerValue];
		
		imageProperties = [[coder decodeObjectForKey:TKImageRepImagePropertiesKey] retain];
		
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
	[coder encodeObject:[NSNumber numberWithUnsignedInt:alphaInfo] forKey:TKImageRepAlphaInfoKey];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:pixelFormat] forKey:TKImageRepPixelFormatKey];
	
	[coder encodeObject:imageProperties forKey:TKImageRepImagePropertiesKey];

}


- (id)copyWithZone:(NSZone *)zone {
	TKImageRep *copy = (TKImageRep *)[super copyWithZone:zone];
	copy->imageProperties = nil;
	[copy setImageProperties:imageProperties];
#if TK_DEBUG
	NSLog(@"[%@ %@] copy == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), copy);
#endif
	return copy;
}

#pragma mark -


- (void)dealloc {
	[imageProperties release];
	[super dealloc];
}


- (NSData *)data {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
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


- (BOOL)hasDimensionsThatArePowerOfTwo {
	return TKIsPowerOfTwo(self.pixelsWide) && TKIsPowerOfTwo(self.pixelsHigh);
}


- (NSData *)dataByConvertingToPixelFormat:(TKPixelFormat)aPixelFormat options:(TKPixelFormatConversionOptions)options {
#if TK_DEBUG
//	NSLog(@"[%@ %@] aPixelFormat == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), TKStringFromPixelFormat(aPixelFormat));
#endif
	if (aPixelFormat == self.pixelFormat) return [self data];
	NSData *convertedData = [TKDDSImageRep dataByConvertingData:[self data] inFormat:self.pixelFormat toFormat:aPixelFormat pixelCount:self.pixelsWide * self.pixelsHigh options:options];
	return convertedData;
}


#pragma mark - writing

- (NSData *)representationUsingImageType:(NSString *)utiType properties:(NSDictionary *)properties {
#if TK_DEBUG
	NSLog(@"[%@ %@] utiType == %@, properties == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), utiType, properties);
#endif
	return [[self class] representationOfImageRepsInArray:[NSArray arrayWithObject:self] usingImageType:utiType properties:properties];
}


+ (NSData *)representationOfImageRepsInArray:(NSArray *)imageReps usingImageType:(NSString *)utiType properties:(NSDictionary *)properties {
#if TK_DEBUG
	NSLog(@"[%@ %@] utiType == %@, properties == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), utiType, properties);
#endif
	
	NSMutableDictionary *mProperties = (properties == nil ? [NSMutableDictionary dictionary] : [[properties deepMutableCopy] autorelease]);
	
//	[mProperties setObject:(id)kCGImagePropertyColorModelRGB forKey:(id)kCGImagePropertyColorModel];
	NSMutableDictionary *TIFFDictionary = [mProperties objectForKey:(id)kCGImagePropertyTIFFDictionary];
	if (TIFFDictionary == nil) {
		TIFFDictionary = [NSMutableDictionary dictionary];
		[mProperties setObject:TIFFDictionary forKey:(id)kCGImagePropertyTIFFDictionary];
	}
	
	[TIFFDictionary setObject:[NSString stringWithFormat:@"%@ %@ (%@)",
							   [[NSBundle mainBundle] objectForInfoDictionaryKey:(id)kCFBundleExecutableKey],
							   [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
							   [[NSBundle mainBundle] objectForInfoDictionaryKey:(id)kCFBundleVersionKey]]
	 
					   forKey:(id)kCGImagePropertyTIFFSoftware];
	
	
	NSMutableData *imageData = [NSMutableData data];
	
	CGImageDestinationRef imageDest = CGImageDestinationCreateWithData((CFMutableDataRef)imageData , (CFStringRef)utiType, imageReps.count, NULL);
	if (imageDest == NULL) {
		NSLog(@"[%@ %@] ERROR: CGImageDestinationCreateWithData() returned NULL", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return nil;
	}
	
	for (TKImageRep *imageRep in imageReps) {
		CGImageRef imageRef = [imageRep CGImage];
		CGImageDestinationAddImage(imageDest, imageRef, (CFDictionaryRef)mProperties);
	}
	
	if (!CGImageDestinationFinalize(imageDest)) {
		NSLog(@"[%@ %@] NOTICE: CGImageDestinationFinalize() returned false", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	}
	
	CFRelease(imageDest);
	return [[imageData copy] autorelease];
}


#pragma mark -



/* Creates an autoreleased copy of the receiver that has been resized using the specified resize mode and filter. */
- (TKImageRep *)imageRepByResizingUsingResizeMode:(TKResizeMode)resizeMode resizeFilter:(TKResizeFilter)resizeFilter {
#if TK_DEBUG
//    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	TKImageRep *resizedImageRep = [TKDDSImageRep imageRepByResizingImageRep:self usingResizeMode:resizeMode resizeFilter:resizeFilter];
	return resizedImageRep;
}


- (NSArray *)mipmapImageRepsUsingFilter:(TKMipmapGenerationType)filterType {
#if TK_DEBUG
//    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *mipmapImageReps = [TKDDSImageRep mipmapImageRepsOfImageRep:self usingFilter:filterType];
	return mipmapImageReps;
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
		if ([[NSProcessInfo processInfo] tk__operatingSystemVersion].minorVersion <= TKLeopard) {
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


+ (TKImageRep *)largestRepresentationInArray:(NSArray *)imageReps {
	NSParameterAssert(imageReps != nil);
	if (imageReps.count == 0) return nil;
	
	NSUInteger repCount = imageReps.count;
	if (repCount == 1) return [imageReps objectAtIndex:0];
	
	NSArray *sortedImageReps = [imageReps sortedArrayUsingSelector:@selector(compare:)];
	
	return [sortedImageReps objectAtIndex:0];
}


+ (BOOL)sizeIsPowerOfTwo:(NSSize)aSize {
	NSSize integralSize = NSIntegralRect(NSMakeRect(0, 0, aSize.width, aSize.height)).size;
	return (TKIsPowerOfTwo((NSUInteger)integralSize.width) && TKIsPowerOfTwo((NSUInteger)integralSize.height));
}


+ (NSSize)powerOfTwoSizeForSize:(NSSize)aSize usingResizeMode:(TKResizeMode)resizeMode {
	NSParameterAssert(resizeMode <= TKResizeModePreviousPowerOfTwo);
	NSSize integralSize = NSIntegralRect(NSMakeRect(0, 0, aSize.width, aSize.height)).size;
	
	if ([[self class] sizeIsPowerOfTwo:integralSize]) return integralSize;
	
	if (resizeMode == TKResizeModeNextPowerOfTwo) {
		return NSMakeSize((CGFloat)TKNextPowerOfTwo((NSUInteger)aSize.width), (CGFloat)TKNextPowerOfTwo((NSUInteger)aSize.height));
		
	} else if (resizeMode == TKResizeModeNearestPowerOfTwo) {
		return NSMakeSize((CGFloat)TKNearestPowerOfTwo((NSUInteger)aSize.width), (CGFloat)TKNearestPowerOfTwo((NSUInteger)aSize.height));
		
	} else if (resizeMode == TKResizeModePreviousPowerOfTwo) {
		return NSMakeSize((CGFloat)TKPreviousPowerOfTwo((NSUInteger)aSize.width), (CGFloat)TKPreviousPowerOfTwo((NSUInteger)aSize.height));
		
	}
	return integralSize;
}


typedef struct TKFaceInfo {
	TKFace				face;
	NSUInteger			xFactor;
	NSUInteger			yFactor;
	NSString	* const	description;
} TKFaceInfo;

static const TKFaceInfo TKFaceInfoTable[] = {
	{ TKFaceRight,		2, 1,	@"TKFaceRight" },
	{ TKFaceLeft,		0, 1,	@"TKFaceLeft" },
	{ TKFaceBack,		1, 2,	@"TKFaceBack" },
	{ TKFaceFront,		1, 0,	@"TKFaceFront" },
	{ TKFaceUp,			1, 1,	@"TKFaceUp" },
	{ TKFaceDown,		3, 1,	@"TKFaceDown" },
	{ TKFaceSphereMap,	0, 0,	@"TKFaceSphereMap" },
};

+ (NSRect)rectForFace:(TKFace)face inEnvironmentMapRect:(NSRect)environmentMapRect {
	NSParameterAssert(face < TKFaceSphereMap);
	CGFloat width = NSWidth(environmentMapRect) / 4.0;
	CGFloat height = NSHeight(environmentMapRect) / 3.0;
	
	TKFaceInfo faceInfo = TKFaceInfoTable[face];
	
	return NSMakeRect(0.0 + width * faceInfo.xFactor, 0.0 + height * faceInfo.yFactor, width, height);
}



#define TK_DEBUG_DATA 1
#define TK_DEBUG_DATA_NUM_PIXELS 8



- (NSString *)description {
	NSMutableString *description = [NSMutableString string];
	[description appendFormat:@"%@ sliceIndex == %@, ", [super description], (sliceIndex == TKSliceIndexNone ? @"TKSliceIndexNone" : [NSNumber numberWithUnsignedInteger:sliceIndex])];
	[description appendFormat:@"face == %@, ", (face == TKFaceNone ? @"TKFaceNone" : TKFaceInfoTable[face].description)];
	[description appendFormat:@"frameIndex == %@, ", (frameIndex == TKFrameIndexNone ? @"TKFrameIndexNone" : [NSNumber numberWithUnsignedInteger:frameIndex])];
	[description appendFormat:@"mipmapIndex == %@, ", (mipmapIndex == TKMipmapIndexNone ? @"TKMipmapIndexNone" : [NSNumber numberWithUnsignedInteger:mipmapIndex])];
	
	[description appendFormat:@"pixelFormat == %@, ", TKStringFromPixelFormat([self pixelFormat])];
	[description appendFormat:@"bitmapInfo == %@, ", TKStringFromCGBitmapInfo([self bitmapInfo])];
	[description appendFormat:@"alphaInfo == %@, ", TKStringFromCGBitmapInfo([self alphaInfo])];
	
	[description appendFormat:@"bitmapFormat == %lu, ", (unsigned long)[self bitmapFormat]];
	[description appendFormat:@"imageProperties == %@, \n", imageProperties];
	
	
#if TK_DEBUG_DATA
	
	if (mipmapIndex == 0 && self.pixelsWide >= TK_DEBUG_DATA_NUM_PIXELS) {
		NSData *imageRepData = self.data;
		
		if (imageRepData.length >= TK_DEBUG_DATA_NUM_PIXELS * ((self.bitsPerPixel + 7) / 8)) {
			NSData *sampleData = [imageRepData subdataWithRange:NSMakeRange(0, TK_DEBUG_DATA_NUM_PIXELS * ((self.bitsPerPixel + 7) / 8) )];
			
			if (self.pixelFormat == TKPixelFormatR32F) {
				[description appendFormat:@"\n sampleData == %@", [sampleData enhancedFloatDescriptionForComponentCount:1]];
				[description appendFormat:@"\n sampleData == %@", [sampleData enhancedDescription]];
				
			} else if (self.pixelFormat == TKPixelFormatRGB323232F) {
				[description appendFormat:@"\n sampleData == %@", [sampleData enhancedFloatDescriptionForComponentCount:3]];
				[description appendFormat:@"\n sampleData == %@", [sampleData enhancedDescription]];
				
			} else if (self.pixelFormat == TKPixelFormatRGBA32323232F) {
				[description appendFormat:@"\n sampleData == %@", [sampleData enhancedFloatDescriptionForComponentCount:4]];
				[description appendFormat:@"\n sampleData == %@", [sampleData enhancedDescription]];
				
			} else {
				[description appendFormat:@"\n sampleData == %@", [sampleData enhancedDescription]];
			}
		}
	}
	
#endif
	
	return description;
}

@end


