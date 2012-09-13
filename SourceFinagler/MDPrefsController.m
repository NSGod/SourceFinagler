//
//  MDPrefsController.m
//  Source Finagler
//
//  Created by Mark Douma on 9/12/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDPrefsController.h"
#import "MDPrefsGeneralController.h"
#import "MDAppKitAdditions.h"

enum {
	MDPrefsGeneralView	= 1
};



@implementation MDPrefsController

- (id)init {
	if ((self = [super initWithWindowNibName:@"MDPrefs"])) {

	} else {
		[NSBundle runFailedNibLoadAlert:@"MDPrefs"];
	}
	return self;
}

- (void)dealloc {
	[generalController release];
	[super dealloc];
}


//- (void)awakeFromNib {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//	
//}

- (void)windowDidLoad {
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	if (generalController == nil) {
		generalController = [[MDPrefsGeneralController alloc] init];
		if (![NSBundle loadNibNamed:@"MDPrefsGeneral" owner:generalController]) {
			NSLog(@"[%@ %@] failed to load MDPrefsGeneral.nib!!!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		}
	}
	[[[self window] toolbar] setSelectedItemIdentifier:@"general"];
	[[self window] switchView:[generalController view] newTitle:NSLocalizedString(@"General", @"")];
	
}


- (IBAction)showWindow:(id)sender {
	if ([[self window] isVisible] == NO) [[self window] center];
	[super showWindow:sender];
}


- (IBAction)switchToView:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	
	
	
	
}






@end







//NSString * const MDPrefsCurrentViewKey = @"MDPrefsCurrentView";

// various pref views...  the values need to be the "itemIdentifier" strings of the toolbarItems

//NSString * const MDPrefsGeneralViewKey = @"generalPrefs";
//
//NSString * const MDPrefsViewDidChangeNotification = @"MDPrefsViewDidChange";
//NSString * const MDPrefsWindowWillCloseNotification = @"MDPrefsWindowWillClose";

