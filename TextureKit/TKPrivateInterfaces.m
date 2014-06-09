//
//  TKPrivateInterfaces.m
//  Texture Kit
//
//  Created by Mark Douma on 10/31/2011.
//  Copyright (c) 2010-2014 Mark Douma LLC. All rights reserved.
//

#import "TKPrivateInterfaces.h"
#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#import <TextureKit/TKError.h>



CGColorSpaceRef TKCreateColorSpaceFromColorSpace(TKColorSpace colorSpace) {
	switch (colorSpace) {
		case TKColorSpaceGray : {
			if (TKGetSystemVersion() <= TKLeopard) {
				return CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
			} else {
				return CGColorSpaceCreateWithName(kCGColorSpaceGenericGrayGamma2_2);
			}
		}
			
		case TKColorSpaceSRGB :
			return CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
			
		case TKColorSpaceLinearGray : {
			NSString *linearGrayProfilePath = [[NSBundle bundleForClass:[TKImage class]] pathForResource:@"Linear Grayscale Profile" ofType:@"icc"];
			
			NSError *error = nil;
			
			NSData *profileData = [NSData dataWithContentsOfFile:linearGrayProfilePath options:0 error:&error];
			
			if (profileData == nil) {
				NSLog(@"%s(): failed to load Linear Grayscale Profile.icc!", __FUNCTION__);
				return NULL;
			}
			return CGColorSpaceCreateWithICCProfile((CFDataRef)profileData);
		}
			
		case TKColorSpaceLinearRGB :
			return CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
			
		default:
			return NULL;
	}
	
}



typedef struct MDCGImageAlphaInfo {
	CGImageAlphaInfo	alphaInfo;
	NSString			*description;
} MDCGImageAlphaInfo;

static const MDCGImageAlphaInfo MDCGImageAlphaInfoTable[] = {
	{kCGImageAlphaNone, @"kCGImageAlphaNone" },
	{kCGImageAlphaPremultipliedLast, @"kCGImageAlphaPremultipliedLast" },
	{kCGImageAlphaPremultipliedFirst, @"kCGImageAlphaPremultipliedFirst" },
	{kCGImageAlphaLast, @"kCGImageAlphaLast" },
	{kCGImageAlphaFirst, @"kCGImageAlphaFirst" },
	{kCGImageAlphaNoneSkipLast, @"kCGImageAlphaNoneSkipLast" },
	{kCGImageAlphaNoneSkipFirst, @"kCGImageAlphaNoneSkipFirst" },
	{kCGImageAlphaOnly, @"kCGImageAlphaOnly" },
};



NSString *TKStringFromCGBitmapInfo(CGBitmapInfo bitmapInfo) {
	CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
	
	NSString *description = MDCGImageAlphaInfoTable[alphaInfo].description;
	
	if (bitmapInfo & kCGBitmapFloatComponents) {
		description = [description stringByAppendingString:@" | kCGBitmapFloatComponents"];
	}
	
//	if ((bitmapInfo & kCGBitmapByteOrderMask) == kCGBitmapByteOrderDefault) description = [description stringByAppendingString:@" | kCGBitmapByteOrderDefault"];
	if ((bitmapInfo & kCGBitmapByteOrderMask) == kCGBitmapByteOrder16Little) description = [description stringByAppendingString:@" | kCGBitmapByteOrder16Little"];
	if ((bitmapInfo & kCGBitmapByteOrderMask) == kCGBitmapByteOrder32Little) description = [description stringByAppendingString:@" | kCGBitmapByteOrder32Little"];
	if ((bitmapInfo & kCGBitmapByteOrderMask) == kCGBitmapByteOrder16Big) description = [description stringByAppendingString:@" | kCGBitmapByteOrder16Big"];
	if ((bitmapInfo & kCGBitmapByteOrderMask) == kCGBitmapByteOrder32Big) description = [description stringByAppendingString:@" | kCGBitmapByteOrder32Big"];
	
	return description;
}


NSString *TKLocalizedStringFromImageSourceStatus(CGImageSourceStatus status) {
	switch (status) {

		case kCGImageStatusUnexpectedEOF : return NSLocalizedString(@"The end of the file was unexpectedly encountered.", @"");
		case kCGImageStatusInvalidData : return NSLocalizedString(@"The image data is not in the proper format.", @"");
		case kCGImageStatusUnknownType : return NSLocalizedString(@"The contents of the image are of an unknown type.", @"");
			
		default:
			return NSLocalizedString(@"An unknown error occurred.", @"");
	}
}


