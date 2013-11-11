//
//  TKImageExportPreviewViewController.h
//  Texture Kit
//
//  Created by Mark Douma on 12/13/2010.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class TKImageView, TKImageExportPreset, TKImageExportController;


@interface TKImageExportPreviewViewController : NSViewController {
	IBOutlet TKImageView			*imageView;
	IBOutlet NSProgressIndicator	*progressIndicator;
	
	// representedObject is a TKImageExportPreview
}

+ (id)previewViewControllerWithExportController:(TKImageExportController *)controller preset:(TKImageExportPreset *)preset tag:(NSInteger)tag;
- (id)initWithExportController:(TKImageExportController *)controller preset:(TKImageExportPreset *)preset tag:(NSInteger)tag;


@property (assign) IBOutlet TKImageView *imageView;

@end


