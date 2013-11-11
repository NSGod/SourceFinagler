//
//  MDOutlineView.h
//  Source Finagler
//
//  Created by Mark Douma on 4/16/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MDTextFieldCell;

extern NSString * const MDShouldShowKindColumnKey;
extern NSString * const MDShouldShowSizeColumnKey;
extern NSString * const MDListViewIconSizeKey;
extern NSString * const MDListViewFontSizeKey;
	

@interface MDOutlineView : NSOutlineView {
    IBOutlet NSTableColumn		*nameColumn;
	IBOutlet NSTableColumn		*kindColumn;
    IBOutlet NSTableColumn		*sizeColumn;
	
	BOOL						shouldShowKindColumn;
	BOOL						shouldShowSizeColumn;
	
	NSInteger					fontSize;
	NSInteger					iconSize;
	NSInteger					rowHeight;
	
}

- (NSInteger)iconSize;

- (NSArray *)itemsAtRowIndexes:(NSIndexSet *)rowIndexes;
- (NSIndexSet *)rowIndexesForItems:(NSArray *)items;

@end

