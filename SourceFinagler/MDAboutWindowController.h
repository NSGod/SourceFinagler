//
//  MDAboutWindowController.h
//  Source Finagler
//
//  Created by Mark Douma on 6/28/2005.
//  Copyright © 2005 Mark Douma. All rights reserved.
//


#import <Cocoa/Cocoa.h>


@interface MDAboutWindowController : NSWindowController {
	IBOutlet NSTextField	*nameField;
	IBOutlet NSTextField	*versionField;
	IBOutlet NSTextField	*copyrightField;
	
}

- (IBAction)showAcknowledgements:(id)sender;

@end
