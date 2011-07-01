//
//  VSGameAdditions.h
//  Source Finagler
//
//  Created by Mark Douma on 5/29/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SteamKit/SteamKit.h>

@interface VSGame (VSAdditions)

- (NSString *)helpedStateString;
- (NSColor *)helpedStateColor;

- (NSImage *)runningStateImage;


@end
