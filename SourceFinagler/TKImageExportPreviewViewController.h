//
//  TKImageExportPreviewViewController.h
//  Source Finagler
//
//  Created by Mark Douma on 12/13/2010.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class TKImageView;
@class TKImageExportPreset;
@class TKImageExportController;
@class TKImageExportTextField;



@interface TKImageExportPreviewViewController : NSViewController {
	IBOutlet TKImageView				*imageView;
	IBOutlet NSProgressIndicator		*progressIndicator;
	IBOutlet TKImageExportTextField		*imageFileSizeField;
	
	// representedObject is a TKImageExportPreview
}

+ (id)previewViewControllerWithExportController:(TKImageExportController *)controller preset:(TKImageExportPreset *)preset tag:(NSInteger)tag;
- (id)initWithExportController:(TKImageExportController *)controller preset:(TKImageExportPreset *)preset tag:(NSInteger)tag;


@property (nonatomic, assign) IBOutlet TKImageView *imageView;

@end


