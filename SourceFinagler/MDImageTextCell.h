//
//  MDImageTextCell.h
//  Source Finagler
//
//  Created by Mark Douma on 6/28/2005.
//  Copyright 2005 Mark Douma. All rights reserved.
//


#import <Cocoa/Cocoa.h>


@interface MDImageTextCell : NSTextFieldCell {
	NSImage		*image;
}

@property (nonatomic, retain) NSImage *image;

@end
