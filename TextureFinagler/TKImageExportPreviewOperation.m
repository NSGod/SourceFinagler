//
//  TKImageExportPreviewOperation.m
//  Source Finagler
//
//  Created by Mark Douma on 7/17/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import "TKImageExportPreviewOperation.h"
#import "TKImageExportPreview.h"
#import "TKImageExportPreset.h"
#import <TextureKit/TextureKit.h>


#define TK_DEBUG 1




NSString * const TKImageExportPreviewOperationDidCompleteNotification	= @"TKImageExportPreviewOperationDidComplete";
NSString * const TKImageExportPreviewKey	= @"TKImageExportPreview";





@implementation TKImageExportPreviewOperation

@synthesize imageExportPreview;


- (id)initWithImageExportPreview:(TKImageExportPreview *)anImageExportPreview {
	if (anImageExportPreview == nil) return nil;
	if ((self = [super init])) {
		imageExportPreview = [anImageExportPreview retain];
	}
	return self;
}


- (void)dealloc {
	[imageExportPreview release];
	[super dealloc];
}


- (void)main {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	TKImageExportPreset *preset = [imageExportPreview preset];
	
	NSString *fileType = [[imageExportPreview preset] fileType];
	
	if ([fileType isEqualToString:[TKDDSFileType uppercaseString]]) {
		
		NSData *previewData = [TKDDSImageRep DDSRepresentationOfImageRepsInArray:[[imageExportPreview image] representations] usingPreset:[imageExportPreview preset]];
		TKDDSImageRep *imageRep = [[TKDDSImageRep alloc] initWithData:previewData];
		[imageExportPreview setImageRep:imageRep];
		[imageRep release];
		
		[imageExportPreview setImageFileSize:[previewData length]];
		
	} else if ([fileType isEqualToString:[TKVTFFileType uppercaseString]]) {
		
		NSData *previewData = [TKVTFImageRep VTFRepresentationOfImageRepsInArray:[[imageExportPreview image] representations] usingPreset:[imageExportPreview preset]];
		TKVTFImageRep *imageRep = [[TKVTFImageRep alloc] initWithData:previewData];
		[imageExportPreview setImageRep:imageRep];
		[imageRep release];
		[imageExportPreview setImageFileSize:[previewData length]];
		
	} else if ([preset isEqualToPreset:[TKImageExportPreset originalImagePreset]]) {
		NSArray *originalImageReps = [[imageExportPreview image] representations];
		if ([originalImageReps count]) {
			TKImageRep *imageRep = [originalImageReps objectAtIndex:0];
			NSData *imageRepData = [imageRep data];
			[imageExportPreview setImageRep:imageRep];
			[imageExportPreview setImageFileSize:[imageRepData length]];
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:TKImageExportPreviewOperationDidCompleteNotification
														object:[imageExportPreview controller]
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:imageExportPreview,TKImageExportPreviewKey, nil]];
	
	[pool release];
}




- (BOOL)isEqual:(id)object {
	if ([object isKindOfClass:[self class]]) {
		return ([(TKImageExportPreviewOperation *)object imageExportPreview] == imageExportPreview);
	}
	return NO;
}





@end
