//
//  TKPrivateInterfaces.h
//  Texture Kit
//
//  Created by Mark Douma on 10/31/2011.
//  Copyright (c) 2010-2013 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKImageRep.h>


typedef struct TKPixelFormatInfo {
	TKPixelFormat			pixelFormat;
	NSUInteger				bitsPerComponent;
	NSUInteger				bitsPerPixel;
	CGBitmapInfo			bitmapInfo;
	CGColorSpaceModel		colorSpaceModel;
	CGColorRenderingIntent	renderingIntent;
} TKPixelFormatInfo;

static const TKPixelFormatInfo TKPixelFormatInfoTable[] = {
	{TKPixelFormatXRGB1555,			5, 16, kCGImageAlphaNoneSkipFirst, kCGColorSpaceModelRGB,	kCGRenderingIntentDefault},
	{TKPixelFormatL,				8, 8,  kCGImageAlphaNone,	kCGColorSpaceModelMonochrome,	kCGRenderingIntentDefault},
	{TKPixelFormatLA,				8, 16, kCGImageAlphaPremultipliedLast, kCGColorSpaceModelMonochrome,	 kCGRenderingIntentDefault},
	{TKPixelFormatA,				8, 8,  kCGImageAlphaOnly, kCGColorSpaceModelUnknown, kCGRenderingIntentDefault},
	{TKPixelFormatRGB,				8, 24, kCGImageAlphaNone, kCGColorSpaceModelRGB,	kCGRenderingIntentDefault},
	{TKPixelFormatXRGB,				8, 32, kCGImageAlphaNoneSkipFirst, kCGColorSpaceModelRGB,	kCGRenderingIntentDefault},
	{TKPixelFormatRGBX,				8, 32, kCGImageAlphaNoneSkipLast, kCGColorSpaceModelRGB,	kCGRenderingIntentDefault},
	{TKPixelFormatARGB,				8, 32, kCGImageAlphaPremultipliedFirst, kCGColorSpaceModelRGB,	kCGRenderingIntentDefault},
	{TKPixelFormatRGBA,				8, 32, kCGImageAlphaPremultipliedLast, kCGColorSpaceModelRGB,	kCGRenderingIntentDefault},
	{TKPixelFormatRGB161616,		16, 48, kCGImageAlphaNone | kCGBitmapByteOrder16Host, kCGColorSpaceModelRGB, kCGRenderingIntentDefault},
	{TKPixelFormatRGBA16161616,		16, 64, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder16Host, kCGColorSpaceModelRGB,	kCGRenderingIntentDefault},
	{TKPixelFormatL32F,				32, 32, kCGImageAlphaNone | kCGBitmapFloatComponents | kCGBitmapByteOrder32Host, kCGColorSpaceModelMonochrome, kCGRenderingIntentDefault},
	{TKPixelFormatRGB323232F,		32, 96, kCGImageAlphaNone | kCGBitmapFloatComponents | kCGBitmapByteOrder32Host, kCGColorSpaceModelRGB,	kCGRenderingIntentDefault},
	{TKPixelFormatRGBA32323232F,	32, 128, kCGImageAlphaPremultipliedLast | kCGBitmapFloatComponents | kCGBitmapByteOrder32Host, kCGColorSpaceModelRGB, kCGRenderingIntentDefault},
	{TKPixelFormatRGB565,			5, 16, kCGImageAlphaNoneSkipFirst, kCGColorSpaceModelRGB,	kCGRenderingIntentDefault},
	{TKPixelFormatBGR565,			5, 16, kCGImageAlphaNoneSkipFirst, kCGColorSpaceModelRGB,	kCGRenderingIntentDefault},
	{TKPixelFormatBGRX5551,			5, 16, kCGImageAlphaNoneSkipLast, kCGColorSpaceModelRGB,	kCGRenderingIntentDefault},
	{TKPixelFormatBGRA5551,			5, 16, kCGImageAlphaNoneSkipFirst, kCGColorSpaceModelRGB,	kCGRenderingIntentDefault},
	{TKPixelFormatBGRA,				8, 32, kCGImageAlphaPremultipliedLast, kCGColorSpaceModelRGB,	kCGRenderingIntentDefault},
	{TKPixelFormatRGBA16161616F,	16, 64, kCGImageAlphaPremultipliedLast | kCGBitmapFloatComponents | kCGBitmapByteOrder16Host, kCGColorSpaceModelRGB,	kCGRenderingIntentDefault},
};
static const NSUInteger TKPixelFormatInfoTableCount = sizeof(TKPixelFormatInfoTable)/sizeof(TKPixelFormatInfoTable[0]);


static inline TKPixelFormat TKPixelFormatFromCGImage(CGImageRef imageRef) {
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

static inline TKPixelFormatInfo TKPixelFormatInfoFromPixelFormat(TKPixelFormat aPixelFormat) {
	NSCParameterAssert(aPixelFormat < TKPixelFormatInfoTableCount);
	for (NSUInteger i = 0; i < TKPixelFormatInfoTableCount; i++) {
		if (TKPixelFormatInfoTable[i].pixelFormat == aPixelFormat) {
			TKPixelFormatInfo pixelFormatInfo = TKPixelFormatInfoTable[i];
			return pixelFormatInfo;
		}
	}
	TKPixelFormatInfo pixelFormatInfo = {0, 0, 0, 0, kCGColorSpaceModelUnknown, kCGRenderingIntentDefault};
	return pixelFormatInfo;
}


