#include <ApplicationServices/ApplicationServices.h>
#include <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>
#import "TKVTFImageRep.h"
#import "TKDDSImageRep.h"


/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */
#ifdef __cplusplus
extern "C" {
#endif
	
	
#define MD_DEBUG 0
	
	
OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if (![(NSString *)contentTypeUTI isEqualToString:TKVTFType] &&
		![(NSString *)contentTypeUTI isEqualToString:TKDDSType]) {
		NSLog(@"SourceImage.qlgenerator; GeneratePreviewForURL(): contentTypeUTI != VTF or DDS; (contentTypeUTI == %@)", contentTypeUTI);
		[pool release];
		return noErr;
	}
	
#if MD_DEBUG
	NSLog(@"GeneratePreviewForURL(): %@", [(NSURL *)url path]);
#endif
	
	NSData *fileData = [NSData dataWithContentsOfURL:(NSURL *)url];
	if (fileData == nil) {
		NSLog(@"SourceImage.qlgenerator; GeneratePreviewForURL(): fileData == nil for url == %@", url);
		[pool release];
		return noErr;
	}
	CGImageRef imageRef = NULL;
	
	if ([(NSString *)contentTypeUTI isEqualToString:TKVTFType]) {
		imageRef = [[TKVTFImageRep imageRepWithData:fileData] CGImage];
	} else if ([(NSString *)contentTypeUTI isEqualToString:TKDDSType]) {
		imageRef = [[TKDDSImageRep imageRepWithData:fileData] CGImage];
	}
	
	if (imageRef == NULL) {
		NSLog(@"SourceImage.qlgenerator; GeneratePreviewForURL(): MDCGImageCreateWithContentsOfFile() returned NULL for file %@", [(NSURL *)url path]);
		[pool release];
		return noErr;
	}
	
#if MD_DEBUG
	NSLog(@"GeneratePreviewForURL(): created imageRef");
#endif
	
	CGContextRef cgContext = QLPreviewRequestCreateContext(preview, CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef)), true, NULL);
	if (cgContext) {
		CGContextSaveGState(cgContext);
		CGContextDrawImage(cgContext, CGRectMake(0.0, 0.0, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef)), imageRef);
		CGContextRestoreGState(cgContext);
		QLPreviewRequestFlushContext(preview, cgContext);
		CGContextRelease(cgContext);
	}
	
#if MD_DEBUG
	NSLog(@"GeneratePreviewForURL(): drew preview request");
#endif
	[pool release];
	return noErr;
	
}
	
void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview) {
//	NSLog(@"SourceImage.qlgenerator; CancelPreviewGeneration()");
	
    // implement only if supported
}


#ifdef __cplusplus
}
#endif

