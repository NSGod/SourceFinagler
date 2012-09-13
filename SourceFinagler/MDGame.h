//
//  MDGame.h
//  Source Finagler
//
//  Created by Mark Douma on 9/28/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDNode.h"
#import <Cocoa/Cocoa.h>


@interface MDGame : MDNode {
	BOOL			enabled;
	NSString		*name;
	NSString		*path;
	NSURL			*URL;
	NSImage			*image;
}
- (id)initWithPath:(NSString *)aPath;

@property (assign) BOOL enabled;
@property (retain) NSString *name;
@property (retain) NSString *path;
@property (retain) NSURL	*URL;
@property (retain) NSImage	*image;

@end
