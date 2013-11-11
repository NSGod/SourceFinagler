//
//  MDMetalBevelView.h
//  Source Finagler
//
//  Created by Mark Douma on 4/4/2006.
//  Copyright © 2007 Mark Douma. All rights reserved.
//



#import <Cocoa/Cocoa.h>


@interface MDMetalBevelView : NSView {
//	BOOL debug;
	BOOL drawsBackground;
}
- (BOOL)drawsBackground;
- (void)setDrawsBackground:(BOOL)value;


@end
