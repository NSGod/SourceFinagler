#include <ApplicationServices/ApplicationServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>
#import <TextureKit/TextureKit.h>


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
		![(NSString *)contentTypeUTI isEqualToString:TKDDSType] &&
		![(NSString *)contentTypeUTI isEqualToString:TKSFTextureImageType]) {
		
		
		NSLog(@"SourceImage.qlgenerator; GeneratePreviewForURL(): contentTypeUTI != VTF or DDS or SFTI; (contentTypeUTI == %@)", contentTypeUTI);
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
		
	} else if ([(NSString *)contentTypeUTI isEqualToString:TKSFTextureImageType]) {
		
		TKImage *tkImage = [[TKImage alloc] initWithData:fileData firstRepresentationOnly:NO];
		
		if (tkImage) {
			
			TKImageRep *tkImageRep = nil;
			
			if ([tkImage sliceCount]) {
				
				
			} else if ([tkImage faceCount] && [tkImage frameCount]) {
				
				NSArray *aTKImageReps = [tkImage representationsForFaceIndexes:[tkImage firstFaceIndexSet]
																  frameIndexes:[tkImage firstFrameIndexSet]
																 mipmapIndexes:[tkImage firstMipmapIndexSet]];
				
				if ([aTKImageReps count]) tkImageRep = [aTKImageReps objectAtIndex:0];
				
			} else if ([tkImage faceCount]) {
				
				NSArray *aTKImageReps = [tkImage representationsForFaceIndexes:[tkImage firstFaceIndexSet]
																 mipmapIndexes:[tkImage firstMipmapIndexSet]];
				
				if ([aTKImageReps count]) tkImageRep = [aTKImageReps objectAtIndex:0];
				
				
			} else if ([tkImage frameCount]) {
				
				NSArray *aTKImageReps = [tkImage representationsForFrameIndexes:[tkImage firstFrameIndexSet]
																  mipmapIndexes:[tkImage firstMipmapIndexSet]];
				
				if ([aTKImageReps count]) tkImageRep = [aTKImageReps objectAtIndex:0];
				
			} else {
				if ([tkImage mipmapCount]) {
					tkImageRep = [tkImage representationForMipmapIndex:0];
				}
			}
			
			imageRef = [tkImageRep CGImage];
			
			[tkImage release];
		}
		
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

