//
//  TKImageKitAdditions.m
//  Source Finagler
//
//  Created by Mark Douma on 12/2/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import "TKImageKitAdditions.h"


#define TK_DEBUG 1


@implementation IKImageBrowserView (TKImageKitAdditions)


/* this is likely being called for the faceBrowserView & mipmapBrowserView	*/
- (CGFloat)idealViewWidth {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSRect bounds = [self bounds];
	NSUInteger numberOfColumns = [self numberOfColumns];
	NSUInteger numberOfRows = [self numberOfRows];
	
	if (numberOfColumns == 0 && numberOfRows == 0) {
		// if we have no content, then ideal width/height would be 0.0
		return 0.0;
		
	} else if (numberOfColumns && numberOfRows) {
		NSRect itemFrame = [self itemFrameAtIndex:0];
#if TK_DEBUG
		NSLog(@"[%@ %@] itemFrame == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(itemFrame));
#endif
		
		NSRect rectOfColumn = [self rectOfColumn:0];
#if TK_DEBUG
		NSLog(@"[%@ %@] rectOfColumn == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(rectOfColumn));
#endif
		
		NSRect rectOfRow = [self rectOfRow:0];
#if TK_DEBUG
		NSLog(@"[%@ %@] rectOfRow == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(rectOfRow));
#endif
		
		return NSWidth(rectOfColumn);
	}
	
	return NSWidth(bounds);
}

/* this is likely being called for the frameBrowserView	*/
- (CGFloat)idealViewHeight {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSRect bounds = [self bounds];
	NSUInteger numberOfColumns = [self numberOfColumns];
	NSUInteger numberOfRows = [self numberOfRows];
	
	if (numberOfColumns == 0 && numberOfRows == 0) {
		// if we have no content, then ideal width/height would be 0
		return 0.0;
		
	} else if (numberOfColumns && numberOfRows) {
		NSRect itemFrame = [self itemFrameAtIndex:0];
#if TK_DEBUG
		NSLog(@"[%@ %@] itemFrame == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(itemFrame));
#endif
		
		NSRect rectOfColumn = [self rectOfColumn:0];
#if TK_DEBUG
		NSLog(@"[%@ %@] rectOfColumn == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(rectOfColumn));
#endif
		
		NSRect rectOfRow = [self rectOfRow:0];
#if TK_DEBUG
		NSLog(@"[%@ %@] rectOfRow == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(rectOfRow));
#endif
		
		return NSHeight(rectOfRow);
	}
	
	return NSHeight(bounds);
}


@end
