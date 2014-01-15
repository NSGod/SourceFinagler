//
//  VSSourceAddonController.h
//  Source Finagler
//
//  Created by Mark Douma on 10/8/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SteamKit/SteamKit.h>



@interface VSSourceAddonController : NSObject <NSApplicationDelegate, NSTableViewDelegate, VSSteamManagerDelegate> {
	IBOutlet NSWindow				*window;
	
	IBOutlet NSTextField			*resultsField;
	
	IBOutlet NSSplitView			*splitView;
	
	IBOutlet NSView					*installedView;
	IBOutlet NSTableView			*installedTableView;
	
	IBOutlet NSView					*alreadyInstalledView;
	IBOutlet NSTableView			*alreadyInstalledTableView;
	
	IBOutlet NSView					*problemView;
	IBOutlet NSTableView			*problemTableView;
	
	
	NSMutableArray					*addons;
	
	NSMutableArray					*installedAddons;
	NSMutableArray					*alreadyInstalledAddons;
	NSMutableArray					*problemAddons;
	
	
	IBOutlet NSArrayController		*installedAddonsController;
	IBOutlet NSArrayController		*alreadyInstalledAddonsController;
	IBOutlet NSArrayController		*problemAddonsController;
	
	
	IBOutlet NSWindow				*prefsWindow;
	
	IBOutlet NSWindow				*copyProgressWindow;
	IBOutlet NSProgressIndicator	*progressIndicator;

}

@property (retain) NSMutableArray *addons;
@property (retain) NSMutableArray *installedAddons;
@property (retain) NSMutableArray *alreadyInstalledAddons;
@property (retain) NSMutableArray *problemAddons;

@property (nonatomic, retain) NSArray *installedAddonsSortDescriptors;
@property (nonatomic, retain) NSArray *alreadyInstalledAddonsSortDescriptors;
@property (nonatomic, retain) NSArray *problemAddonsSortDescriptors;



- (IBAction)showPrefsWindow:(id)sender;

- (IBAction)ok:(id)sender;


@end


