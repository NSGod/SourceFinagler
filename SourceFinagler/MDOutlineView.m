//
//  MDOutlineView.m
//  Source Finagler
//
//  Created by Mark Douma on 4/16/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDOutlineView.h"
#import "MDHLDocument.h"
#import "MDFileSizeFormatter.h"
#import "MDUserDefaults.h"



static NSString * const MDFinderBundleIdentifierKey					= @"com.apple.finder";


NSString * const MDOutlineViewShouldShowKindColumnKey				= @"MDOutlineViewShouldShowKindColumn";
NSString * const MDOutlineViewShouldShowSizeColumnKey				= @"MDOutlineViewShouldShowSizeColumn";

NSString * const MDOutlineViewIconSizeKey							= @"MDOutlineViewIconSize";
NSString * const MDOutlineViewFontSizeKey							= @"MDOutlineViewFontSize";



@interface MDOutlineView (MDPrivate)
- (void)calculateRowHeight;
@end


#define MD_DEBUG 0
#define MD_DEBUG_TABLE_COLUMNS 0


#define MD_DEFAULT_FONT_SIZE 12
#define MD_DEFAULT_ICON_SIZE 16



@implementation MDOutlineView


+ (void)initialize {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	static BOOL initialized = NO;
	
	@synchronized(self) {
		
		if (initialized == NO) {
			
			NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
			[defaults setObject:[NSNumber numberWithBool:YES] forKey:MDOutlineViewShouldShowKindColumnKey];
			[defaults setObject:[NSNumber numberWithBool:YES] forKey:MDOutlineViewShouldShowSizeColumnKey];
			
			MDUserDefaults *userDefaults = [MDUserDefaults standardUserDefaults];
			
			NSNumber *finderListViewFontSize = [[[userDefaults objectForKey:@"StandardViewOptions" forAppIdentifier:MDFinderBundleIdentifierKey inDomain:MDUserDefaultsUserDomain] objectForKey:@"ListViewOptions"] objectForKey:@"FontSize"];
			NSNumber *finderListViewIconSize = [[[userDefaults objectForKey:@"StandardViewOptions" forAppIdentifier:MDFinderBundleIdentifierKey inDomain:MDUserDefaultsUserDomain] objectForKey:@"ListViewOptions"] objectForKey:@"IconSize"];
			
			if (finderListViewFontSize) {
				[defaults setObject:finderListViewFontSize forKey:MDOutlineViewFontSizeKey];
			} else {
				[defaults setObject:[NSNumber numberWithInteger:MD_DEFAULT_FONT_SIZE] forKey:MDOutlineViewFontSizeKey];
			}
			
			if (finderListViewIconSize) {
				[defaults setObject:finderListViewIconSize forKey:MDOutlineViewIconSizeKey];
			} else {
				[defaults setObject:[NSNumber numberWithInteger:MD_DEFAULT_ICON_SIZE] forKey:MDOutlineViewIconSizeKey];
			}
			
			[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
			[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaults];
			
			initialized = YES;
		}
	}
}


- (void)dealloc {
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
#if MD_DEBUG_TABLE_COLUMNS
	NSArray *tableColumns = self.tableColumns;
	NSArray *sortDescriptors = self.sortDescriptors;
	NSLog(@"[%@ %@] (CLOSING) tableColumns == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tableColumns);
	NSLog(@"[%@ %@] (CLOSING) sortDescriptors == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sortDescriptors);
#endif
	
	[kindColumn release];
	[sizeColumn release];
	
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[NSString stringWithFormat:@"defaults.%@", MDOutlineViewFontSizeKey]];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[NSString stringWithFormat:@"defaults.%@", MDOutlineViewIconSizeKey]];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[NSString stringWithFormat:@"defaults.%@", MDOutlineViewShouldShowKindColumnKey]];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[NSString stringWithFormat:@"defaults.%@", MDOutlineViewShouldShowSizeColumnKey]];
	
	[super dealloc];
}


- (void)awakeFromNib {
#if MD_DEBUG
//    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif

	[[sizeColumn dataCell] setFormatter:[[[MDFileSizeFormatter alloc] initWithUnitsType:MDFileSizeFormatterAutomaticUnitsType
																				  style:MDFileSizeFormatterPhysicalStyle] autorelease]];
	
	/* The following code is a hack to workaround a bug (or at least what seems to be a bug to me)
	 in OS X 10.9 that causes outline view columns to be restored in incorrect order. */

	NSArray *tableColumns = self.tableColumns;
	
#if MD_DEBUG_TABLE_COLUMNS
	NSLog(@"[%@ %@] (OPENING) tableColumns == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tableColumns);
	NSArray *sortDescriptors = self.sortDescriptors;
	NSLog(@"[%@ %@] (OPENING) sortDescriptors == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sortDescriptors);
#endif
	
	if (tableColumns.count >= 3 && [tableColumns objectAtIndex:0] != nameColumn) {
		
		NSLog(@"[%@ %@] NOTICE: rearranging table columns; prior tableColumns == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tableColumns);
		
		NSInteger currentNameColumnIndex = [self columnWithIdentifier:[nameColumn identifier]];
		if (currentNameColumnIndex != -1) {
			[self moveColumn:currentNameColumnIndex toColumn:0];
		}
	}
	
	// from controllers
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	fontSize = [[userDefaults objectForKey:MDOutlineViewFontSizeKey] integerValue];
	iconSize = [[userDefaults objectForKey:MDOutlineViewIconSizeKey] integerValue];
	[self calculateRowHeight];
	
	[[nameColumn dataCell] setFont:[NSFont systemFontOfSize:(CGFloat)fontSize]];
	[[sizeColumn dataCell] setFont:[NSFont systemFontOfSize:(CGFloat)fontSize]];
	[[kindColumn dataCell] setFont:[NSFont systemFontOfSize:(CGFloat)fontSize]];
	
	[kindColumn retain];
	[sizeColumn retain];

	shouldShowKindColumn = [[userDefaults objectForKey:MDOutlineViewShouldShowKindColumnKey] boolValue];
	if (!shouldShowKindColumn) [self removeTableColumn:kindColumn];
	
	shouldShowSizeColumn = [[userDefaults objectForKey:MDOutlineViewShouldShowSizeColumnKey] boolValue];
	if (!shouldShowSizeColumn) [self removeTableColumn:sizeColumn];
	
	[self setVerticalMotionCanBeginDrag:NO];
	
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[NSString stringWithFormat:@"defaults.%@", MDOutlineViewFontSizeKey]
																 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[NSString stringWithFormat:@"defaults.%@", MDOutlineViewIconSizeKey]
																 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[NSString stringWithFormat:@"defaults.%@", MDOutlineViewShouldShowKindColumnKey]
																 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[NSString stringWithFormat:@"defaults.%@", MDOutlineViewShouldShowSizeColumnKey]
																 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
	
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
#if MD_DEBUG
	NSLog(@"[%@ %@] keyPath == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), keyPath);
#endif
	
	if ([keyPath isEqualToString:[NSString stringWithFormat:@"defaults.%@", MDOutlineViewFontSizeKey]]) {
		
		fontSize = [[[NSUserDefaults standardUserDefaults] objectForKey:MDOutlineViewFontSizeKey] integerValue];
		[self calculateRowHeight];
		
		[[nameColumn dataCell] setFont:[NSFont systemFontOfSize:(CGFloat)fontSize]];
		[[sizeColumn dataCell] setFont:[NSFont systemFontOfSize:(CGFloat)fontSize]];
		[[kindColumn dataCell] setFont:[NSFont systemFontOfSize:(CGFloat)fontSize]];
		
		[self reloadData];
		
	} else if ([keyPath isEqualToString:[NSString stringWithFormat:@"defaults.%@", MDOutlineViewIconSizeKey]]) {
		
		iconSize = [[[NSUserDefaults standardUserDefaults] objectForKey:MDOutlineViewIconSizeKey] integerValue];
		[self calculateRowHeight];
		[self reloadData];
		
	} else if ([keyPath isEqualToString:[NSString stringWithFormat:@"defaults.%@", MDOutlineViewShouldShowKindColumnKey]]) {
		
		shouldShowKindColumn = [[[NSUserDefaults standardUserDefaults] objectForKey:MDOutlineViewShouldShowKindColumnKey] boolValue];
		(shouldShowKindColumn ? [self addTableColumn:kindColumn] : [self removeTableColumn:kindColumn]);
		[self reloadData];
		
	} else if ([keyPath isEqualToString:[NSString stringWithFormat:@"defaults.%@", MDOutlineViewShouldShowSizeColumnKey]]) {
		
		shouldShowSizeColumn = [[[NSUserDefaults standardUserDefaults] objectForKey:MDOutlineViewShouldShowSizeColumnKey] boolValue];
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


- (void)addTableColumn:(NSTableColumn *)tableColumn {
#if MD_DEBUG_TABLE_COLUMNS
	NSLog(@"[%@ %@] tableColumn == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tableColumn);
#endif
	[super addTableColumn:tableColumn];
}


- (void)removeTableColumn:(NSTableColumn *)tableColumn {
#if MD_DEBUG_TABLE_COLUMNS
	NSLog(@"[%@ %@] tableColumn == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tableColumn);
#endif
	[super removeTableColumn:tableColumn];
}


- (void)moveColumn:(NSInteger)oldIndex toColumn:(NSInteger)newIndex {
#if MD_DEBUG_TABLE_COLUMNS
	NSLog(@"[%@ %@] oldIndex == %ld, newIndex == %ld", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (long)oldIndex, (long)newIndex);
#endif
	[super moveColumn:oldIndex toColumn:newIndex];
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
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
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
//	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSPoint clickPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	
	NSInteger rowIndex = [self rowAtPoint:clickPoint];
	
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
//	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
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


#pragma mark - <NSDraggingSource>



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

#pragma mark END <NSDraggingSource>

@end


