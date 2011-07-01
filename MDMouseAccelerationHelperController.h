//
//  MDMouseAccelerationHelperController.h
//  Source Finagler
//
//  Created by Mark Douma on 8/21/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

//#if TARGET_CPU_X86 || TARGET_CPU_X86_64

#import "MDController.h"

@class VSSteamManager;

@interface MDMouseAccelerationHelperController : MDController {
	IBOutlet NSOutlineView		*outlineView;
	IBOutlet NSTreeController	*gamesController;
	
	IBOutlet NSButton			*helpButton;
	
	NSMutableArray				*games;
	
	VSSteamManager				*steamManager;

}

- (IBAction)revealInFinder:(id)sender;
- (IBAction)refresh:(id)sender;
- (IBAction)helpApps:(id)sender;
- (IBAction)restoreToDefault:(id)sender;
- (IBAction)launchGame:(id)sender;

@end
