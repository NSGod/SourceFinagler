//
//  MDDDSImageRep.m
//  Image Finagler
//
//  Created by Mark Douma on 9/25/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDDDSImageRep.h"

#define MD_USE_NV_FRAMEWORKS 0

#if MD_USE_NV_FRAMEWORKS

#import <NVCore/StdStream.h>
#import <NVMath/Color.h>
#import <NVImage/NVImage.h>
#import <NVImage/Image.h>
#import <NVImage/DirectDrawSurface.h>

using namespace nv;

#else

//#include "Stream.h"
#include "DirectDrawSurface.h"

#endif


#import <ApplicationServices/ApplicationServices.h>


#define MD_DEBUG 1


NSString * const MDDDSIdentifier = @"com.markdouma.dds";


@implementation MDDDSImageRep

@synthesize version, compression, hasAlphaChannel, hasMipmaps;


+ (id)imageRepWithData:(NSData *)aData {
	return [[[[self class] alloc] initWithData:aData] autorelease];
}


- (id)initWithData:(NSData *)aData {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (aData) {
		
#if MD_USE_NV_FRAMEWORKS
		MemoryInputStream *memStream = new MemoryInputStream((const uint8 *)[aData bytes], [aData length]);
		if (memStream == 0) {
			NSLog(@"[%@ %@] failed to create new MemoryInputStream()", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			[self release];
			return nil;
		}
		DirectDrawSurface dds(memStream);
		if (!dds.isValid()) {
			NSLog(@"[%@ %@] dds() image is not valid, header follows:", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			dds.printInfo();
			delete memStream;
			[self release];
			return nil;
		}
		if (!dds.isSupported()) {
			NSLog(@"[%@ %@] dds() image format is not supported, header follows:", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			dds.printInfo();
			delete memStream;
			[self release];
			return nil;
		}
		if ((dds.width() > 65535) || (dds.height() > 65535)) {
			NSLog(@"[%@ %@] dds() image dimensions are too large, header follows:", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			dds.printInfo();
			delete memStream;
			[self release];
			return nil;
		}
		
#else
		
		MemoryInputStream *memStream = new MemoryInputStream((const uint8 *)[aData bytes], [aData length]);
		if (memStream == 0) {
			NSLog(@"[%@ %@] failed to create new MemoryInputStream()", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			[self release];
			return nil;
		}
		DirectDrawSurface dds(memStream);
		if (!dds.isValid()) {
			NSLog(@"[%@ %@] dds() image is not valid, header follows:", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			dds.printInfo();
			delete memStream;
			[self release];
			return nil;
		}
		if (!dds.isSupported()) {
			NSLog(@"[%@ %@] dds() image format is not supported, header follows:", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			dds.printInfo();
			delete memStream;
			[self release];
			return nil;
		}
		if ((dds.width() > 65535) || (dds.height() > 65535)) {
			NSLog(@"[%@ %@] dds() image dimensions are too large, header follows:", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			dds.printInfo();
			delete memStream;
			[self release];
			return nil;
		}
		
#endif
		
#if MD_DEBUG
		dds.printInfo();
#endif
		
		
		unsigned char bitsPerPixel = 0;
		Image img;
		NSUInteger numPixels = 0;
		int col;
		unsigned char *cp = (unsigned char *)&col;
		Color32 pixel;
		Color32 *pixels = 0;
		
		if (dds.hasAlpha()) {
			bitsPerPixel = 32;	
		} else {
			bitsPerPixel = 24;
		}
//		unsigned char *bytes = (unsigned char *)malloc(dds.width() * dds.height() * bitsPerPixel);
		
		NSUInteger newLength = (dds.width() * dds.height() * 4);
		
		unsigned int *bytes = (unsigned int *)malloc(newLength);
		
		if (bytes == NULL) {
			NSLog(@"[%@ %@] malloc() failed", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			delete memStream;
			[self release];
			return nil;
		}
#if MD_DEBUG
		NSLog(@"[%@ %@] %lu bytes malloced", NSStringFromClass([self class]), NSStringFromSelector(_cmd), newLength);
#endif
		
		dds.mipmap(&img, 0, 0);
		pixels = img.pixels();
		numPixels = dds.width() * dds.height();
		cp[3] = 0xff;	// default alpha if alpha channel isn't present
		
		for (unsigned int i = 0; i < numPixels; i++) {
			pixel = pixels[i];
			cp[0] = pixel.r;	/* set R component of col	*/
			cp[1] = pixel.g;	/* set G component of col	*/
			cp[2] = pixel.b;	/* set B component of col	*/
			if (bitsPerPixel == 32) {
				cp[3] = pixel.a; /* set A component of col	*/
			}
			bytes[i] = col;
		}
		
		NSData *data = [NSData dataWithBytes:bytes length:newLength];
		
		CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
		CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
		
		CGImageRef imageRef = NULL;
		imageRef = CGImageCreate(dds.width(),
								 dds.height(),
								 8,
								 32,
								 dds.width() * 4,
								 colorSpace,
								 (bitsPerPixel == 32 ? kCGImageAlphaLast : kCGImageAlphaNoneSkipLast),
								 provider,
								 NULL,
								 false,
								 kCGRenderingIntentDefault);
		
		if (imageRef == NULL) {
			NSLog(@"[%@ %@] CGImageCreate() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			delete memStream;
			CGColorSpaceRelease(colorSpace);
			CGDataProviderRelease(provider);
			if (bytes) free(bytes);
			[self release];
			return nil;
		}
		
		CGColorSpaceRelease(colorSpace);
		CGDataProviderRelease(provider);
		
#if MD_DEBUG
		NSLog(@"[%@ %@] CGImageRef created", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		if (self = [super initWithCGImage:imageRef]) {
#if MD_DEBUG
			NSLog(@"[%@ %@] initWithCGImage: succeeded", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
			if (bytes) free(bytes);
			if (imageRef) CGImageRelease(imageRef);
		}
	}
	return self;
}

- (void)dealloc {
	[version release];
	[compression release];
	[super dealloc];
}

@end


#if MD_DEBUG
//				NSMutableString *description = [NSMutableString string];
//				[description appendFormat:@"\nversion == %u.%u\n", file->GetMajorVersion(), file->GetMinorVersion()];
//				[description appendFormat:@"size == %u\n", file->GetSize()];
//				[description appendFormat:@"width == %u\n", file->GetWidth()];
//				[description appendFormat:@"height == %u\n", file->GetHeight()];
//				[description appendFormat:@"depth == %u\n", file->GetDepth()];
//				[description appendFormat:@"frameCount == %u\n", file->GetFrameCount()];
//				[description appendFormat:@"startFrame == %u\n", file->GetStartFrame()];
//				[description appendFormat:@"faceCount == %u\n", file->GetFaceCount()];
//				[description appendFormat:@"mipMapCount == %u\n", file->GetMipmapCount()];
//				[description appendFormat:@"flags == %u\n", file->GetFlags()];
//				[description appendFormat:@"Bumpmap scale == %.3f\n", file->GetBumpmapScale()];
//				[description appendFormat:@"VTFImageFormat == %u\n\n", file->GetFormat()];
//				[description appendFormat:@"VTFImageFormat == %s\n\n", imageFormatInfo.lpName];
//				[description appendFormat:@"LENGTH == %u\n\n", newLength];
//				NSLog(@"[%@ %@] description == %@\n\n", NSStringFromClass([self class]), NSStringFromSelector(_cmd), description);
#endif
