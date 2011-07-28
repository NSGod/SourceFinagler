//
//  MDBrowser.m
//  Source Finagler
//
//  Created by Mark Douma on 2/5/2008.
//  Copyright © 2008 Mark Douma. All rights reserved.
//



#import "MDBrowser.h"
#import "MDBrowserCell.h"
#import "MDAppKitAdditions.h"
#import "MDHLDocument.h"

#pragma mark view
#define MD_DEBUG 0


NSString * const MDBrowserSelectionDidChangeNotification		= @"MDBrowserSelectionDidChange";
NSString * const MDBrowserFontAndIconSizeKey					= @"MDBrowserFontAndIconSize";
NSString * const MDBrowserShouldShowIconsKey					= @"MDBrowserShouldShowIcons";
NSString * const MDBrowserShouldShowPreviewKey					= @"MDBrowserShouldShowPreview";
NSString * const MDBrowserSortByKey								= @"MDBrowserSortBy";


typedef struct MDBrowserSortOptionMapping {
	NSInteger	sortOption;
	NSString	*key;
	NSString	*selectorName;
} MDBrowserSortOptionMapping;

static MDBrowserSortOptionMapping MDBrowserSortOptionMappingTable[] = {
	{ MDBrowserSortByName, @"name", @"caseInsensitiveNumericalCompare:" },
	{ MDBrowserSortBySize, @"size", @"compare:" },
	{ MDBrowserSortByKind, @"kind", @"caseInsensitiveCompare:" }
};
static const NSUInteger MDBrowserSortOptionMappingTableCount = sizeof(MDBrowserSortOptionMappingTable)/sizeof(MDBrowserSortOptionMapping);

static inline NSArray *MDSortDescriptorsFromSortOption(NSInteger sortOption) {
	for (NSUInteger i = 0; i < MDBrowserSortOptionMappingTableCount; i++) {
		if (MDBrowserSortOptionMappingTable[i].sortOption == sortOption) {
			return [NSArray arrayWithObjects:
					[[[NSSortDescriptor alloc] initWithKey:MDBrowserSortOptionMappingTable[i].key
												 ascending:YES
												  selector:NSSelectorFromString(MDBrowserSortOptionMappingTable[i].selectorName)] autorelease], nil];
		}
	}
	return nil;
}


@interface MDBrowser (MDPrivate)
- (void)calculateRowHeight;
@end


@implementation MDBrowser

@synthesize sortDescriptors, shouldShowIcons, shouldShowPreview;


- (id)initWithFrame:(NSRect)frameRect {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithFrame:frameRect])) {
		fontAndIconSize = [[[NSUserDefaults standardUserDefaults] objectForKey:MDBrowserFontAndIconSizeKey] intValue];
		shouldShowIcons = [[[NSUserDefaults standardUserDefaults] objectForKey:MDBrowserShouldShowIconsKey] boolValue];
		shouldShowPreview = [[[NSUserDefaults standardUserDefaults] objectForKey:MDBrowserShouldShowPreviewKey] boolValue];
		NSInteger sortByOption = [[[NSUserDefaults standardUserDefaults] objectForKey:MDBrowserSortByKey] intValue];
		[self setSortDescriptors:MDSortDescriptorsFromSortOption(sortByOption)];
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)coder {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if ((self = [super initWithCoder:coder])) {
		fontAndIconSize = [[[NSUserDefaults standardUserDefaults] objectForKey:MDBrowserFontAndIconSizeKey] intValue];
		shouldShowIcons = [[[NSUserDefaults standardUserDefaults] objectForKey:MDBrowserShouldShowIconsKey] boolValue];
		shouldShowPreview = [[[NSUserDefaults standardUserDefaults] objectForKey:MDBrowserShouldShowPreviewKey] boolValue];
		NSInteger sortByOption = [[[NSUserDefaults standardUserDefaults] objectForKey:MDBrowserSortByKey] intValue];
		[self setSortDescriptors:MDSortDescriptorsFromSortOption(sortByOption)];
	}
	return self;
}


- (void)dealloc {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[sortDescriptors release];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:NSStringFromDefaultsKeyPath(MDBrowserFontAndIconSizeKey)];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:NSStringFromDefaultsKeyPath(MDBrowserShouldShowIconsKey)];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:NSStringFromDefaultsKeyPath(MDBrowserShouldShowPreviewKey)];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:NSStringFromDefaultsKeyPath(MDBrowserSortByKey)];
	[super dealloc];
}


- (void)awakeFromNib {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:NSStringFromDefaultsKeyPath(MDBrowserFontAndIconSizeKey)
																 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:NSStringFromDefaultsKeyPath(MDBrowserShouldShowIconsKey)
																 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:NSStringFromDefaultsKeyPath(MDBrowserShouldShowPreviewKey)
																 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:NSStringFromDefaultsKeyPath(MDBrowserSortByKey)
																 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
	
	[self setCellClass:[MDBrowserCell class]];
	
	[self calculateRowHeight];
	[self setAutohidesScroller:YES];

#if MD_DEBUG
//	NSView *superView = [self superview];
//	NSLog(@" \"%@\" [%@ %@] superView == %@", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd), superView);
#endif

}



- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([keyPath isEqualToString:NSStringFromDefaultsKeyPath(MDBrowserFontAndIconSizeKey)]) {
		fontAndIconSize = [[[NSUserDefaults standardUserDefaults] objectForKey:MDBrowserFontAndIconSizeKey] integerValue];
		[self calculateRowHeight];
		
	} else if ([keyPath isEqualToString:NSStringFromDefaultsKeyPath(MDBrowserShouldShowIconsKey)]) {
		shouldShowIcons = [[[NSUserDefaults standardUserDefaults] objectForKey:MDBrowserShouldShowIconsKey] boolValue];
		[self reloadData];
		
	} else if ([keyPath isEqualToString:NSStringFromDefaultsKeyPath(MDBrowserShouldShowPreviewKey)]) {
		shouldShowPreview = [[[NSUserDefaults standardUserDefaults] objectForKey:MDBrowserShouldShowPreviewKey] boolValue];

		NSInteger selectedColumn = [self selectedColumn];
		
		if (selectedColumn != -1) {
			NSIndexSet *selectedRowIndexes = [[[self selectedRowIndexesInColumn:selectedColumn] retain] autorelease];
			[self reloadData];
			if ([selectedRowIndexes count] == 1) {
				[self selectRowIndexes:[NSIndexSet indexSet] inColumn:selectedColumn];
				[self selectRowIndexes:selectedRowIndexes inColumn:selectedColumn];
			}
		}
		
	} else if ([keyPath isEqualToString:NSStringFromDefaultsKeyPath(MDBrowserSortByKey)]) {
		NSInteger sortByOption = [[[NSUserDefaults standardUserDefaults] objectForKey:MDBrowserSortByKey] integerValue];
		[self setSortDescriptors:MDSortDescriptorsFromSortOption(sortByOption)];
		if ([[self delegate] respondsToSelector:@selector(browser:sortDescriptorsDidChange:)]) {
			[(id)[self delegate] browser:self sortDescriptorsDidChange:nil];
		}
	} else {
		if ([super respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:)]) {
			// be sure to call the super implementation
			// if the superclass implements it
			[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
		}
	}
}


- (void)calculateRowHeight {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	CGFloat newHeight = (CGFloat)((CGFloat)fontAndIconSize + 5.0);
	[self setRowHeight:newHeight];
}


- (NSArray *)itemsAtRowIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)columnIndex {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSMutableArray *items = [NSMutableArray array];
	
	NSUInteger index = [rowIndexes firstIndex];
	
	while (index != NSNotFound) {
		id item = [self itemAtRow:index inColumn:columnIndex];
		if (item) [items addObject:item];
		index = [rowIndexes indexGreaterThanIndex:index];
	}
	return [[items copy] autorelease];
}


- (void)reloadData {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (![self isLoaded]) {
		[self loadColumnZero];
		return;
	}
	NSInteger lastVisibleColumn = [self lastVisibleColumn];
	
	for (NSUInteger i = 0; i <= lastVisibleColumn; i++) {
		[self reloadColumn:i];
	}
}
	

- (NSInteger)fontAndIconSize {
	return fontAndIconSize;
}

/* used by MDFontSuitcase when switching from column view to list view */
- (IBAction)deselectAll:(id)sender {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if ([[self selectedRowIndexesInColumn:0] count]) {
		[self selectRowIndexes:[NSIndexSet indexSet] inColumn:0];
	}
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [super acceptsFirstMouse:theEvent];
}


- (void)selectRowIndexes:(NSIndexSet *)indexes inColumn:(NSInteger)columnIndex {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSIndexSet *selectedRowIndexes = [[[self selectedRowIndexesInColumn:columnIndex] retain] autorelease];
	
	[super selectRowIndexes:indexes inColumn:columnIndex];
	
	if (![indexes isEqualToIndexSet:selectedRowIndexes]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:MDBrowserSelectionDidChangeNotification object:self userInfo:nil];
	}
}


- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return NSDragOperationCopy | NSDragOperationGeneric;
}



#pragma mark NSDraggingSource
#pragma mark -


enum {
	MDEscapeKey		= 0x35
};

- (void)keyDown:(NSEvent *)event {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSString *characters = [event characters];
	unsigned short keyCode = [event keyCode];
	
	if ([characters isEqualToString:@" "]) {
		[(MDHLDocument *)[self delegate] toggleShowQuickLook:self];
		
	} else if (keyCode == MDEscapeKey) {
		
		[self deselectAll:nil];
		
	} else {
		[super keyDown:event];
	}
}


- (void)rightMouseDown:(NSEvent *)event {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSInteger clickedColumn = [self clickedColumn];
	NSInteger clickedRow = [self clickedRow];
	
	NSLog(@"[%@ %@] clickedColumn == %ld, clickedRow == %ld", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (long)clickedColumn, (long)clickedRow);
	
	[super rightMouseDown:event];
}


- (void)mouseDown:(NSEvent *)event {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSUInteger modifierFlags = [event modifierFlags];
	
	if (modifierFlags & NSAlternateKeyMask || modifierFlags & NSCommandKeyMask) {
		return [super mouseDown:event];
	} else if (modifierFlags & NSControlKeyMask) {
		NSInteger clickedColumn = [self clickedColumn];
		NSInteger clickedRow = [self clickedRow];
		
		NSLog(@"[%@ %@] clickedColumn == %ld, clickedRow == %ld", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (long)clickedColumn, (long)clickedRow);
		
	}
	[super mouseDown:event];
}


@end


