//
//  MDBrowser.m
//  Source Finagler
//
//  Created by Mark Douma on 2/5/2008.
//  Copyright © 2008 Mark Douma. All rights reserved.
//



#import "MDBrowser.h"
#import "MDBrowserCell.h"
#import "MDHLDocument.h"
#import "MDUserDefaults.h"



static NSString * const MDFinderBundleIdentifierKey				= @"com.apple.finder";


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
static const NSUInteger MDBrowserSortOptionMappingTableCount = sizeof(MDBrowserSortOptionMappingTable)/sizeof(MDBrowserSortOptionMappingTable[0]);

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
- (void)finishSetup;
@end



#pragma mark view
#define MD_DEBUG 0



#define MD_DEFAULT_BROWSER_FONT_AND_ICON_SIZE 13



@implementation MDBrowser


@synthesize sortDescriptors;
@synthesize shouldShowIcons;
@synthesize shouldShowPreview;


+ (void)initialize {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	static BOOL initialized = NO;
	
	if (initialized == NO) {
		NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
		
		NSNumber *finderColumnViewFontAndIconSize = [[[[MDUserDefaults standardUserDefaults] objectForKey:@"StandardViewOptions" forAppIdentifier:MDFinderBundleIdentifierKey inDomain:MDUserDefaultsUserDomain] objectForKey:@"ColumnViewOptions"] objectForKey:@"FontSize"];
		
		if (finderColumnViewFontAndIconSize) {
			[defaults setObject:finderColumnViewFontAndIconSize forKey:MDBrowserFontAndIconSizeKey];
		} else {
			[defaults setObject:[NSNumber numberWithInteger:MD_DEFAULT_BROWSER_FONT_AND_ICON_SIZE] forKey:MDBrowserFontAndIconSizeKey];
		}
		
		[defaults setObject:[NSNumber numberWithBool:YES] forKey:MDBrowserShouldShowIconsKey];
		[defaults setObject:[NSNumber numberWithBool:YES] forKey:MDBrowserShouldShowPreviewKey];
		
		[defaults setObject:[NSNumber numberWithInteger:MDBrowserSortByName] forKey:MDBrowserSortByKey];
		
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
		[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaults];
		
		initialized = YES;
	}
}


- (id)initWithFrame:(NSRect)frameRect {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithFrame:frameRect])) {
		[self finishSetup];
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)coder {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithCoder:coder])) {
		[self finishSetup];
	}
	return self;
}


- (void)finishSetup {
	fontAndIconSize = [[[NSUserDefaults standardUserDefaults] objectForKey:MDBrowserFontAndIconSizeKey] intValue];
	shouldShowIcons = [[[NSUserDefaults standardUserDefaults] objectForKey:MDBrowserShouldShowIconsKey] boolValue];
	shouldShowPreview = [[[NSUserDefaults standardUserDefaults] objectForKey:MDBrowserShouldShowPreviewKey] boolValue];
	NSInteger sortByOption = [[[NSUserDefaults standardUserDefaults] objectForKey:MDBrowserSortByKey] intValue];
	[self setSortDescriptors:MDSortDescriptorsFromSortOption(sortByOption)];
}



- (void)dealloc {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[sortDescriptors release];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[NSString stringWithFormat:@"defaults.%@", MDBrowserFontAndIconSizeKey]];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[NSString stringWithFormat:@"defaults.%@", MDBrowserShouldShowIconsKey]];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[NSString stringWithFormat:@"defaults.%@", MDBrowserShouldShowPreviewKey]];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[NSString stringWithFormat:@"defaults.%@", MDBrowserSortByKey]];
	[super dealloc];
}


- (void)awakeFromNib {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[NSString stringWithFormat:@"defaults.%@", MDBrowserFontAndIconSizeKey]
																 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[NSString stringWithFormat:@"defaults.%@", MDBrowserShouldShowIconsKey]
																 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[NSString stringWithFormat:@"defaults.%@", MDBrowserShouldShowPreviewKey]
																 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[NSString stringWithFormat:@"defaults.%@", MDBrowserSortByKey]
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
	if ([keyPath isEqualToString:[NSString stringWithFormat:@"defaults.%@", MDBrowserFontAndIconSizeKey]]) {
		fontAndIconSize = [[[NSUserDefaults standardUserDefaults] objectForKey:MDBrowserFontAndIconSizeKey] integerValue];
		[self calculateRowHeight];
		
	} else if ([keyPath isEqualToString:[NSString stringWithFormat:@"defaults.%@", MDBrowserShouldShowIconsKey]]) {
		shouldShowIcons = [[[NSUserDefaults standardUserDefaults] objectForKey:MDBrowserShouldShowIconsKey] boolValue];
		[self reloadData];
		
	} else if ([keyPath isEqualToString:[NSString stringWithFormat:@"defaults.%@", MDBrowserShouldShowPreviewKey]]) {
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
		
	} else if ([keyPath isEqualToString:[NSString stringWithFormat:@"defaults.%@", MDBrowserSortByKey]]) {
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

/* used by document when switching from column view to list view */
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
	NSInteger clickedColumn = [self clickedColumn];
	NSInteger clickedRow = [self clickedRow];
	NSLog(@"[%@ %@] clickedColumn == %ld, clickedRow == %ld", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (long)clickedColumn, (long)clickedRow);
#endif
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
#if MD_DEBUG
		NSInteger clickedColumn = [self clickedColumn];
		NSInteger clickedRow = [self clickedRow];
		NSLog(@"[%@ %@] clickedColumn == %ld, clickedRow == %ld", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (long)clickedColumn, (long)clickedRow);
#endif
	}
	[super mouseDown:event];
}


@end


