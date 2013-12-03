//
//  TKBlueBackgroundView.m
//  Source Finagler
//
//  Created by Mark Douma on 10/17/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import "TKBlueBackgroundView.h"


#define MD_RED		200.0/255.0
#define MD_GREEN	206.0/255.0
#define MD_BLUE		218.0/255.0

#define MD_DARKER_RED		192.0/255.0
#define MD_DARKER_GREEN		196.0/255.0
#define MD_DARKER_BLUE		206.0/255.0



@interface TKBlueBackgroundView (TKPrivate)
- (void)finishSetup;
@end


@implementation TKBlueBackgroundView


- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
		[self finishSetup];
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super initWithCoder:coder])) {
		[self finishSetup];
	}
	return self;
}


- (void)dealloc {
	[gradient release];
	[super dealloc];
}


- (void)finishSetup {
	gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:MD_DARKER_RED green:MD_DARKER_GREEN blue:MD_DARKER_BLUE alpha:1.0]
											 endingColor:[NSColor colorWithCalibratedRed:MD_RED green:MD_GREEN blue:MD_BLUE alpha:1.0]];
	
}

- (void)drawRect:(NSRect)dirtyRect {
	[gradient drawInRect:[self bounds] angle:90.0];
}


@end

