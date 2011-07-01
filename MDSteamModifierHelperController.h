//
//  MDSteamModifierHelperController.h
//  Source Finagler
//
//  Created by Mark Douma on 12/21/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDController.h"

@class VSSteamManager;

@interface MDSteamModifierHelperController : MDController {
	IBOutlet NSArrayController	*modifiedFilesController;
	IBOutlet NSTableView		*tableView;
	
	NSMutableArray				*modifiedFiles;
	
	
	VSSteamManager				*steamManager;
}

@end
