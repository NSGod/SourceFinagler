//
//  TKDDSImageRep.mm
//  Texture Kit
//
//  Created by Mark Douma on 9/25/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKDDSImageRep.h>
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>
#import <NVTextureTools/NVTextureTools.h>

#import "TKFoundationAdditions.h"


NSData *TKImageDataFromNSData(NSData *data, NSUInteger pixelCount, NSUInteger bitsPerPixel, CGBitmapInfo sourceBitmapInfo, CGBitmapInfo destinationBitmapInfo);
NSData *TKBGRADataFromImageData(NSData *data, NSUInteger pixelCount, NSUInteger bitsPerPixel, CGBitmapInfo aCGBitmapInfo);

struct TKDDSFormatDescription {
	TKDDSFormat		format;
	NSString		*description;
};
	
static const TKDDSFormatDescription TKDDSFormatDescriptionTable[] = {
	{ TKDDSFormatRGB, @"RGB" },
	{ TKDDSFormatRGBA, @"RGBA" },
	{ TKDDSFormatDXT1, @"DXT1" },
	{ TKDDSFormatDXT1a, @"DXT1a" },
	{ TKDDSFormatDXT3, @"DXT3" },
	{ TKDDSFormatDXT5, @"DXT5" },
	{ TKDDSFormatBC4, @"BC4 (ATI1)" },
	{ TKDDSFormatBC5, @"BC5 (3DC, ATI2)" },
	{ TKDDSFormatRGBE, @"RGBE" }
};
static const NSUInteger TKDDSFormatTableCount = sizeof(TKDDSFormatDescriptionTable)/sizeof(TKDDSFormatDescription);
	
	
NSString *NSStringFromDDSFormat(TKDDSFormat aFormat) {
	for (NSUInteger i = 0; i < TKDDSFormatTableCount; i++) {
		if (TKDDSFormatDescriptionTable[i].format == aFormat) {
			return TKDDSFormatDescriptionTable[i].description;
		}
	}
	return @"<Unknown>";
}
	

using namespace nv;

#define TK_DEBUG 0


NSString * const TKDDSType			= @"com.microsoft.dds";
NSString * const TKDDSFileType		= @"dds";
NSString * const TKDDSPboardType	= @"TKDDSPboardType";


@interface TKDDSImageRep (TKPrivate)
+ (NSArray *)imageRepsWithData:(NSData *)aData firstRepresentationOnly:(BOOL)firstRepOnly;
@end

using namespace nvtt;

struct TKOutputHandler : public OutputHandler {
	
	TKOutputHandler(NSMutableData *imageData) : imageData(imageData) {
		
	}
	
	virtual ~TKOutputHandler() { }
	
    virtual void beginImage(int size, int width, int height, int depth, int face, int miplevel) {
        // ignore.
    }
	
    virtual bool writeData(const void * data, int size) {
		printf("TKOutputHandler::writeData()\n");
		
		if (this->imageData) {
			[this->imageData appendBytes:data length:size];
		}
        return true;
    }
	NSMutableData *imageData;
};



static TKDDSFormat defaultDDSFormat = TKDDSFormatDefault;

@implementation TKDDSImageRep

/* Implemented by subclassers to indicate what UTI-identified data types they can deal with. */
+ (NSArray *)imageUnfilteredTypes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	static NSArray *types = nil;
	if (types == nil) types = [[NSArray alloc] initWithObjects:TKDDSType, nil];
	return types;
}


+ (NSArray *)imageUnfilteredFileTypes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	static NSArray *fileTypes = nil;
	if (fileTypes == nil) fileTypes = [[NSArray alloc] initWithObjects:TKDDSFileType, nil];
	return fileTypes;
}

+ (NSArray *)imageUnfilteredPasteboardTypes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	static NSArray *imageUnfilteredPasteboardTypes = nil;
	
	if (imageUnfilteredPasteboardTypes == nil) {
		NSArray *types = [super imageUnfilteredPasteboardTypes];
		NSLog(@"[%@ %@] super's imageUnfilteredPasteboardTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), types);
		imageUnfilteredPasteboardTypes = [[types arrayByAddingObject:TKDDSPboardType] retain];
	}
	return imageUnfilteredPasteboardTypes;
}


//+ (BOOL)canInitWithPasteboard:(NSPasteboard *)pasteboard {
//	
//}


+ (BOOL)canInitWithData:(NSData *)data {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([data length] < sizeof(OSType)) return NO;
	OSType magic = 0;
	[data getBytes:&magic length:sizeof(magic)];
	magic = NSSwapBigIntToHost(magic);
	return (magic == TKDDSMagic);
}


+ (Class)imageRepClassForType:(NSString *)type {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([type isEqualToString:TKDDSType]) {
		return [self class];
	}
	return [super imageRepClassForType:type];
}

+ (Class)imageRepClassForFileType:(NSString *)fileType {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([fileType isEqualToString:TKDDSFileType]) {
		return [self class];
	}
	return [super imageRepClassForFileType:fileType];
}


+ (TKDDSFormat)defaultFormat {
	return defaultDDSFormat;
}

+ (void)setDefaultFormat:(TKDDSFormat)aFormat {
	defaultDDSFormat = aFormat;
}


+ (NSData *)DDSRepresentationOfImageRepsInArray:(NSArray *)tkImageReps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] DDSRepresentationOfImageRepsInArray:tkImageReps usingFormat:defaultDDSFormat quality:[[self class] defaultDXTCompressionQuality] createMipmaps:YES];
}


+ (NSData *)DDSRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingFormat:(TKDDSFormat)aFormat quality:(TKDXTCompressionQuality)aQuality createMipmaps:(BOOL)createMipmaps {
#if TK_DEBUG
	NSLog(@"[%@ %@] tkImageReps == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tkImageReps);
#endif
	NSUInteger imageRepCount = [tkImageReps count];
	
	if (imageRepCount == 0) {
		return nil;
	}
	
	NSMutableData *ddsData = [[NSMutableData alloc] init];
	
	TKImageRep *imageRep = [TKImageRep largestRepresentationInArray:tkImageReps];
	NSData *data = [imageRep data];
	CGImageAlphaInfo cgAlphaInfo = [imageRep alphaInfo];
	
	NSLog(@"[%@ %@] alphaInfo == %u", NSStringFromClass([self class]), NSStringFromSelector(_cmd), cgAlphaInfo);
	
	NSData *swappedData = TKBGRADataFromImageData(data, [imageRep pixelsWide] * [imageRep pixelsHigh], [imageRep bitsPerPixel], cgAlphaInfo);
	
	if (swappedData) {
		InputOptions inputOptions;
		inputOptions.setTextureLayout(TextureType_2D, [imageRep pixelsWide], [imageRep pixelsHigh]);
		inputOptions.setFormat(InputFormat_BGRA_8UB);
		inputOptions.setMipmapData([swappedData bytes], [imageRep pixelsWide], [imageRep pixelsHigh]);
		
		inputOptions.setWrapMode(WrapMode_Clamp);
		inputOptions.setRoundMode(RoundMode_ToNearestPowerOfTwo);
		inputOptions.setNormalMap(false);
		inputOptions.setConvertToNormalMap(false);
		inputOptions.setGamma(2.2, 2.2);
		inputOptions.setMipmapGeneration(createMipmaps);
		
		CompressionOptions compressionOptions;
		compressionOptions.setFormat(static_cast<nvtt::Format>(aFormat));
		compressionOptions.setQuality(static_cast<nvtt::Quality>(aQuality));
		
		Context context;
		context.enableCudaAcceleration(false);
		
		TKOutputHandler outputHandler(ddsData);
		
		OutputOptions outputOptions;
		outputOptions.setOutputHandler(&outputHandler);
		
		if (!context.process(inputOptions, compressionOptions, outputOptions)) {
			NSLog(@"[%@ %@] context.process() returned false!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		}
		NSLog(@"[%@ %@] ddsData length == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)[ddsData length]);
		NSData *copiedData = [ddsData copy];
		[ddsData release];
		return [copiedData autorelease];
	}
	[ddsData release];
	return nil;
}


static unsigned char *TKCreateRGBADataFromColor32(Color32 *pixels, NSUInteger pixelCount, NSUInteger bitsPerPixel, NSUInteger *length) {
	if (pixels == NULL || pixelCount == 0 || bitsPerPixel == 0 || (bitsPerPixel != 24 && bitsPerPixel != 32) || length == NULL) {
		NSLog(@"TKCreateRGBADataFromColor32() invalid parameters!");
		return NULL;
	}
	NSUInteger newLength = pixelCount * 4;
	
	int col;
	unsigned char *cp = (unsigned char *)&col;
	
	unsigned int *bytes = (unsigned int *)malloc(newLength);
	
	if (bytes == NULL) {
		NSLog(@"TKCreateRGBADataFromColor32() malloc(%llu) failed!", (unsigned long long)newLength);
		return NULL;
	}
	
	*length = newLength;
	
	cp[3] = 0xff;	// default alpha if alpha channel isn't present
	
	Color32 pixel;
	
	for (unsigned int i = 0; i < pixelCount; i++) {
		pixel = pixels[i];
		cp[0] = pixel.r;	/* set R component of col	*/
		cp[1] = pixel.g;	/* set G component of col	*/
		cp[2] = pixel.b;	/* set B component of col	*/
							
		if (bitsPerPixel == 32) {
			cp[3] = pixel.a; /* set A component of col	*/
		}
		bytes[i] = col;
	}
	return (unsigned char *)bytes;
}


+ (NSArray *)imageRepsWithData:(NSData *)aData firstRepresentationOnly:(BOOL)firstRepOnly {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	OSType magic = 0;
	[aData getBytes:&magic length:sizeof(magic)];
	magic = NSSwapBigIntToHost(magic);
#if TK_DEBUG
	NSLog(@"[%@ %@] magic == 0x%x, %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), magic, NSFileTypeForHFSTypeCode(magic));
#endif
	
	DirectDrawSurface *dds = new DirectDrawSurface((unsigned char *)[aData bytes], [aData length]);
	if (dds == 0) {
		NSLog(@"[%@ %@] new DirectDrawSurface() with data failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return nil;
	}
	
	if (!dds->isValid() || !dds->isSupported() || (dds->width() > 65535) || (dds->height() > 65535)) {
		if (!dds->isValid()) {
			NSLog(@"[%@ %@] dds image is not valid, info follows:", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		} else if (!dds->isSupported()) {
			NSLog(@"[%@ %@] dds image format is not supported, info follows:", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		} else {
			NSLog(@"[%@ %@] dds image dimensions are too large, info follows:", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		}
		dds->printInfo();
		delete dds;
		return nil;
	}
#if TK_DEBUG
	NSLog(@"[%@ %@] dds info == \n", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	dds->printInfo();
#endif
	
	NSMutableArray *bitmapImageReps = [NSMutableArray array];
	
	const NSUInteger mipmapCount = dds->mipmapCount();
	const NSUInteger faceCount = dds->isTextureCube() ? 6 : 1;
	
	for (NSUInteger mipmap = 0; mipmap < mipmapCount; mipmap++) {
		for (NSUInteger faceIndex = 0; faceIndex < faceCount; faceIndex++) {
			Image nvImage;
			dds->mipmap(&nvImage, faceIndex, mipmap);
			NSUInteger length = 0;
			unsigned char *bytes = TKCreateRGBADataFromColor32(nvImage.pixels(), nvImage.width() * nvImage.height(), (nvImage.format() == Image::Format_ARGB ? 32 : 24), &length);
			if (bytes) {
				NSData *convertedData = [[NSData alloc] initWithBytes:bytes length:length];
				free(bytes);
				CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)convertedData);
				[convertedData release];
				CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
				NSUInteger bitsPerPixel = (dds->hasAlpha() ? 32 : 24);
				CGImageRef imageRef = CGImageCreate(nvImage.width(),
													nvImage.height(),
													8,
													32,
													nvImage.width() * 4,
													colorSpace,
													(bitsPerPixel == 32 ? kCGImageAlphaLast : kCGImageAlphaNoneSkipLast),
													provider,
													NULL,
													false,
													kCGRenderingIntentDefault);
				CGColorSpaceRelease(colorSpace);
				CGDataProviderRelease(provider);
				
				if (imageRef) {
					
					TKDDSImageRep *imageRep = [[TKDDSImageRep alloc] initWithCGImage:imageRef
																		  sliceIndex:0
																				face:faceIndex
																		  frameIndex:0
																		 mipmapIndex:mipmap];
					
					CGImageRelease(imageRef);
					if (imageRep) {
						[bitmapImageReps addObject:imageRep];
						[imageRep release];
					}
					
					if (firstRepOnly && faceIndex == 0 && mipmap == 0) {
						delete dds;
						return [[bitmapImageReps copy] autorelease];
					}
					
				} else {
					NSLog(@"[%@ %@] CGImageCreate() (for faceIndex == %lu, mipmapIndex == %lu) failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)faceIndex, (unsigned long)mipmap);
				}
			}
		}
	}
	delete dds;
	return [[bitmapImageReps copy] autorelease];
	
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
		self = nil;
		return self;
	}
	self = [[imageReps objectAtIndex:0] retain];
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	TKDDSImageRep *copy = (TKDDSImageRep *)[super copyWithZone:zone];
	NSLog(@"[%@ %@] copy == %@, class == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), copy, NSStringFromClass([copy class]));
	return copy;
}


- (id)initWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithCoder:coder])) {
		
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super encodeWithCoder:coder];
	
}


@end


#pragma pack(1)

typedef struct TKColor24 {
	UInt8	x;
	UInt8	y;
	UInt8	z;
} TKColor24;


typedef struct TKColor32 {
	UInt8	x;
	UInt8	y;
	UInt8	z;
	UInt8	w;
} TKColor32;

#pragma pack()


enum {
	TKBGRA	= UINT_MAX
};

NSData *TKImageDataFromNSData(NSData *inputData, NSUInteger pixelCount, NSUInteger bitsPerPixel, CGBitmapInfo sourceBitmapInfo, CGBitmapInfo destBitmapInfo) {
	if (inputData == nil || pixelCount == 0 || bitsPerPixel == 0 || (bitsPerPixel != 24 && bitsPerPixel != 32)) {
		NSLog(@"TKImageDataFromNSData() invalid parameters!");
		return nil;
	}
	
	NSUInteger newLength = pixelCount;
	
	if (destBitmapInfo == kCGImageAlphaNone) 
		newLength *= 3;
	else
		newLength *= 4;
	
	void *vBytes = malloc(newLength);
	
	
	if (sourceBitmapInfo == kCGImageAlphaNone) {
		TKColor24 *sourcePixels = (TKColor24 *)[inputData bytes];
		TKColor24 sourcePixel;
		
		
		if (destBitmapInfo == kCGImageAlphaNone) {
			free(vBytes);
			return inputData;
			
		} else {
			TKColor32 *destPixels = (TKColor32 *)vBytes;
			TKColor32 destPixel;
			
			for (NSUInteger i = 0; i < pixelCount; i++) {
				sourcePixel = sourcePixels[i];
				
				if (destBitmapInfo == TKBGRA) {
					
					destPixel.x = sourcePixel.z;
					destPixel.y = sourcePixel.y;
					destPixel.z = sourcePixel.x;
					
					destPixel.w = 0xff;
					
					
				} else if (destBitmapInfo == kCGImageAlphaPremultipliedFirst ||
					destBitmapInfo == kCGImageAlphaFirst ||
					destBitmapInfo == kCGImageAlphaNoneSkipFirst) {
					
					destPixel.x = 0xff;
					
					destPixel.y = sourcePixel.x;
					destPixel.z = sourcePixel.y;
					destPixel.w = sourcePixel.z;
					
				} else {
					
					destPixel.x = sourcePixel.x;
					destPixel.y = sourcePixel.y;
					destPixel.z = sourcePixel.z;
					
					destPixel.w = 0xff;
					
				}
				
				destPixels[i] = destPixel;
			}
			
			NSData *newData = [NSData dataWithBytes:destPixels length:newLength];
			free(vBytes);
			return newData;
			
		}
		
		
	} else {
		// 32 bit input image
		
		TKColor32 *sourcePixels = (TKColor32 *)[inputData bytes];
		TKColor32 sourcePixel;
		
		if (destBitmapInfo == kCGImageAlphaNone) {
			
			
		} else {
			TKColor32 *destPixels = (TKColor32 *)vBytes;
			TKColor32 destPixel;
			
			for (NSUInteger i = 0; i < pixelCount; i++) {
				sourcePixel = sourcePixels[i];
				
				if ((sourceBitmapInfo == kCGImageAlphaPremultipliedFirst ||
							sourceBitmapInfo == kCGImageAlphaFirst ||
							sourceBitmapInfo == kCGImageAlphaNoneSkipFirst) &&
						   destBitmapInfo == TKBGRA) {
					
					destPixel.x = sourcePixel.w;
					destPixel.y = sourcePixel.z;
					destPixel.z = sourcePixel.y;
					destPixel.w = sourcePixel.x;
					
					
				} else if ((sourceBitmapInfo == kCGImageAlphaPremultipliedLast ||
							sourceBitmapInfo == kCGImageAlphaLast ||
							sourceBitmapInfo == kCGImageAlphaNoneSkipLast) &&
						   destBitmapInfo == TKBGRA) {
					
					destPixel.x = sourcePixel.z;
					destPixel.y = sourcePixel.y;
					destPixel.z = sourcePixel.x;
					
					destPixel.w = sourcePixel.w;
					
				} else if ((sourceBitmapInfo == kCGImageAlphaPremultipliedFirst ||
					sourceBitmapInfo == kCGImageAlphaFirst ||
					sourceBitmapInfo == kCGImageAlphaNoneSkipFirst) &&
					destBitmapInfo == kCGImageAlphaPremultipliedLast ||
					destBitmapInfo == kCGImageAlphaLast ||
					destBitmapInfo == kCGImageAlphaNoneSkipLast) {
					
					destPixel.x = sourcePixel.y;
					destPixel.y = sourcePixel.z;
					destPixel.z = sourcePixel.w;
					destPixel.w = sourcePixel.x;
					
				}
					
				
				destPixels[i] = destPixel;
				
			}
			
			NSData *newData = [NSData dataWithBytes:destPixels length:newLength];
			free(vBytes);
			return newData;
			
		}
		
	}
	return nil;
}

NSData *TKBGRADataFromImageData(NSData *data, NSUInteger pixelCount, NSUInteger bitsPerPixel, CGBitmapInfo sourceBitmapInfo) {
	return TKImageDataFromNSData(data, pixelCount, bitsPerPixel, sourceBitmapInfo, TKBGRA);
}
