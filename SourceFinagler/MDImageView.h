//
//  MDImageView.h
//  Source Finagler
//
//  Created by Mark Douma on 10/10/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MDImageView : NSView {
	NSImage *image;
}

@property (retain) NSImage *image;

@end
