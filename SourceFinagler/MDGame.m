//
//  MDGame.m
//  Source Finagler
//
//  Created by Mark Douma on 9/28/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDGame.h"


@implementation MDGame

@synthesize enabled, name, path, URL, image;

- (id)initWithPath:(NSString *)aPath {
	if (aPath && (self = [super initWithParent:nil children:nil sortDescriptors:nil container:nil])) {
		[self setPath:[aPath stringByStandardizingPath]];
		[self setName:[path lastPathComponent]];
		[self setURL:[NSURL fileURLWithPath:path]];
		[self setImage:nil];
	}
	return self;
}



- (void)dealloc {
	[name release];
	[path release];
	[URL release];
	[image release];
	[super dealloc];
}



@end
