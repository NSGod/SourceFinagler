//
//  MDPrefsController.h
//  Source Finagler
//
//  Created by Mark Douma on 9/12/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class MDPrefsGeneralController;



@interface MDPrefsController : NSWindowController <NSToolbarDelegate> {
	MDPrefsGeneralController	*generalController;
	
}

- (IBAction)switchToView:(id)sender;

@end


/*************		Preferences		*************/
//extern NSString * const MDPrefsCurrentViewKey;

// various pref views...  the values need to be the "itemIdentifier" strings of the toolbarItems

//extern NSString * const MDPrefsGeneralViewKey;
//
//extern NSString * const MDPrefsViewDidChangeNotification;
//extern NSString * const MDPrefsWindowWillCloseNotification;




