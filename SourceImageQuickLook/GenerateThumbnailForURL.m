#include <ApplicationServices/ApplicationServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>
#import "MDCGImage.h"


/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */
	
	
#define MD_DEBUG 0



OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef URL, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxImageSize) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSError *outError = nil;
	
	CGImageRef imageRef = MDCGImageCreateFromURL((NSURL *)URL, (NSString *)contentTypeUTI, &outError);
	
	if (imageRef == NULL) {
		NSLog(@"%@; MDCGImageCreateFromURL() returned NULL for file \"%@\". error == %@", MDSourceQuickLookBundleIdentifier, [(NSURL *)URL path], outError);
		[pool release];
		return noErr;
	}
	
	NSSize imageSize = NSMakeSize(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
	
	NSSize contextSize = NSSizeFromCGSize(maxImageSize);
	
	if (imageSize.width >= imageSize.height) {
		contextSize.height *= (imageSize.width / imageSize.height);
	} else {
		contextSize.width *= (imageSize.width / imageSize.height);
	}
	
#if MD_DEBUG
	NSLog(@"%@; %s(): \"%@\", maxImageSize == %@, QLThumbnailRequestGetMaximumSize() == %@, contextSize == %@", MDSourceQuickLookBundleIdentifier, __FUNCTION__, [(NSURL *)URL path], NSStringFromSize(NSSizeFromCGSize(maxImageSize)), NSStringFromSize(NSSizeFromCGSize(QLThumbnailRequestGetMaximumSize(thumbnail))), NSStringFromSize(contextSize));
#endif
	
	CGContextRef qlContext = QLThumbnailRequestCreateContext(thumbnail, NSSizeToCGSize(contextSize), true, NULL);
	if (qlContext == NULL) {
		NSLog(@"%@; QLThumbnailRequestCreateContext() returned NULL for file \"%@\".", MDSourceQuickLookBundleIdentifier, [(NSURL *)URL path]);
		CGImageRelease(imageRef);
		[pool release];
		return noErr;
	}
	
	CGContextSaveGState(qlContext);
	CGContextDrawImage(qlContext, CGRectMake(0.0, 0.0, contextSize.width, contextSize.height), imageRef);
	CGContextRestoreGState(qlContext);
	QLThumbnailRequestFlushContext(thumbnail, qlContext);
	CGContextRelease(qlContext);
	
	CGImageRelease(imageRef);
	
	[pool release];
	return noErr;
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail) {
	// implement only if supported
}

