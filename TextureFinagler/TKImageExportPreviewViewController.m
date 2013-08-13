//
//  TKImageExportPreviewViewController.m
//  Texture Kit
//
//  Created by Mark Douma on 12/13/2010.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//

#import "TKImageExportPreviewViewController.h"
#import "TKImageView.h"
#import <TextureKit/TextureKit.h>
#import "TKImageExportController.h"
#import "TKImageExportPreset.h"
#import "TKImageExportPreview.h"
#import "TKImageDocument.h"
#import "TKAppKitAdditions.h"


#define TK_DEBUG 1


@implementation TKImageExportPreviewViewController

@synthesize imageView;


+ (id)previewViewControllerWithExportController:(TKImageExportController *)controller preset:(TKImageExportPreset *)preset tag:(NSInteger)tag {
	return [[[[self class] alloc] initWithExportController:controller preset:preset tag:tag] autorelease];
}

- (id)initWithExportController:(TKImageExportController *)controller preset:(TKImageExportPreset *)preset tag:(NSInteger)tag {
	if (controller == nil ||preset == nil) return nil;
	
	if ((self = [super initWithNibName:@"TKImageExportPreviewView" bundle:nil])) {
		TKImageExportPreview *preview = [[[TKImageExportPreview alloc] initWithController:controller image:[[controller document] image] preset:preset tag:tag] autorelease];
		[self setRepresentedObject:preview];
		[(TKImageExportPreviewView *)[self view] setDelegate:controller];
		[imageView setDelegate:controller];
		
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


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithFormat:@"%@, ", [super description]];
	[description appendFormat:@"representedObject == %@", [self representedObject]];
	return description;
}

@end

