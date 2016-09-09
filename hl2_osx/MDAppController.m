//
//  MDAppController.m
//  hl2_osx
//
//  Created by Mark Douma on 11/22/2012.
//  Copyright 2012 Mark Douma LLC. All rights reserved.
//

#import "MDAppController.h"

#define MD_DEBUG 1

@implementation MDAppController


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[NSApp runModalForWindow:window];
}


- (IBAction)quit:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[NSApp stopModal];
	[NSApp terminate:nil];
}


@end
