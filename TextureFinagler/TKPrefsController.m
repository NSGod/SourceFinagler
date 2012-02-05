//
//  TKPrefsController.m
//  Source Finagler
//
//  Created by Mark Douma on 9/12/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "TKPrefsController.h"
#import "TKPrefsGeneralController.h"
#import "MDAppKitAdditions.h"

enum {
	MDPrefsGeneralView	= 1
};



@implementation TKPrefsController

- (id)init {
	if ((self = [super initWithWindowNibName:@"TKPrefs"])) {

	} else {
		[NSBundle runFailedNibLoadAlert:@"TKPrefs"];
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
		generalController = [[TKPrefsGeneralController alloc] init];
		if (![NSBundle loadNibNamed:@"TKPrefsGeneral" owner:generalController]) {
			NSLog(@"[%@ %@] failed to load TKPrefsGeneral.nib!!!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
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

