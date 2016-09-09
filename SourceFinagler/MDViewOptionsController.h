//
//  MDViewOptionsController.h
//  Source Finagler
//
//  Created by Mark Douma on 1/29/2008.
//  Copyright © 2008 Mark Douma. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "MDHLDocument.h"


@interface MDViewOptionsController : NSWindowController {

	IBOutlet NSBox				*contentBox;
	
	IBOutlet NSView				*noViewOptionsView;
	IBOutlet NSTextField		*noViewOptionsField;
	
	IBOutlet NSView				*listViewOptionsView;
	
	IBOutlet NSView				*browserViewOptionsView;
	
	MDHLDocumentViewMode		viewMode;
	
	
	BOOL						appIsTerminating;
	
}

- (IBAction)changeListViewIconSize:(id)sender;

@end

