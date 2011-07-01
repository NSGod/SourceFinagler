//
//  MDBrowserCell.h
//  Source Finagler
//
//  Created by Mark Douma on 6/28/2005.
//  Copyright 2005 Mark Douma. All rights reserved.
//


#import <Cocoa/Cocoa.h>


@interface MDBrowserCell : NSTextFieldCell {
	NSImage		*image;
	BOOL		itemIsInvisible;
}

@property (assign) BOOL itemIsInvisible;
@property (retain) NSImage *image;

@end
