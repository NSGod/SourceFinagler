//
//  MDSteamAppsRelocatorController.h
//  Source Finagler
//
//  Created by Mark Douma on 6/13/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

//#if TARGET_CPU_X86 || TARGET_CPU_X86_64

#import "MDController.h"

@class VSSteamManager;

@interface MDSteamAppsRelocatorController : MDController <NSOpenSavePanelDelegate> {
	IBOutlet NSTextField		*statusField;
	IBOutlet NSTextField		*newPathField;
	
	NSURL						*currentURL;
	NSString					*proposedNewPath;
	
	VSSteamManager				*steamManager;
	
	BOOL						canCreate;
	
	BOOL						steamIsRunning;
}

@property (assign) BOOL canCreate;
@property (retain) NSURL *currentURL;
@property (retain) NSString *proposedNewPath;
@property (assign) BOOL steamIsRunning;

- (IBAction)browse:(id)sender;
- (IBAction)createSteamAppsShortcut:(id)sender;
- (IBAction)revealInFinder:(id)sender;
- (IBAction)quitSteam:(id)sender;

@end

//#endif
