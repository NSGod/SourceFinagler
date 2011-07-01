//
//  MDPrefsGeneralController.m
//  Source Finagler
//
//  Created by Mark Douma on 9/12/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDPrefsGeneralController.h"
#import "MDAppController.h"
#import "TKImageDocument.h"


@implementation MDPrefsGeneralController


- (void)awakeFromNib {
	
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:MDLaunchTimeActionKey] unsignedIntegerValue] & MDLaunchTimeActionOpenMainWindow) {
		[openMainWindowCheckbox setState:NSOnState];
	}
	
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:MDLaunchTimeActionKey] unsignedIntegerValue] & MDLaunchTimeActionOpenNewDocument) {
		[openDocumentCheckbox setState:NSOnState];
	}
}



- (IBAction)changeLaunchTimeOptions:(id)sender {
	
	MDLaunchTimeActionType newLaunchTimeAction = MDLaunchTimeActionNone;
	
	if ([openMainWindowCheckbox state] == NSOnState) {
		newLaunchTimeAction |= MDLaunchTimeActionOpenMainWindow;
	}
	
	if ([openDocumentCheckbox state] == NSOnState) {
		newLaunchTimeAction |= MDLaunchTimeActionOpenNewDocument;
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedInteger:newLaunchTimeAction] forKey:MDLaunchTimeActionKey];
}


- (IBAction)resetWarnings:(id)sender {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:TKImageDocumentDoNotShowWarningAgainKey];
}



@end
