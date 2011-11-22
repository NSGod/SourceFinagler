//
//  VSSourceAddonController.h
//  Source Finagler
//
//  Created by Mark Douma on 10/8/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VSSteamManager;


@interface VSSourceAddonController : NSObject <NSApplicationDelegate, NSTableViewDelegate, NSTableViewDataSource> {
	IBOutlet NSWindow			*window;
	
	IBOutlet NSTextField		*resultsField;
	
	IBOutlet NSBox				*box;
	
	IBOutlet NSView				*comboView;
	
	IBOutlet NSBox				*successBox;
	IBOutlet NSView				*successView;
	IBOutlet NSTableView		*successTableView;
	IBOutlet NSTableColumn		*successFileNameColumn;
	
	
	IBOutlet NSBox				*problemBox;
	IBOutlet NSView				*problemView;
	IBOutlet NSTableView		*problemTableView;
	IBOutlet NSTableColumn		*problemFileNameColumn;
	
	
	NSMutableArray				*installedAddons;
	NSMutableArray				*problemAddons;
	
	
	IBOutlet NSWindow			*prefsWindow;
	
	IBOutlet NSWindow				*copyProgressWindow;
	IBOutlet NSProgressIndicator	*progressIndicator;

	
	VSSteamManager				*steamManager;

}

- (IBAction)showPrefsWindow:(id)sender;

- (IBAction)ok:(id)sender;


@end


