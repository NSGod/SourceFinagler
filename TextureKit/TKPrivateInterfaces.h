//
//  TKPrivateInterfaces.h
//  Texture Kit
//
//  Created by Mark Douma on 10/31/2011.
//  Copyright (c) 2010-2014 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TextureKitDefines.h>
#import <TextureKit/TKImage.h>
#import <TextureKit/TKImageRep.h>
#import <TextureKit/TKDDSImageRep.h>
#import <TextureKit/TKVTFImageRep.h>
#import <Foundation/Foundation.h>
#import "TKFoundationAdditions.h"



#define kBGRX_5551_BitmapInfo				kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder16Little
#define kXBGR_1555_BitmapInfo				kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder16Little

#define kBGRX_BitmapInfo					kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little
#define kXBGR_BitmapInfo					kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Little
#define kBGRA_BitmapInfo					kCGImageAlphaFirst | kCGBitmapByteOrder32Little
#define kPremultipliedBGRA_BitmapInfo		kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little
#define kABGR_BitmapInfo					kCGImageAlphaLast | kCGBitmapByteOrder32Little
#define kPremultipliedABGR_BitmapInfo		kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Little

#define kL_16_BitmapInfo					kCGImageAlphaNone | kCGBitmapByteOrder16Little
#define kLA_16_BitmapInfo					kCGImageAlphaLast | kCGBitmapByteOrder16Little
#define kPremultipliedLA_16_BitmapInfo		kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder16Little

#define kRGB_16_BitmapInfo					kCGImageAlphaNone | kCGBitmapByteOrder16Little
#define kRGBA_16_BitmapInfo					kCGImageAlphaLast | kCGBitmapByteOrder16Little
#define kPremultipliedRGBA_16_BitmapInfo	kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder16Little

#define kR_16F_BitmapInfo				kCGImageAlphaNone | kCGBitmapFloatComponents | kCGBitmapByteOrder16Little
#define kRG_16F_BitmapInfo				kCGImageAlphaNone | kCGBitmapFloatComponents | kCGBitmapByteOrder16Little
#define kRGBA_16F_BitmapInfo			kCGImageAlphaLast | kCGBitmapFloatComponents | kCGBitmapByteOrder16Little

#define kR_32F_BitmapInfo				kCGImageAlphaNone | kCGBitmapFloatComponents | kCGBitmapByteOrder32Little
#define kRG_32F_BitmapInfo				kCGImageAlphaNone | kCGBitmapFloatComponents | kCGBitmapByteOrder32Little
#define kRGB_32F_BitmapInfo				kCGImageAlphaNone | kCGBitmapFloatComponents | kCGBitmapByteOrder32Little
#define kRGBA_32F_BitmapInfo			kCGImageAlphaLast | kCGBitmapFloatComponents | kCGBitmapByteOrder32Little


#define TKIsPremultiplied(bitmapInfo) ((bitmapInfo & kCGBitmapAlphaInfoMask) == kCGImageAlphaPremultipliedLast || (bitmapInfo & kCGBitmapAlphaInfoMask) == kCGImageAlphaPremultipliedFirst)

#define TKHasAlpha(alphaInfo) !(alphaInfo == kCGImageAlphaNone || alphaInfo == kCGImageAlphaNoneSkipFirst || alphaInfo == kCGImageAlphaNoneSkipLast)


#define TK_ARRAY_SIZE(x) (sizeof(x)/sizeof((x)[0]))



/* continuation of TKPixelFormat values, hiding the ones that aren't native from the public interface */

enum {
	
	/* non-native below this point */
	
	TKPixelFormatLA44			= 31,	// non-native
	
	TKPixelFormatBGR,			// non-native
	
	TKPixelFormatRGBA1010102,	// non-native
	TKPixelFormatBGRA1010102,	// non-native
	
	TKPixelFormatRG1616,		// non-native
	
	TKPixelFormatR16F,			// non-native
	TKPixelFormatRG1616F,		// non-native
	TKPixelFormatRGBA16161616F,	// non-native
	
	TKPixelFormatRG3232F,		// non-native

};


enum {
	TKColorSpaceNone			= 0,
	TKColorSpaceGray			= 1,
	TKColorSpaceSRGB			= 2,
	TKColorSpaceLinearGray		= 3,
	TKColorSpaceLinearRGB		= 4,
};
typedef NSUInteger TKColorSpace;




typedef struct TKPixelFormatInfo {
	const TKPixelFormat			pixelFormat;
	
	const NSUInteger			bitsPerPixel;
	const NSUInteger			bytesPerPixel;
	
	const NSUInteger			componentCount;
	
	const NSUInteger			rBitsPerPixel;
	const NSUInteger			gBitsPerPixel;
	const NSUInteger			bBitsPerPixel;
	const NSUInteger			aBitsPerPixel;
	
	const NSInteger				rIndex;
	const NSInteger				gIndex;
	const NSInteger				bIndex;
	const NSInteger				aIndex;
	
	const NSUInteger			bitsPerComponent;
	const CGBitmapInfo			bitmapInfo;
	const TKColorSpace			colorSpace;
	NSString			* const description;
} TKPixelFormatInfo;


static const TKPixelFormatInfo TKPixelFormatInfoTable[] = {
	
	{TKPixelFormatUnknown,						0,	0,		0,		0,	0,	0,	0,		-1,	-1,	-1,	-1,		0,		0,									TKColorSpaceNone,			@"TKPixelFormatUnknown"},
	
	{TKPixelFormatXRGB1555,						16, 2,		4,		5,	5,	5,	0,		1,	2,	3,	-1,		5,		kCGImageAlphaNoneSkipFirst,			TKColorSpaceSRGB,			@"TKPixelFormatXRGB1555"}, /* NOT used by DDS or VTF formats */
	{TKPixelFormatRGBX5551,						16, 2,		4,		5,	5,	5,	0,		0,	1,	2,	-1,		5,		kCGImageAlphaNoneSkipLast,			TKColorSpaceSRGB,			@"TKPixelFormatRGBX5551"}, /* NOT used by DDS or VTF formats */
	
	{TKPixelFormatBGRX5551,						16, 2,		4,		5,	5,	5,	0,		2,	1,	0,	-1,		5,		kBGRX_5551_BitmapInfo,				TKColorSpaceSRGB,			@"TKPixelFormatBGRX5551"}, /* no longer used by DDS or VTF formats */
	{TKPixelFormatXBGR1555,						16, 2,		4,		5,	5,	5,	0,		1,	2,	3,	-1,		5,		kXBGR_1555_BitmapInfo,				TKColorSpaceSRGB,			@"TKPixelFormatXBGR5551"}, /* NOT used by DDS or VTF formats */
	
	{TKPixelFormatA,							8, 1,		1,		0,	0,	0,	8,		-1,	-1,	-1,	0,		8,		kCGImageAlphaNone,					TKColorSpaceGray,			@"TKPixelFormatA"},
	{TKPixelFormatL,							8, 1,		1,		8,	0,	0,	0,		0,	-1,	-1,	-1,		8,		kCGImageAlphaNone,					TKColorSpaceGray,			@"TKPixelFormatL"},
	{TKPixelFormatLA,							16, 2,		2,		8,	0,	0,	8,		0,	-1,	-1,	1,		8,		kCGImageAlphaLast,					TKColorSpaceGray,			@"TKPixelFormatLA"},
	{TKPixelFormatPremultipliedLA,				16, 2,		2,		8,	0,	0,	8,		0,	-1,	-1,	1,		8,		kCGImageAlphaPremultipliedLast,		TKColorSpaceGray,			@"TKPixelFormatPremultipliedLA"},
	
	{TKPixelFormatRGB,							24, 3,		3,		8,	8,	8,	0,		0,	1,	2,	-1,		8,		kCGImageAlphaNone,					TKColorSpaceSRGB,			@"TKPixelFormatRGB"},
	{TKPixelFormatXRGB,							32, 4,		4,		8,	8,	8,	0,		1,	2,	3,	-1,		8,		kCGImageAlphaNoneSkipFirst,			TKColorSpaceSRGB,			@"TKPixelFormatXRGB"},
	{TKPixelFormatRGBX,							32, 4,		4,		8,	8,	8,	0,		0,	1,	2,	-1,		8,		kCGImageAlphaNoneSkipLast,			TKColorSpaceSRGB,			@"TKPixelFormatRGBX"},
	
	{TKPixelFormatBGRX,							32, 4,		4,		8,	8,	8,	0,		2,	1,	0,	-1,		8,		kBGRX_BitmapInfo,					TKColorSpaceSRGB,			@"TKPixelFormatBGRX"},
	{TKPixelFormatXBGR,							32, 4,		4,		8,	8,	8,	0,		3,	2,	1,	-1,		8,		kXBGR_BitmapInfo,					TKColorSpaceSRGB,			@"TKPixelFormatXBGR"},

	{TKPixelFormatARGB,							32, 4,		4,		8,	8,	8,	8,		1,	2,	3,	0,		8,		kCGImageAlphaFirst,					TKColorSpaceSRGB,			@"TKPixelFormatARGB"},
	{TKPixelFormatPremultipliedARGB,			32, 4,		4,		8,	8,	8,	8,		1,	2,	3,	0,		8,		kCGImageAlphaPremultipliedFirst,	TKColorSpaceSRGB,			@"TKPixelFormatPremultipliedARGB"},
	{TKPixelFormatRGBA,							32, 4,		4,		8,	8,	8,	8,		0,	1,	2,	3,		8,		kCGImageAlphaLast,					TKColorSpaceSRGB,			@"TKPixelFormatRGBA"},
	{TKPixelFormatPremultipliedRGBA,			32, 4,		4,		8,	8,	8,	8,		0,	1,	2,	3,		8,		kCGImageAlphaPremultipliedLast,		TKColorSpaceSRGB,			@"TKPixelFormatPremultipliedRGBA"},
	
	{TKPixelFormatBGRA,							32, 4,		4,		8,	8,	8,	8,		2,	1,	0,	3,		8,		kBGRA_BitmapInfo,					TKColorSpaceSRGB,			@"TKPixelFormatBGRA"},
	{TKPixelFormatPremultipliedBGRA,			32, 4,		4,		8,	8,	8,	8,		2,	1,	0,	3,		8,		kPremultipliedBGRA_BitmapInfo,		TKColorSpaceSRGB,			@"TKPixelFormatPremultipliedBGRA"},
	{TKPixelFormatABGR,							32, 4,		4,		8,	8,	8,	8,		3,	2,	1,	0,		8,		kABGR_BitmapInfo,					TKColorSpaceSRGB,			@"TKPixelFormatABGR"},
	{TKPixelFormatPremultipliedABGR,			32, 4,		4,		8,	8,	8,	8,		3,	2,	1,	0,		8,		kPremultipliedABGR_BitmapInfo,		TKColorSpaceSRGB,			@"TKPixelFormatPremultipliedABGR"},
	
	
	{TKPixelFormatL16,							16, 2,		1,		16,	0,	0,	0,		0,	-1,	-1,	-1,		16,		kL_16_BitmapInfo,					TKColorSpaceGray,			@"TKPixelFormatL16"},
	{TKPixelFormatLA1616,						32, 4,		2,		16,	0,	0,	16,		0,	-1,	-1,	1,		16,		kLA_16_BitmapInfo,					TKColorSpaceGray,			@"TKPixelFormatLA1616"},
	{TKPixelFormatPremultipliedLA1616,			32, 4,		2,		16,	0,	0,	16,		0,	-1,	-1,	1,		16,		kPremultipliedLA_16_BitmapInfo,		TKColorSpaceGray,			@"TKPixelFormatPremultipliedLA1616"},
	
	
	{TKPixelFormatRGB161616,					48, 6,		3,		16,	16,	16,	0,		0,	1,	2,	-1,		16,		kRGB_16_BitmapInfo,					TKColorSpaceSRGB,			@"TKPixelFormatRGB161616"},
	{TKPixelFormatRGBA16161616,					64, 8,		4,		16,	16,	16,	16,		0,	1,	2,	3,		16,		kRGBA_16_BitmapInfo,				TKColorSpaceSRGB,			@"TKPixelFormatRGBA16161616"},
	{TKPixelFormatPremultipliedRGBA16161616,	64, 8,		4,		16,	16,	16,	16,		0,	1,	2,	3,		16,		kPremultipliedRGBA_16_BitmapInfo,	TKColorSpaceSRGB,			@"TKPixelFormatPremultipliedRGBA16161616"},
	
	{TKPixelFormatR32F,							32, 4,		1,		32,	0,	0,	0,		0,	-1,	-1,	-1,		32,		kR_32F_BitmapInfo,					TKColorSpaceLinearGray,		@"TKPixelFormatR32F"},
	{TKPixelFormatRGB323232F,					96, 12,		3,		32,	32,	32,	0,		0,	1,	2,	-1,		32,		kRGB_32F_BitmapInfo,				TKColorSpaceLinearRGB,		@"TKPixelFormatRGB323232F"},
	{TKPixelFormatRGBA32323232F,				128, 16,	4,		32,	32,	32,	32,		0,	1,	2,	3,		32,		kRGBA_32F_BitmapInfo,				TKColorSpaceLinearRGB,		@"TKPixelFormatRGBA32323232F"},
	
	/* non-native below this point */
	
	{TKPixelFormatLA44,							8, 1,		2,		4,	0,	0,	4,		0,	-1,	-1,	1,		4,		kCGImageAlphaLast,					TKColorSpaceGray,			@"TKPixelFormatLA44"},			/* converted to TKPixelFormatLA */
	
	{TKPixelFormatBGR,							24, 3,		3,		8,	8,	8,	0,		2,	1,	0,	-1,		8,		kCGImageAlphaNone,					TKColorSpaceSRGB,			@"TKPixelFormatBGR"},			/* converted to TKPixelFormatRGB */
	
	{TKPixelFormatRGBA1010102,					32, 4,		4,		10,	10,	10,	2,		0,	1,	2,	3,		10,		kCGImageAlphaLast,					TKColorSpaceSRGB,			@"TKPixelFormatRGBA1010102"},	/* converted to TKPixelFormatRGBA16161616 */
	{TKPixelFormatBGRA1010102,					32, 4,		4,		10,	10,	10,	2,		2,	1,	0,	3,		10,		kCGImageAlphaLast,					TKColorSpaceSRGB,			@"TKPixelFormatBGRA1010102"},	/* converted to TKPixelFormatRGBA16161616 */
	
	{TKPixelFormatRG1616,						32, 4,		2,		16,	16,	0,	0,		0,	1,	-1,	-1,		16,		kCGImageAlphaNone,					TKColorSpaceSRGB,			@"TKPixelFormatRG1616"},		/* converted to TKPixelFormatRGB161616 */
	
	{TKPixelFormatR16F,							16, 2,		1,		16,	0,	0,	0,		0,	-1,	-1,	-1,		16,		kR_16F_BitmapInfo,					TKColorSpaceLinearGray,		@"TKPixelFormatR16F"},			/* converted to TKPixelFormatR32F */
	{TKPixelFormatRG1616F,						32, 4,		2,		16,	16,	0,	0,		0,	1,	-1,	-1,		16,		kRG_16F_BitmapInfo,					TKColorSpaceLinearRGB,		@"TKPixelFormatRG1616F"},		/* converted to TKPixelFormatRGB323232F */
	{TKPixelFormatRGBA16161616F,				64, 8,		4,		16,	16,	16,	16,		0,	1,	2,	3,		16,		kRGBA_16F_BitmapInfo,				TKColorSpaceLinearRGB,		@"TKPixelFormatRGBA16161616F"}, /* converted to TKPixelFormatRGBA32323232F */
	
	{TKPixelFormatRG3232F,						64, 8,		2,		32,	32,	0,	0,		0,	1,	-1,	-1,		32,		kRG_32F_BitmapInfo,					TKColorSpaceLinearRGB,		@"TKPixelFormatRG3232F"},		/* converted to TKPixelFormatRGB323232F */
	
	
};
static const NSUInteger TKPixelFormatInfoTableCount = TK_ARRAY_SIZE(TKPixelFormatInfoTable);



TEXTUREKIT_STATIC_INLINE TKPixelFormat TKPixelFormatFromCGImage(CGImageRef imageRef) {
	NSCParameterAssert(imageRef != NULL);
	size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
	CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
	for (NSUInteger i = 0; i < TKPixelFormatInfoTableCount; i++) {
		if (TKPixelFormatInfoTable[i].bitsPerPixel == bitsPerPixel && TKPixelFormatInfoTable[i].bitmapInfo == bitmapInfo) {
			return TKPixelFormatInfoTable[i].pixelFormat;
		}
	}
	return TKPixelFormatUnknown;
}

TEXTUREKIT_STATIC_INLINE TKPixelFormatInfo TKPixelFormatInfoFromPixelFormat(TKPixelFormat aPixelFormat) {
	NSCParameterAssert(aPixelFormat < TKPixelFormatInfoTableCount);
	return TKPixelFormatInfoTable[aPixelFormat];
}

TEXTUREKIT_STATIC_INLINE NSString *TKStringFromPixelFormat(TKPixelFormat aPixelFormat) {
	NSCParameterAssert(aPixelFormat < TKPixelFormatInfoTableCount);
	return TKPixelFormatInfoTable[aPixelFormat].description;
}


TEXTUREKIT_STATIC_INLINE BOOL TKIsPowerOfTwo(NSUInteger n) {
	return n > 0 && (n & (n - 1)) == 0;
}

TEXTUREKIT_STATIC_INLINE NSUInteger TKNextPowerOfTwo(NSUInteger n) {
	if (n == 0) return 1;
	if (TKIsPowerOfTwo(n)) return n;
	
	n--;
	for (NSUInteger i = 1; i <= sizeof(NSUInteger) * 4; i <<= 1) {
		n |= (n >> i);
	}
	n++;
	return n;
}

TEXTUREKIT_STATIC_INLINE NSUInteger TKPreviousPowerOfTwo(NSUInteger n) {
	return TKNextPowerOfTwo(n + 1) / 2;
}

TEXTUREKIT_STATIC_INLINE NSUInteger TKNearestPowerOfTwo(NSUInteger n) {
	const NSUInteger nextPowerOfTwo = TKNextPowerOfTwo(n);
	const NSUInteger previousPowerOfTwo = TKPreviousPowerOfTwo(n);
	
	if (nextPowerOfTwo - n <= n - previousPowerOfTwo) {
		return nextPowerOfTwo;
	} else {
		return previousPowerOfTwo;
	}
}



#if defined(__cplusplus)
extern "C"  {
#endif
	
__attribute__((visibility("hidden"))) extern CGColorSpaceRef TKCreateColorSpaceFromColorSpace(TKColorSpace colorSpace);
	
__attribute__((visibility("hidden"))) extern NSString *TKStringFromCGBitmapInfo(CGBitmapInfo bitmapInfo);

__attribute__((visibility("hidden"))) extern NSString *TKLocalizedStringFromImageSourceStatus(CGImageSourceStatus status);
	
#if defined(__cplusplus)
}
#endif





@interface TKImage ()

@property (retain) NSMutableDictionary *allIndexes;

- (TKImageRep *)representationForSliceIndex:(NSUInteger)sliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;
- (void)setRepresentation:(TKImageRep *)representation forSliceIndex:(NSUInteger)sliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;
- (void)removeRepresentationForSliceIndex:(NSUInteger)sliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)frameIndex mipmapIndex:(NSUInteger)mipmapIndex;

- (void)resizeRepresentationsUsingResizeMode:(TKResizeMode)resizeMode resizeFilter:(TKResizeFilter)resizeFilter;

/* Creates an autoreleased copy of the receiver in which all image reps have been resized using the specified resize mode and filter. */
- (TKImage *)imageByResizingRepresentationsUsingResizeMode:(TKResizeMode)resizeMode resizeFilter:(TKResizeFilter)resizeFilter;

@end



enum {
	TKPixelFormatConversionOptionsDefault			= 0,
	TKPixelFormatConversionIgnoreAlpha				= 1 << 0,
	TKPixelFormatConversionUseColorManagement		= 1 << 1,
};
typedef NSUInteger TKPixelFormatConversionOptions;



@interface TKImageRep ()


+ (NSArray *)imageRepsWithData:(NSData *)containerData firstRepresentationOnly:(BOOL)firstRepOnly error:(NSError **)outError;

- (id)initWithPixelData:(NSData *)pixelData pixelFormat:(TKPixelFormat)aPixelFormat pixelsWide:(NSInteger)width pixelsHigh:(NSInteger)height sliceIndex:(NSUInteger)aSliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)aFrameIndex mipmapIndex:(NSUInteger)aMipmapIndex;


@property (nonatomic, assign) NSUInteger sliceIndex;
@property (nonatomic, assign) TKFace face;
@property (nonatomic, assign) NSUInteger frameIndex;
@property (nonatomic, assign) NSUInteger mipmapIndex;

@property (nonatomic, assign) TKPixelFormat pixelFormat;
@property (nonatomic, assign) CGBitmapInfo bitmapInfo;
@property (nonatomic, assign) CGImageAlphaInfo alphaInfo;

@property (nonatomic, copy) NSDictionary *imageProperties;


- (void)setSliceIndex:(NSUInteger)aSliceIndex face:(TKFace)aFace frameIndex:(NSUInteger)aFrameIndex mipmapIndex:(NSUInteger)aMipmapIndex;


- (NSData *)dataByConvertingToPixelFormat:(TKPixelFormat)aPixelFormat options:(TKPixelFormatConversionOptions)options;


/* Creates an autoreleased copy of the receiver that has been resized using the specified resize mode and filter. */
- (TKImageRep *)imageRepByResizingUsingResizeMode:(TKResizeMode)resizeMode resizeFilter:(TKResizeFilter)resizeFilter;


- (NSArray *)mipmapImageRepsUsingFilter:(TKMipmapGenerationType)filterType;


+ (NSData *)representationOfImageRepsInArray:(NSArray *)imageReps usingImageType:(NSString *)utiType properties:(NSDictionary *)properties;


@end





@interface TKDDSImageRep ()

@property (nonatomic, assign) TKDDSFormat format;
@property (nonatomic, assign) TKDDSContainer container;


+ (NSData *)dataByConvertingData:(NSData *)inputData inFormat:(TKPixelFormat)inputPixelFormat toFormat:(TKPixelFormat)outputPixelFormat pixelCount:(NSUInteger)pixelCount options:(TKPixelFormatConversionOptions)options;


+ (TKImageRep *)imageRepByResizingImageRep:(TKImageRep *)imageRep usingResizeMode:(TKResizeMode)resizeMode resizeFilter:(TKResizeFilter)resizeFilter;

+ (NSArray *)mipmapImageRepsOfImageRep:(TKImageRep *)imageRep usingFilter:(TKMipmapGenerationType)filterType;


@end



@interface TKVTFImageRep ()

@property (nonatomic, assign) TKVTFFormat format;

@end




