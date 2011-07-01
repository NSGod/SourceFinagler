//
//  MDOutlineView.m
//  Source Finagler
//
//  Created by Mark Douma on 4/16/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDOutlineView.h"
#import "MDHLDocument.h"
#import "MDTextFieldCell.h"
#import "MDAppKitAdditions.h"


NSString * const MDShouldShowKindColumnKey							= @"MDShouldShowKindColumn";
NSString * const MDShouldShowSizeColumnKey							= @"MDShouldShowSizeColumn";

NSString * const MDListViewIconSizeKey								= @"MDListViewIconSize";
NSString * const MDListViewFontSizeKey								= @"MDListViewFontSize";

#define MD_DEBUG 0

@interface MDOutlineView (MDPrivate)
- (void)calculateRowHeight;
@end

@implementation MDOutlineView


- (id)init {
	if ((self = [super init])) {

	}
	return self;
}


- (void)dealloc {
	
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[kindColumn release];
	[sizeColumn release];
	
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:NSStringFromDefaultsKeyPath(MDListViewFontSizeKey)];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:NSStringFromDefaultsKeyPath(MDListViewIconSizeKey)];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:NSStringFromDefaultsKeyPath(MDShouldShowKindColumnKey)];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:NSStringFromDefaultsKeyPath(MDShouldShowSizeColumnKey)];
	
	[super dealloc];
}


- (void)awakeFromNib {
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:NSStringFromDefaultsKeyPath(MDListViewFontSizeKey)
																 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:NSStringFromDefaultsKeyPath(MDListViewIconSizeKey)
																 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:NSStringFromDefaultsKeyPath(MDShouldShowKindColumnKey)
																 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:NSStringFromDefaultsKeyPath(MDShouldShowSizeColumnKey)
																 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
	
	
	// from controllers
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	fontSize = [[userDefaults objectForKey:MDListViewFontSizeKey] integerValue];
	iconSize = [[userDefaults objectForKey:MDListViewIconSizeKey] integerValue];
	[self calculateRowHeight];
	
	[[nameColumn dataCell] setFont:[NSFont systemFontOfSize:(CGFloat)fontSize]];
	[[sizeColumn dataCell] setFont:[NSFont systemFontOfSize:(CGFloat)fontSize]];
	[[kindColumn dataCell] setFont:[NSFont systemFontOfSize:(CGFloat)fontSize]];
	
	[kindColumn retain];
	[sizeColumn retain];

	shouldShowKindColumn = [[userDefaults objectForKey:MDShouldShowKindColumnKey] boolValue];
	if (!shouldShowKindColumn) [self removeTableColumn:kindColumn];
	
	shouldShowSizeColumn = [[userDefaults objectForKey:MDShouldShowSizeColumnKey] boolValue];
	if (!shouldShowSizeColumn) [self removeTableColumn:sizeColumn];
	
	[self registerForDraggedTypes:[NSArray arrayWithObjects:MDDraggedItemsPboardType, NSFilenamesPboardType, nil]];
	[self setVerticalMotionCanBeginDrag:NO];
	
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([keyPath isEqualToString:NSStringFromDefaultsKeyPath(MDListViewFontSizeKey)]) {
		
		fontSize = [[[NSUserDefaults standardUserDefaults] objectForKey:MDListViewFontSizeKey] integerValue];
		[self calculateRowHeight];
		
		[(MDTextFieldCell *)[nameColumn dataCell] setFont:[NSFont systemFontOfSize:(CGFloat)fontSize]];
		[(MDTextFieldCell *)[sizeColumn dataCell] setFont:[NSFont systemFontOfSize:(CGFloat)fontSize]];
		[(MDTextFieldCell *)[kindColumn dataCell] setFont:[NSFont systemFontOfSize:(CGFloat)fontSize]];
		
		[self reloadData];
		
	} else if ([keyPath isEqualToString:NSStringFromDefaultsKeyPath(MDListViewIconSizeKey)]) {
		
		iconSize = [[[NSUserDefaults standardUserDefaults] objectForKey:MDListViewIconSizeKey] integerValue];
		[self calculateRowHeight];
		[self reloadData];
		
	} else if ([keyPath isEqualToString:NSStringFromDefaultsKeyPath(MDShouldShowKindColumnKey)]) {
		
		shouldShowKindColumn = [[[NSUserDefaults standardUserDefaults] objectForKey:MDShouldShowKindColumnKey] boolValue];
		(shouldShowKindColumn ? [self addTableColumn:kindColumn] : [self removeTableColumn:kindColumn]);
		[self reloadData];
		
	} else if ([keyPath isEqualToString:NSStringFromDefaultsKeyPath(MDShouldShowSizeColumnKey)]) {
		
		shouldShowSizeColumn = [[[NSUserDefaults standardUserDefaults] objectForKey:MDShouldShowSizeColumnKey] boolValue];
		(shouldShowSizeColumn ? [self addTableColumn:sizeColumn] : [self removeTableColumn:sizeColumn]);
		[self reloadData];
		
	} else {
		if ([super respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:)]) {
			// be sure to call the super implementation
			// if the superclass implements it
			[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
		}
	}
}


- (void)calculateRowHeight {
	if (iconSize == 16) {
		if (fontSize <= 13) {
			rowHeight = 16;
		} else {
			rowHeight = fontSize + 2;
		}
	} else if (iconSize == 32) {
		rowHeight = 34;
	}	
	[self setRowHeight:(CGFloat)rowHeight];
}


- (NSInteger)iconSize {
	return iconSize;
}

- (NSArray *)itemsAtRowIndexes:(NSIndexSet *)rowIndexes {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSMutableArray *items = [NSMutableArray array];
	NSUInteger index = [rowIndexes firstIndex];
	while (index != NSNotFound) {
		id item = [self itemAtRow:index];
		if (item) [items addObject:item];
		index = [rowIndexes indexGreaterThanIndex:index];
	}
	return [[items copy] autorelease];
}



- (NSIndexSet *)rowIndexesForItems:(NSArray *)items {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSMutableIndexSet *rowIndexes = [NSMutableIndexSet indexSet];
	for (id item in items) {
		NSInteger index = [self rowForItem:item];
		if (index >= 0) {
			[rowIndexes addIndex:(NSUInteger)index];
		}
	}
	return [[rowIndexes copy] autorelease];
}



- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
//	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	SEL action = [menuItem action];
	if (action == @selector(revealInFinder:)) {
		return ([self numberOfSelectedRows] > 0 && [self numberOfSelectedRows] < 20);
		
	} else if (action == @selector(toggleShowInspector:)) {
		return NO;
	} else {
		return YES;
	}
	return YES;
}


- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	return YES;
}

- (void)keyDown:(NSEvent *)theEvent {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSString *characters = [theEvent characters];
	if ([characters isEqualToString:@" "]) {
		if ([[self dataSource] respondsToSelector:@selector(toggleShowQuickLook:)]) {
			[(MDHLDocument *)[self dataSource] toggleShowQuickLook:self];
		}
	} else {
		[super keyDown:theEvent];
	}
}

- (void)rightMouseDown:(NSEvent *)event {
#if MD_DEBUG
		NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSPoint clickPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	
	NSInteger rowIndex		= [self rowAtPoint:clickPoint];
	
	NSIndexSet *selectedRowIndexes = [self selectedRowIndexes];
	if (rowIndex >= 0) {
		if ([selectedRowIndexes containsIndex:rowIndex]) {
			return [super rightMouseDown:event];
		} else {
			[self selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
			return [super rightMouseDown:event];
		}
	} else {
		if ([selectedRowIndexes count]) {
			[self deselectAll:self];
			return [super rightMouseDown:event];
		}
	}
	return [super rightMouseDown:event];
	
	/*** actually, what's happening I think is that if I have multiple items selected and I right click, do I de-select the current selection and only select the single row, or do I keep the whole selection and call super? */
	
}


- (void)mouseDown:(NSEvent *)event {
#if MD_DEBUG
		NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSUInteger modifierFlags = [event modifierFlags];
	
	if (modifierFlags & NSAlternateKeyMask || modifierFlags & NSCommandKeyMask) {
		
		return [super mouseDown:event];
		
	} else if (modifierFlags & NSControlKeyMask) {
		
		NSInteger rowIndex = [self rowAtPoint:[self convertPoint:[event locationInWindow] fromView:nil]];
		
		NSIndexSet *selectedRowIndexes = [self selectedRowIndexes];
		
		if (rowIndex >= 0) {
			if ([selectedRowIndexes containsIndex:rowIndex]) {
				return [super mouseDown:event];
			} else {
				[self selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
				return [super mouseDown:event];
			}
		} else {
			if ([selectedRowIndexes count]) {
				[self deselectAll:self];
				return [super mouseDown:event];
			}
		}
		
	}
	return [super mouseDown:event];
}


#pragma mark -
#pragma mark NSDraggingSource



/*************************************** NSDraggingSource protocol methods [ SOURCE ] ***********************************************************/


- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return NSDragOperationCopy;
}



// use the following method to remove the data from the drag source. (as in dragging to the Trash)

- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation {
#if MD_DEBUG
		NSLog(@" \"%@\" [%@ %@] forwarding to MDHLDocument...", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([[self delegate] respondsToSelector:@selector(draggedImage:endedAt:operation:)]) {
		[(MDHLDocument *)[self delegate] draggedImage:image endedAt:screenPoint operation:operation];
	}
	[super draggedImage:image endedAt:screenPoint operation:operation];
}

#pragma mark NSDraggingSource


@end


