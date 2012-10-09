//
//  MDMouseAppHelperController.h
//  Source Finagler
//
//  Created by Mark Douma on 6/13/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

//#if TARGET_CPU_X86 || TARGET_CPU_X86_64

#import "MDController.h"
#import <SteamKit/SteamKit.h>

@class MDTableView;


enum {
	MDNoMouseSoftware	= 0,
	MDUSBOverdrive		= 1 << 1,
	MDSteerMouse		= 1 << 2,
	MDLogitech			= 1 << 3
};
typedef NSUInteger MDMouseSoftware;


@interface MDOtherAppsHelperController : MDController <NSTableViewDelegate, VSSteamManagerDelegate> {
	IBOutlet NSArrayController	*gamesController;
	IBOutlet NSButton			*helpButton;
	IBOutlet MDTableView		*tableView;
	
	IBOutlet NSView				*usbOverdriveView;
	IBOutlet NSButton			*usbOverdriveIconButton;
	
	IBOutlet NSWindow			*usbOverdriveWindow;
	
	
	NSMutableArray				*games;
	
	VSSteamManager				*steamManager;
	
	MDMouseSoftware				mouseSoftware;
	
	BOOL						enableSourceFinaglerAgent;
}


- (NSArray *)games;
- (NSUInteger)countOfGames;
- (id)objectInGamesAtIndex:(NSUInteger)theIndex;

- (IBAction)showUSBOverdriveTip:(id)sender;
- (IBAction)ok:(id)sender;


- (IBAction)helpApps:(id)sender;
- (IBAction)restoreToDefault:(id)sender;

- (IBAction)toggleHelpApps:(id)sender;

@property (assign) BOOL enableSourceFinaglerAgent;

@property (nonatomic, retain) NSArray *sortDescriptors;


- (IBAction)toggleEnableAgent:(id)sender;

- (IBAction)refresh:(id)sender;
- (IBAction)revealInFinder:(id)sender;
- (IBAction)launchGame:(id)sender;

@end

//#endif
