//
//  TKImageKitAdditions.m
//  Source Finagler
//
//  Created by Mark Douma on 12/2/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import "TKImageKitAdditions.h"


#define TK_DEBUG 0


@implementation IKImageBrowserView (TKImageKitAdditions)


/* this is likely being called for the faceBrowserView & mipmapBrowserView	*/
- (CGFloat)idealViewWidth {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	// `numberOfColumns` and `numberOfRows` are only available in OS X 10.6 and later. 
	if ([self respondsToSelector:@selector(numberOfColumns)] && [self respondsToSelector:@selector(numberOfRows)]) {
		NSUInteger numberOfColumns = [self numberOfColumns];
		NSUInteger numberOfRows = [self numberOfRows];
		
		if (numberOfColumns == 0 && numberOfRows == 0) {
			// if we have no content, then ideal width/height would be 0.0
			return 0.0;
			
		} else if (numberOfColumns && numberOfRows) {
#if TK_DEBUG
			NSRect itemFrame = [self itemFrameAtIndex:0];
			NSLog(@"[%@ %@] itemFrame == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(itemFrame));
#endif
			
			NSRect rectOfColumn = [self rectOfColumn:0];
#if TK_DEBUG
			NSLog(@"[%@ %@] rectOfColumn == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(rectOfColumn));
#endif
			
#if TK_DEBUG
			NSRect rectOfRow = [self rectOfRow:0];
			NSLog(@"[%@ %@] rectOfRow == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(rectOfRow));
#endif
			
			return NSWidth(rectOfColumn);
		}
	}
	return NSWidth(self.bounds);
	
}


/* this is likely being called for the frameBrowserView	*/
- (CGFloat)idealViewHeight {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	// `numberOfColumns` and `numberOfRows` are only available in OS X 10.6 and later. 
	if ([self respondsToSelector:@selector(numberOfColumns)] && [self respondsToSelector:@selector(numberOfRows)]) {
		NSUInteger numberOfColumns = [self numberOfColumns];
		NSUInteger numberOfRows = [self numberOfRows];
		
		if (numberOfColumns == 0 && numberOfRows == 0) {
			// if we have no content, then ideal width/height would be 0
			return 0.0;
			
		} else if (numberOfColumns && numberOfRows) {
#if TK_DEBUG
			NSRect itemFrame = [self itemFrameAtIndex:0];
			NSLog(@"[%@ %@] itemFrame == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(itemFrame));
#endif
			
#if TK_DEBUG
			NSRect rectOfColumn = [self rectOfColumn:0];
			NSLog(@"[%@ %@] rectOfColumn == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(rectOfColumn));
#endif
			
			NSRect rectOfRow = [self rectOfRow:0];
#if TK_DEBUG
			NSLog(@"[%@ %@] rectOfRow == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(rectOfRow));
#endif
			
			return NSHeight(rectOfRow);
		}
	}
	return NSHeight(self.bounds);
}


@end
