//
//  MDSteamModifierHelperController.m
//  Source Finagler
//
//  Created by Mark Douma on 12/21/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDSteamModifierHelperController.h"
#import "VSSteamManager.h"
#import "MDAppKitAdditions.h"

#define VS_DEBUG 1

NSString * const MDSteamModifierHelperViewSizeKey = @"MDSteamModifierHelperViewSize";


@implementation MDSteamModifierHelperController


- (id)init {
	if (self = [super init]) {

		steamManager = [[VSSteamManager defaultManager] retain];
		modifiedFiles = [[NSMutableArray alloc] init];
		resizable = YES;
	}
	return self;
}


- (void)dealloc {
	[steamManager release];
	[modifiedFiles release];
	[super dealloc];
}


- (void)awakeFromNib {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	minWinSize = [view frame].size;
	maxWinSize = NSMakeSize(16000, 16000);
	
	
	[tableView setTarget:self];
	[tableView setDoubleAction:@selector(launchGame:)];
	[tableView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
	[tableView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
	[tableView setVerticalMotionCanBeginDrag:NO];
//	[gamesController setSortDescriptors:[tableView sortDescriptors]];
	
}


- (void)appControllerDidLoadNib:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSUserDefaults *uD = [NSUserDefaults standardUserDefaults];
	if ([uD objectForKey:MDSteamModifierHelperViewSizeKey] == nil) [uD setObject:[view stringWithSavedFrame] forKey:MDSteamModifierHelperViewSizeKey];
	[view setFrameFromString:[uD objectForKey:MDSteamModifierHelperViewSizeKey]];
	[super appControllerDidLoadNib:self];
}













@end
