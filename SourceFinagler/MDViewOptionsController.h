//
//  MDViewOptionsController.h
//  Source Finagler
//
//  Created by Mark Douma on 1/29/2008.
//  Copyright © 2008 Mark Douma. All rights reserved.
//



#import <Cocoa/Cocoa.h>

extern NSString * const MDShouldShowViewOptionsKey;	// BOOL/NSNumber
extern NSString * const MDShouldShowViewOptionsDidChangeNotification;


@interface MDViewOptionsController : NSWindowController {

	IBOutlet NSBox				*contentBox;
	
	IBOutlet NSView				*noViewOptionsView;
	IBOutlet NSTextField		*noViewOptionsField;
	
	IBOutlet NSView				*listViewOptionsView;
	
	IBOutlet NSView				*browserViewOptionsView;
	
	NSInteger					documentViewMode;
}

- (IBAction)changeListViewIconSize:(id)sender;

@end

