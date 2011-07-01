//
//  MDInspectorController.h
//  Source Finagler
//
//  Created by Mark Douma on 1/28/2008.
//  Copyright © 2008 Mark Douma. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class MDPreviewViewController;

@interface MDInspectorController : NSWindowController {
	IBOutlet NSImageView				*iconImageView;
	IBOutlet NSTextField				*nameField;
	IBOutlet NSTextField				*headerSizeField;
	IBOutlet NSTextField				*dateModifiedField;
	
	IBOutlet NSTextField				*kindField;
	IBOutlet NSTextField				*sizeField;
	IBOutlet NSTextField				*whereField;
	
	IBOutlet MDPreviewViewController	*previewViewController;
	
}

@end

