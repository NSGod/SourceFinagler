//
//  TKImageExportPreviewViewController.m
//  Texture Kit
//
//  Created by Mark Douma on 12/13/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import "TKImageExportPreviewViewController.h"
#import "TKImageView.h"
#import "TKImageExportPreview.h"
#import "MDAppKitAdditions.h"

#define TK_DEBUG 1


@implementation TKImageExportPreviewViewController

@synthesize imageView;

- (id)init {
	if ((self = [super initWithNibName:@"TKImageExportPreviewView" bundle:nil])) {
		
	} else {
		[NSBundle runFailedNibLoadAlert:@"TKImageExportPreviewView"];
	}
	return self;
}


- (void)dealloc {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super dealloc];	
}


- (void)awakeFromNib {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[progressIndicator setUsesThreadedAnimation:YES];
	[imageView setImage:NULL imageProperties:nil];
}


- (void)setRepresentedObject:(id)representedObject {
#if TK_DEBUG
	NSLog(@"[%@ %@] representedObject == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), representedObject);
#endif
	[super setRepresentedObject:representedObject];
	
	if ([(TKImageExportPreview *)representedObject imageRep] == nil) {
		[progressIndicator startAnimation:self];
	}
}



@end
