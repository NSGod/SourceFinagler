//
//  TKImageExportPreviewViewController.h
//  Source Finagler
//
//  Created by Mark Douma on 12/13/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TKImageView;

@interface TKImageExportPreviewViewController : NSViewController {
	IBOutlet TKImageView			*imageView;
	IBOutlet NSProgressIndicator	*progressIndicator;
	IBOutlet NSTextField			*imageFileSizeField;
}

@end
