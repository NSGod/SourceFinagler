//
//  MDTextFieldCell.h
//  Source Finagler
//
//  Created by Mark Douma on 1/31/2008.
//  Copyright © 2008 Mark Douma. All rights reserved.
//  


#import <Cocoa/Cocoa.h>


@interface MDTextFieldCell : NSTextFieldCell <NSCoding, NSCopying> {
	NSImage			*image;
	CGFloat			leftEdgePadding;
	BOOL			centerImageVertically;

}

- (void)drawWithFrame:(NSRect)cellFrame inImage:(NSImage *)dragImage;

- (NSArray *)hitRectsForFrame:(NSRect)cellFrame isFlipped:(BOOL)isFlipped;

- (void)setLeftEdgePadding:(CGFloat)aPadding;
- (CGFloat)leftEdgePadding;

- (BOOL)centerImageVertically;
- (void)setCenterImageVertically:(BOOL)value;

@end

