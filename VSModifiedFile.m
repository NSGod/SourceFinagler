//
//  VSModifiedFile.m
//  Source Finagler
//
//  Created by Mark Douma on 12/21/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "VSModifiedFile.h"


@implementation VSModifiedFile

@synthesize path, name, image, status;


- (id)initWithPath:(NSString *)aPath status:(NSString *)aStatus {
	if (self = [super init]) {
		[self setPath:aPath];
		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:aPath];
		if (icon) {
			[icon setSize:NSMakeSize(16.0, 16.0)];
			[self setImage:icon];
		}
		[self setName:[aPath lastPathComponent]];
		[self setStatus:aStatus];
	}
	return self;
}


- (void)dealloc {
	[path release];
	[name release];
	[image release];
	[status release];
	[super dealloc];
}


@end
