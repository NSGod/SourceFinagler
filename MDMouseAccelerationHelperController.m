//
//  MDMouseAccelerationHelperController.m
//  Source Finagler
//
//  Created by Mark Douma on 8/21/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDMouseAccelerationHelperController.h"
#import "MDGame.h"
#import "VSSteamManager.h"
#import "MDAppKitAdditions.h"


NSString * const MDImageURLKey = @"http://cdn.store.steampowered.com/gamedetailsheader/440/image.jpg";

NSString * const MDMouseAccelerationHelperViewSizeKey = @"MDMouseAccelerationHelperViewSize";


@implementation MDMouseAccelerationHelperController


- (id)init {
	if (self = [super init]) {
		games = [[NSMutableArray alloc] init];
		steamManager = [[VSSteamManager defaultManager] retain];
		resizable = YES;
	}
	return self;
}


- (void)awakeFromNib {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	minWinSize = [view frame].size;
	maxWinSize = NSMakeSize(16000, 16000);
	
//	NSArray *theGames = [steamManager games];
//	if (theGames && [theGames count]) {
//		[self insertGames:theGames atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [theGames count])]];
//	}
	

	
}


- (void)appControllerDidLoadNib:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSUserDefaults *uD = [NSUserDefaults standardUserDefaults];
	if ([uD objectForKey:MDMouseAccelerationHelperViewSizeKey] == nil) [uD setObject:[view stringWithSavedFrame] forKey:MDMouseAccelerationHelperViewSizeKey];
	[view setFrameFromString:[uD objectForKey:MDMouseAccelerationHelperViewSizeKey]];
	[super appControllerDidLoadNib:self];
}



- (IBAction)revealInFinder:(id)sender {
	
}


- (IBAction)refresh:(id)sender {
	
}


- (IBAction)helpApps:(id)sender {
	
}


- (IBAction)restoreToDefault:(id)sender {
	
}


- (IBAction)launchGame:(id)sender {
	
}





@end
