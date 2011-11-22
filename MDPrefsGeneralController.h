//
//  MDPrefsGeneralController.h
//  Source Finagler
//
//  Created by Mark Douma on 9/12/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDController.h"


@interface MDPrefsGeneralController : MDController {
	IBOutlet NSButton		*openMainWindowCheckbox;
	IBOutlet NSButton		*openDocumentCheckbox;
	
}

- (IBAction)changeLaunchTimeOptions:(id)sender;
- (IBAction)resetWarnings:(id)sender;

@end
