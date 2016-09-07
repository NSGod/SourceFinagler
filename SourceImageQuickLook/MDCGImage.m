//
//  MDCGImage.m
//  Source Finagler
//
//  Created by Mark Douma on 9/25/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#include "MDCGImage.h"
#import <TextureKit/TextureKit.h>

#define MD_DEBUG 1
#define MD_DEBUG_PERFORMANCE 1


NSString * const MDSourceQuickLookBundleIdentifier = @"com.markdouma.qlgenerator.SourceImage";



CGImageRef MDCGImageCreateFromURL(NSURL *URL, NSString *contentTypeUTI, NSError **outError) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if (![contentTypeUTI isEqualToString:TKVTFType] &&
		![contentTypeUTI isEqualToString:TKDDSType] &&
		![contentTypeUTI isEqualToString:TKSFTextureImageType]) {
		
		NSLog(@"%@; %s(): contentTypeUTI != VTF or DDS or SFTI; (contentTypeUTI == \"%@\")", MDSourceQuickLookBundleIdentifier, __FUNCTION__, contentTypeUTI);
		[pool release];
		return NULL;
	}
	
#if MD_DEBUG
	NSLog(@"%@; %s(): file == \"%@\")", MDSourceQuickLookBundleIdentifier, __FUNCTION__, URL.path);
#endif
	
	NSData *imageData = [[NSData alloc] initWithContentsOfURL:URL];
	
	if (imageData == nil || [imageData length] < sizeof(OSType)) {
		NSLog(@"%@; %s(): data%@ for \"%@\")", MDSourceQuickLookBundleIdentifier, __FUNCTION__, (imageData == nil ? @" == nil" : @".length < sizeof(OSType)"), URL.path);
		[imageData release];
		[pool release];
		return NULL;
	}
	
	OSType magic = 0;
	[imageData getBytes:&magic length:sizeof(magic)];
	magic = NSSwapBigIntToHost(magic);
	
	if (magic == TKHTMLErrorMagic) {
		NSLog(@"%@; %s(): file at \"%@\" appears to be an ERROR 404 HTML file rather than a valid VTF", MDSourceQuickLookBundleIdentifier, __FUNCTION__, URL.path);
		[imageData release];
		[pool release];
		return NULL;
	}
	
#if MD_DEBUG_PERFORMANCE
	NSDate *date = [NSDate date];
#endif
	
	CGImageRef imageRef = NULL;
	
	if ([contentTypeUTI isEqualToString:TKVTFType]) {
		
		imageRef = CGImageRetain([[TKVTFImageRep imageRepWithData:imageData error:outError] CGImage]);
		
	} else if ([contentTypeUTI isEqualToString:TKDDSType]) {
		
		imageRef = CGImageRetain([[TKDDSImageRep imageRepWithData:imageData error:outError] CGImage]);
		
	} else if ([contentTypeUTI isEqualToString:TKSFTextureImageType]) {
		
		TKImage *tkImage = [[TKImage alloc] initWithData:imageData firstRepresentationOnly:NO error:outError];
		
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
			
			imageRef = CGImageRetain([tkImageRep CGImage]);
			
			[tkImage release];
		}
		
	}
	[imageData release];
	
#if MD_DEBUG_PERFORMANCE
	NSTimeInterval timeInterval = ABS([date timeIntervalSinceNow]);
	NSLog(@"%@; %s(): elapsed time to gather image == %0.7f sec (%0.4f ms)", MDSourceQuickLookBundleIdentifier, __FUNCTION__, timeInterval, timeInterval * 1000.0);
#endif
	
	/* Since we've created our own local autorelease pool inside of which an autoreleased NSError may have been created, we need to make sure that NSError persists outside of our local pool. To do so, we first retain it, then destroy our local pool, then autorelease it again. This will add it to our calling function/app's autorelease pool so that it's both valid and not leaked.  */
	
	if (outError) [*outError retain];
	
	[pool release];
	
	if (outError) [*outError autorelease];
	
	return imageRef;
}





