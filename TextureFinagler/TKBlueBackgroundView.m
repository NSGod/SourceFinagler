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


//#define MD_DARKER_RED		0.0
//#define MD_DARKER_GREEN		0.0
//#define MD_DARKER_BLUE		0.0


@interface TKBlueBackgroundView (TKPrivate)
- (void)finishSetup;
@end


@implementation TKBlueBackgroundView

//@dynamic backgroundColor;

//@dynamic gradient;


- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
		[self finishSetup];
//		backgroundColor = [[NSColor colorWithCalibratedRed:MD_RED green:MD_GREEN blue:MD_BLUE alpha:1.0] retain];
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super initWithCoder:coder])) {
		[self finishSetup];
//		backgroundColor = [[NSColor colorWithCalibratedRed:MD_RED green:MD_GREEN blue:MD_BLUE alpha:1.0] retain];
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
	
//	[self setWantsLayer:YES];
	
	
//	CAGradientLayer *layer = [CAGradientLayer layer];
//	layer.frame = CGRectMake(0.0, 0.0, NSWidth([self bounds]), NSHeight([self bounds]));
//	layer.position = CGPointMake(NSWidth([self bounds])/2.0, NSHeight([self bounds])/2.0);
//	layer.autoresizingMask = kCALayerHeightSizable | kCALayerWidthSizable | kCALayerMinXMargin | kCALayerMinYMargin | kCALayerMaxXMargin | kCALayerMaxYMargin;
//	
//	CGColorRef upperBlueColorRef = CGColorCreateGenericRGB(MD_RED, MD_GREEN, MD_BLUE, 1.0);
//	CGColorRef lowerBlueColorRef = CGColorCreateGenericRGB(MD_DARKER_RED, MD_DARKER_GREEN, MD_DARKER_BLUE, 1.0);
//	
//	layer.colors = [NSArray arrayWithObjects:(id)upperBlueColorRef, (id)lowerBlueColorRef, nil];
//	
//	CGColorRelease(upperBlueColorRef);
//	CGColorRelease(lowerBlueColorRef);
//	
//	[self setLayer:layer];
//	
//	[self setWantsLayer:YES];
	
}

- (void)drawRect:(NSRect)dirtyRect {
	[gradient drawInRect:[self bounds] angle:90.0];
}


@end




//- (NSColor *)backgroundColor {
//    return backgroundColor;
//}
//
//- (void)setBackgroundColor:(NSColor *)value {
//	[value retain];
//	[backgroundColor release];
//	backgroundColor = value;
//	[self setNeedsDisplay:YES];
//}
//
//


//@implementation TKBlueBackgroundView
//
//@dynamic backgroundColor;
//
//
//- (id)initWithFrame:(NSRect)frame {
//    if ((self = [super initWithFrame:frame])) {
//		backgroundColor = [[NSColor colorWithCalibratedRed:MD_RED green:MD_GREEN blue:MD_BLUE alpha:1.0] retain];
//    }
//    return self;
//}
//
//
//- (id)initWithCoder:(NSCoder *)coder {
//	if ((self = [super initWithCoder:coder])) {
//		backgroundColor = [[NSColor colorWithCalibratedRed:MD_RED green:MD_GREEN blue:MD_BLUE alpha:1.0] retain];
//	}
//	return self;
//}
//
//
//- (void)dealloc {
//	[backgroundColor release];
//	[super dealloc];
//}
//
//
//- (NSColor *)backgroundColor {
//    return backgroundColor;
//}
//
//- (void)setBackgroundColor:(NSColor *)value {
//	[value retain];
//	[backgroundColor release];
//	backgroundColor = value;
//	[self setNeedsDisplay:YES];
//}
//
//
//- (void)drawRect:(NSRect)dirtyRect {
//	[backgroundColor set];
//	NSRectFill(dirtyRect);
//}
//
//
//@end
//


