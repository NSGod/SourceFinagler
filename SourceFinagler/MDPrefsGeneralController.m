//
//  TKPrefsGeneralController.m
//  Source Finagler
//
//  Created by Mark Douma on 9/12/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "TKPrefsGeneralController.h"
#import "TKAppController.h"
#import "TKImageDocument.h"


@implementation TKPrefsGeneralController


- (NSString *)title {
	return NSLocalizedString(@"General", @"");
}


- (void)awakeFromNib {
	
	resizable = NO;
	
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:TKLaunchTimeActionKey] unsignedIntegerValue] & TKLaunchTimeActionOpenMainWindow) {
		[openMainWindowCheckbox setState:NSOnState];
	}
	
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:TKLaunchTimeActionKey] unsignedIntegerValue] & TKLaunchTimeActionOpenNewDocument) {
		[openDocumentCheckbox setState:NSOnState];
	}
}


- (IBAction)changeLaunchTimeOptions:(id)sender {
	
	TKLaunchTimeActionType newLaunchTimeAction = TKLaunchTimeActionNone;
	
	if ([openMainWindowCheckbox state] == NSOnState) {
		newLaunchTimeAction |= TKLaunchTimeActionOpenMainWindow;
	}
	
	if ([openDocumentCheckbox state] == NSOnState) {
		newLaunchTimeAction |= TKLaunchTimeActionOpenNewDocument;
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedInteger:newLaunchTimeAction] forKey:TKLaunchTimeActionKey];
}


- (IBAction)resetWarnings:(id)sender {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:TKImageDocumentDoNotShowWarningAgainKey];
}



@end
