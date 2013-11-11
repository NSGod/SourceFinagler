//
//  TKImageChannelCell.h
//  Source Finagler
//
//  Created by Mark Douma on 10/24/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TKImageChannelCell : NSTextFieldCell {
		NSImage		*image;
}

@property (retain) NSImage *image;

@end
