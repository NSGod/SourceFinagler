#include <ApplicationServices/ApplicationServices.h>
#include <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>
#import "MDCGImage.h"
#import "TKVTFImageRep.h"
#import "TKDDSImageRep.h"


/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */
	
	
#define MD_DEBUG 0
	

	
OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxImageSize) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if (![(NSString *)contentTypeUTI isEqualToString:TKVTFType] &&
		![(NSString *)contentTypeUTI isEqualToString:TKDDSType]) {
		NSLog(@"SourceImage.qlgenerator; GenerateThumbnailForURL(): contentTypeUTI != VTF or DDS; (contentTypeUTI == %@)", contentTypeUTI);
		[pool release];
		return noErr;
	}
	
#if MD_DEBUG
	NSLog(@"GenerateThumbnailForURL(): %@", [(NSURL *)url path]);
#endif
	
	NSData *imageData = [[NSData alloc] initWithContentsOfURL:(NSURL *)url];
	
	if (imageData == nil || [imageData length] < sizeof(OSType)) {
		NSLog(@"GenerateThumbnailForURL(): data %@ for file == %@", (imageData == nil ? @"== nil" : @"length < 4"), [(NSURL *)url path]);
		[imageData release];
		[pool release];
		return noErr;
	}
	
	OSType magic = 0;
	[imageData getBytes:&magic length:sizeof(magic)];
	magic = NSSwapBigIntToHost(magic);
	
	if (magic == TKHTMLErrorMagic) {
		NSLog(@"GenerateThumbnailForURL(): file at path \"%@\" appears to be an ERROR 404 HTML file rather than a valid VTF", [(NSURL *)url path]);
		[imageData release];
		[pool release];
		return noErr;
	}
	
	CGImageRef imageRef = NULL;
	
	if ([(NSString *)contentTypeUTI isEqualToString:TKVTFType]) {
		imageRef = [[TKVTFImageRep imageRepWithData:imageData] CGImage];
	} else if ([(NSString *)contentTypeUTI isEqualToString:TKDDSType]) {
		imageRef = [[TKDDSImageRep imageRepWithData:imageData] CGImage];
	}
	
	if (imageRef == NULL) {
		NSLog(@"SourceImage.qlgenerator; GenerateThumbnailForURL(): MDCGImageCreateWithData() returned NULL for file %@", [(NSURL *)url path]);
		[imageData release];
		[pool release];
		return noErr;
	}
	
#if MD_DEBUG
	NSLog(@"GenerateThumbnailForURL(): created imageRef");
#endif
	
	CGSize theMaxImageSize = QLThumbnailRequestGetMaximumSize(thumbnail);
	
	if (CGImageGetWidth(imageRef) > theMaxImageSize.width || CGImageGetHeight(imageRef) > theMaxImageSize.height) {
		CGSize newSize = theMaxImageSize;
		if (newSize.width < newSize.height) {
			newSize.height = newSize.width;
		} else {
			newSize.width = newSize.height;
		}
		
		newSize.height = newSize.width * (CGFloat)CGImageGetHeight(imageRef)/(CGFloat)CGImageGetWidth(imageRef);
		
#if MD_DEBUG
	NSLog(@"GenerateThumbnailForURL(): going to call CGCreateCopyWithSize()");
#endif
		CGImageRef newImage = MDCGImageCreateCopyWithSize(imageRef, newSize);
		QLThumbnailRequestSetImage(thumbnail, newImage, NULL);
		CGImageRelease(newImage);
	} else {
		QLThumbnailRequestSetImage(thumbnail, imageRef, NULL);
		
	}
	
#if MD_DEBUG
	NSLog(@"GenerateThumbnailForURL(): set thumbnail image");
#endif
	
	[imageData release];
	
	[pool release];
	return noErr;
}
	
void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail) {
//	NSLog(@"SourceImage.qlgenerator; CancelThumbnailGeneration()");

	// implement only if supported
}

