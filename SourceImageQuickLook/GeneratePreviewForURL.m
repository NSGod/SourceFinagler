#include <ApplicationServices/ApplicationServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>
#import <TextureKit/TextureKit.h>
#import "MDCGImage.h"


/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */


#define MD_DEBUG 1


OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef URL, CFStringRef contentTypeUTI, CFDictionaryRef options) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
#if MD_DEBUG
	NSLog(@"%@; %s(): file == \"%@\")", MDSourceQuickLookBundleIdentifier, __FUNCTION__, [(NSURL *)URL path]);
#endif
	
	if (![(NSString *)contentTypeUTI isEqualToString:TKVTFType] &&
		![(NSString *)contentTypeUTI isEqualToString:TKDDSType] &&
		![(NSString *)contentTypeUTI isEqualToString:TKSFTextureImageType]) {
		NSLog(@"%@; %s(): contentTypeUTI != VTF or DDS or SFTI; (contentTypeUTI == \"%@\"), file == \"%@\"", MDSourceQuickLookBundleIdentifier, __FUNCTION__, (NSString *)contentTypeUTI, [(NSURL *)URL path]);
		[pool release];
		return noErr;
	}
	
	NSError *outError = nil;
	
	TKImage *image = [[TKImage alloc] initWithContentsOfURL:(NSURL *)URL error:&outError];
	
	if (image == nil) {
		NSLog(@"%@; TKImage returned nil for file \"%@\". error == %@", MDSourceQuickLookBundleIdentifier, [(NSURL *)URL path], outError);
		[pool release];
		return noErr;
	}
	
	NSSize imageSize = (image.isEnvironmentMap ? image.environmentMapSize : image.size);
	
	CGContextRef cgContext = QLPreviewRequestCreateContext(preview, NSSizeToCGSize(imageSize), true, NULL);
	
	if (cgContext == NULL) {
		NSLog(@"%@; QLPreviewRequestCreateContext() returned NULL for file \"%@\".", MDSourceQuickLookBundleIdentifier, [(NSURL *)URL path]);
		[image release];
		[pool release];
		return noErr;
	}
	
	NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithGraphicsPort:(void *)cgContext flipped:NO];
	
	if (context == nil) {
		NSLog(@"%@; failed to create NSGraphicsContext for file \"%@\".", MDSourceQuickLookBundleIdentifier, [(NSURL *)URL path]);
		CGContextRelease(cgContext);
		[image release];
		[pool release];
		return noErr;
	}
	
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:context];
	
	// draw image
	
	[context saveGraphicsState];
	
	if (image.isEnvironmentMap) {
		[image drawEnvironmentMapInRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height)];
		
	} else {
		[image drawInRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		
	}
	
	[context restoreGraphicsState];
	
	[NSGraphicsContext restoreGraphicsState];
	
	QLPreviewRequestFlushContext(preview, cgContext);
	CGContextRelease(cgContext);
	[image release];
	
	[pool release];
	return noErr;
}


void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview) {
    // implement only if supported
}


