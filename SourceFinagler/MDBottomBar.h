//
//  MDBottomBar.h
//  Source Finagler
//
//  Created by Mark Douma on 10/29/2008.
//  Copyright 2008 Mark Douma. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MDFileSizeFormatter;


@interface MDBottomBar : NSView {
	NSIndexSet			*selectedIndexes;
	NSNumber			*totalCount;
	NSNumber			*freeSpace;
	MDFileSizeFormatter	*formatter;
}
- (void)setSelectedIndexes:(NSIndexSet *)anIndexSet totalCount:(NSNumber *)aTotalCount freeSpace:(NSNumber *)aFreeSpace;

@end
