//
//  MDTextFieldCell.m
//  Source Finagler
//
//  Created by Mark Douma on 1/31/2008.
//  Copyright © 2008 Mark Douma. All rights reserved.
//  


#define MD_LEFT_EDGE_PADDING 16.0


#import "MDTextFieldCell.h"


#define MD_DEBUG 0

@implementation MDTextFieldCell

- (id)copyWithZone:(NSZone *)zone {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	MDTextFieldCell *cell = (MDTextFieldCell *)[super copyWithZone:zone];
	cell->image = nil;
	[cell setImage:image];
	return cell;
}



- (id)initTextCell:(NSString *)value {
	if  ((self = [super initTextCell:value])) {
		image = nil;
		debug = NO;
		centerImageVertically = NO;
		leftEdgePadding = MD_LEFT_EDGE_PADDING;
	}
	return self;
}



- (id)initImageCell:(NSImage *)value {
	if ((self = [super initImageCell:value])) {
		image = [value retain];
		debug = NO;
		centerImageVertically = NO;
		leftEdgePadding = MD_LEFT_EDGE_PADDING;
	}
	return self;
}



- (id)init {
	if ((self = [super initTextCell:@""])) {
		image = nil;
		debug = NO;
		centerImageVertically = NO;
		leftEdgePadding = MD_LEFT_EDGE_PADDING;
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super initWithCoder:coder])) {
		image = nil;
		debug = NO;
		leftEdgePadding = MD_LEFT_EDGE_PADDING;
		centerImageVertically = NO;
		
	}
	return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeObject:[NSNumber numberWithDouble:(double) MD_LEFT_EDGE_PADDING] forKey:@"MDLeftEdgePadding"];
	[coder encodeObject:[NSNumber numberWithBool:centerImageVertically] forKey:@"MDCenterImageVertically"];
}


- (void)dealloc {
	[image release];
	[super dealloc];
}


- (NSImage *)image {
    return image;
}


- (void)setImage:(NSImage *)value {
    [value retain];
    [image release];
    image = value;
}


- (void)setLeftEdgePadding:(CGFloat)aPadding {
	leftEdgePadding = aPadding;
}


- (CGFloat)leftEdgePadding {
	return leftEdgePadding;
}


- (BOOL)centerImageVertically {
    return centerImageVertically;
}

- (void)setCenterImageVertically:(BOOL)value {
	centerImageVertically = value;
}


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	NSSize	imageSize = NSZeroSize;
	NSPoint	imagePoint = NSZeroPoint;
	
	if ([self image]) {
		imageSize = [[self image] size];
		imagePoint = cellFrame.origin;
		imagePoint.x += leftEdgePadding;
		
		if ([controlView isFlipped]) {
			if (imageSize.height == 16.0) {
				if (centerImageVertically) {
					imagePoint.y += (imageSize.height + ceil((cellFrame.size.height - imageSize.height)/2.0));
					
				} else {
					if (cellFrame.size.height >= 17.0 && cellFrame.size.height <= 18.0) {
						// in other words, if the font size is 15 pt or 16 pt
						imagePoint.y += imageSize.height;
					} else {
						imagePoint.y += (imageSize.height - 1.0);
					}
				}
			} else if (imageSize.height == 32.0) {
				imagePoint.y += imageSize.height;
			}
		} else {
			if (imageSize.height == 16.0) {
				if (cellFrame.size.height == 18.0) {
					imagePoint.y += 1.0;
				} else {
					
				}
			} else if (imageSize.height == 32.0) {
//				imagePoint.y += imageSize.height;
			}
		}
		
	}
	
	NSMutableParagraphStyle *style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[style setLineBreakMode:NSLineBreakByTruncatingMiddle];
	[style setAlignment:[self alignment]];
	
	NSDictionary *attributes = nil;
	
	BOOL isEnabled = [self isEnabled];
	
	if ([self isHighlighted]) {
		
		NSImage *tempImage = [self image];
		id tempObject = [self objectValue];
		
#if MD_DEBUG
		NSLog(@"[%@ %@] tempImage == %@, tempObject == %@, stringValue == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tempImage, tempObject, [self stringValue]);
#endif
	
		
		[self setImage:nil];
		[self setStringValue:@""];
		
		[super drawWithFrame:cellFrame inView:controlView];
		
		[self setImage:tempImage];
		[self setObjectValue:tempObject];
		
		
		if ([[controlView window] isKeyWindow]) {
			attributes = [NSDictionary dictionaryWithObjectsAndKeys:[self font],NSFontAttributeName,
			 style,NSParagraphStyleAttributeName,
			 (isEnabled ? [NSColor alternateSelectedControlTextColor] : [NSColor colorWithCalibratedRed:208.0/255.0 green:208.0/255.0 blue:208.0/255.0 alpha:1.0] ),NSForegroundColorAttributeName, nil];
			
		} else {
			attributes = [NSDictionary dictionaryWithObjectsAndKeys:[self font],NSFontAttributeName,
						  style,NSParagraphStyleAttributeName,
						  (isEnabled ? [NSColor controlTextColor] : [[NSColor controlTextColor] colorWithAlphaComponent:0.5]),NSForegroundColorAttributeName, nil];
		}
		
	} else {
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:[self font],NSFontAttributeName,
					  style,NSParagraphStyleAttributeName,
					  (isEnabled ? [self textColor] : [[NSColor controlTextColor] colorWithAlphaComponent:0.5]),NSForegroundColorAttributeName, nil];
	}
	
	if ([self image]) {
		
		[[self image] compositeToPoint:imagePoint operation:NSCompositeSourceOver fraction:(isEnabled ? 1.0 : 0.5)];
	}
	
	NSAttributedString *richText = [[[NSAttributedString alloc] initWithString:[self stringValue] attributes:attributes] autorelease];
	
	CGFloat fontSize = [[self font] pointSize];
	CGFloat fontBaselineFudge = 0.0;
	
	if ([controlView isFlipped]) {
		if (fontSize >= 12.0 && fontSize <= 14.0) {
			fontBaselineFudge = -1.0;
		} else if (fontSize == 16.0) {
			fontBaselineFudge = 1.0;
		}
	} else {
		if (fontSize >= 12.0 && fontSize <= 14.0) {
			fontBaselineFudge = 1.0;
		} else if (fontSize == 16.0) {
			fontBaselineFudge = -1.0;
		}
	}
	
	CGFloat textMarginFudge = 0.0;
	CGFloat textWidthFudge = 0.0;
	
	if ([self image] == nil) {
		if ([self alignment] == NSLeftTextAlignment) {
			textMarginFudge = 15.0;
			textWidthFudge = -30.0;
		} else {
			textMarginFudge = 15.0;
			textWidthFudge = -30.0;
		}
	} else {
		if ([self alignment] == NSLeftTextAlignment) {
//			textMarginFudge = 15.0;
			textWidthFudge = -15.0;
		} else {
			textMarginFudge = -15.0;
		}
	}
	
	NSRect richTextRect;
	richTextRect.size = [richText size];
	
	richTextRect.origin.x = cellFrame.origin.x + textMarginFudge;
	
	if ([controlView isFlipped]) {
		richTextRect.origin.y = cellFrame.origin.y + fontBaselineFudge + floor((cellFrame.size.height - richTextRect.size.height)/2.0);
	} else {
		richTextRect.origin.y = cellFrame.origin.y - 1.0 + fontBaselineFudge + ceil((cellFrame.size.height - richTextRect.size.height)/2.0);
	}
	
	richTextRect.size.width = cellFrame.size.width + textWidthFudge;
	
	if ([self image]) {
		richTextRect.origin.x += (leftEdgePadding + imageSize.width + 6.0);
		richTextRect.size.width -= (leftEdgePadding + imageSize.width + 6.0);
	}
	
	[richText drawInRect:richTextRect];
	
//	[[NSColor greenColor] set];
//	[NSBezierPath strokeRect:richTextRect];
	
//	[self hitRectsForFrame:cellFrame isFlipped:[controlView isFlipped]];
//	
//	[[[NSColor greenColor] colorWithAlphaComponent:0.37] set];
//	
//	NSEnumerator *enumerator = [hitRects objectEnumerator];
//	NSValue *hitRectValue;
//	
//	while (hitRectValue = [enumerator nextObject]) {
//		NSRect hitRect = [hitRectValue rectValue];
//		[NSBezierPath fillRect:hitRect];
//	}
}


- (NSSize)cellSize {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		
	NSSize cellSize = [super cellSize];
	
	if ([self image] == nil) {
		cellSize.width -= 30.0;
	} else {
		cellSize.width -= 31.0;
	}
	return cellSize;
}


- (void)drawWithFrame:(NSRect)cellFrame inImage:(NSImage *)dragImage {
//	NSLog(@"[MDTextFieldCell drawWithFrame:inImage:] %f,%f",cellFrame.origin.x,cellFrame.origin.y);
	
	if (debug) {
		[dragImage lockFocus];
//		[[[NSColor grayColor] colorWithAlphaComponent:0.37] set];
		[[[NSColor redColor] colorWithAlphaComponent:0.37] set];
		[NSBezierPath fillRect:cellFrame];
		[dragImage unlockFocus];
	}
	
	NSSize	imageSize = NSZeroSize;
	NSPoint imagePoint = NSZeroPoint;
	
	if ([self image]) {
		imageSize = [[self image] size];
		imagePoint = cellFrame.origin;
		imagePoint.x += leftEdgePadding;
		
		if ([dragImage isFlipped]) {
//			NSLog(@"[MDTextFieldCell drawWithFrame:inImage:] dragImage isFlipped");
			if (imageSize.height == 16.0) {
				if (cellFrame.size.height >= 17.0 && cellFrame.size.height <= 18.0) {
					// in other words, if the font size is 15 pt or 16 pt
					imagePoint.y += imageSize.height;
				} else {
					imagePoint.y += (imageSize.height - 1.0);
				}
			} else if (imageSize.height == 32.0) {
				imagePoint.y += imageSize.height;
			}
		} else {
//			NSLog(@"[MDTextFieldCell drawWithFrame:inImage:] dragImage is NOT isFlipped");
			if (imageSize.height == 16.0) {
//				NSLog(@"[MDTextFieldCell drawWithFrame:inImage:] cellFrame.size.height == %f", cellFrame.size.height);
				if (cellFrame.size.height == 18.0) {
					imagePoint.y += 1.0;
				} else {
					
				}
			} else if (imageSize.height == 32.0) {
				
			}
		}
		
		[dragImage lockFocus];
		[[self image] compositeToPoint:imagePoint operation:NSCompositeSourceOver fraction:0.37];
		[dragImage unlockFocus];
	}
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[self font],NSFontAttributeName, [[NSColor controlTextColor] colorWithAlphaComponent:0.37],NSForegroundColorAttributeName, nil];
	
	NSAttributedString *richText = [[[NSAttributedString alloc] initWithString:[self stringValue] attributes:attributes] autorelease];
	
	CGFloat fontSize = [[self font] pointSize];
	CGFloat fontBaselineFudge = 0.0;
	
	if ([dragImage isFlipped]) {
		if (fontSize >= 12.0 && fontSize <= 14.0) {
			fontBaselineFudge = -1.0;
		} else if (fontSize == 16.0) {
			fontBaselineFudge = 1.0;
		}
	} else {
		if (fontSize >= 12.0 && fontSize <= 14.0) {
			fontBaselineFudge = 1.0;
		} else if (fontSize == 16.0) {
			fontBaselineFudge = -1.0;
		}
	}
	
	CGFloat textMarginFudge = 0.0;
	CGFloat textWidthFudge = 0.0;
	
	
	if ([self image] == nil) {
		if ([self alignment] == NSLeftTextAlignment) {
			textMarginFudge = 15.0;
			textWidthFudge = -30.0;
		} else {
			textMarginFudge = 15.0;
			textWidthFudge = -30.0;
		}
	} else {
		if ([self alignment] == NSLeftTextAlignment) {
//			textMarginFudge = 15.0;
			textWidthFudge = -15.0;
		} else {
			textMarginFudge = -15.0;
		}
	}
	
	NSRect richTextRect;
	
	richTextRect.size = [richText size];
	
	richTextRect.origin.x = cellFrame.origin.x + textMarginFudge;
	
	if ([dragImage isFlipped]) {
		richTextRect.origin.y = cellFrame.origin.y + fontBaselineFudge + floor((cellFrame.size.height - richTextRect.size.height)/2.0);
	} else {
		
		richTextRect.origin.y = cellFrame.origin.y - 1.0 + fontBaselineFudge + ceil((cellFrame.size.height - richTextRect.size.height)/2.0);
	}
	
	richTextRect.size.width = cellFrame.size.width + textWidthFudge;
	
	if ([self image]) {
		richTextRect.origin.x += (leftEdgePadding + imageSize.width + 6.0);
		richTextRect.size.width -= (leftEdgePadding + imageSize.width + 6.0);
	}
	
	[dragImage lockFocus];
	[richText drawInRect:richTextRect];
	[dragImage unlockFocus];
	
}


	
- (NSArray *)hitRectsForFrame:(NSRect)cellFrame isFlipped:(BOOL)isFlipped {
//	NSLog(@"[MDTextFieldCell hitRectsForFrame:isFlipped:] isFlipped == %@", (isFlipped ? @"YES" : @"NO"));
	
	NSMutableArray *hitRects = [NSMutableArray array];
	
	NSSize	imageSize = NSZeroSize;
	NSPoint imagePoint = NSZeroPoint;
	NSRect	imageFrame = NSZeroRect;
	
	if ([self image]) {
		imageSize = [[self image] size];
		imagePoint = cellFrame.origin;
		imagePoint.x += leftEdgePadding;
		
		if (isFlipped) {
			if (imageSize.height == 16.0) {
				if (cellFrame.size.height >= 17.0 && cellFrame.size.height <= 18.0) {
					// in other words, if the font size is 15 pt or 16 pt
//					imagePoint.y += imageSize.height;
				} else {
					imagePoint.y -= 1.0;
				}
			} else if (imageSize.height == 32.0) {
//				imagePoint.y += imageSize.height;
			}
		} else {
			if (imageSize.height == 16.0) {
				if (cellFrame.size.height == 18.0) {
					imagePoint.y += 1.0;
				} else {
					
				}
			} else if (imageSize.height == 32.0) {
				
			}
		}
		
		imageFrame = NSMakeRect(imagePoint.x, imagePoint.y, imageSize.width, imageSize.height);
		
		[hitRects addObject:[NSValue valueWithRect:imageFrame]];
	}
	
	NSMutableParagraphStyle *style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[style setLineBreakMode:NSLineBreakByTruncatingMiddle];
	[style setAlignment:[self alignment]];
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[self font],NSFontAttributeName, style,NSParagraphStyleAttributeName, nil];
	
	NSAttributedString *richText = [[[NSAttributedString alloc] initWithString:[self stringValue] attributes:attributes] autorelease];
	
	CGFloat fontSize = [[self font] pointSize];
	CGFloat fontBaselineFudge = 0.0;
	
	if (isFlipped) {
		if (fontSize >= 12.0 && fontSize <= 14.0) {
			fontBaselineFudge = -1.0;
		} else if (fontSize == 16.0) {
			fontBaselineFudge = 1.0;
		}
	} else {
		if (fontSize >= 12.0 && fontSize <= 14.0) {
			fontBaselineFudge = 1.0;
		} else if (fontSize == 16.0) {
			fontBaselineFudge = -1.0;
		}
	}
	
	CGFloat textMarginFudge = 0.0;
	CGFloat textWidthFudge = 0.0;
	
	if ([self image] == nil) {
		if ([self alignment] == NSLeftTextAlignment) {
			textMarginFudge = 15.0;
			textWidthFudge = -30.0;
		} else {
			textMarginFudge = 15.0;
			textWidthFudge = -30.0;
		}
	} else {
		if ([self alignment] == NSLeftTextAlignment) {
//			textMarginFudge = 15.0;
			textWidthFudge = -15.0;
		} else {
			textMarginFudge = -15.0;
		}
	}
	
	NSRect richTextRect = NSZeroRect;
	richTextRect.size = [richText size];
	
	if ([self alignment] == NSLeftTextAlignment) {
		richTextRect.origin.x = cellFrame.origin.x + textMarginFudge;
	} else {
		richTextRect.origin.x = ((cellFrame.origin.x + cellFrame.size.width + textMarginFudge + textWidthFudge) - richTextRect.size.width);
	}
	
	if (isFlipped) {
		richTextRect.origin.y = cellFrame.origin.y + fontBaselineFudge + floor((cellFrame.size.height - richTextRect.size.height)/2.0);
	} else {
		richTextRect.origin.y = cellFrame.origin.y - 1.0 + fontBaselineFudge + ceil((cellFrame.size.height - richTextRect.size.height)/2.0);
	}
	
	
	if ([self image]) {
		richTextRect.origin.x += (leftEdgePadding + imageSize.width + 6.0);
	}
	
	[hitRects addObject:[NSValue valueWithRect:richTextRect]];
	
	return [[hitRects copy] autorelease];
}


@end




