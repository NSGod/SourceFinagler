//
//  MDViewOptionsController.m
//  Source Finagler
//
//  Created by Mark Douma on 1/29/2008.
//  Copyright © 2008 Mark Douma. All rights reserved.
//


#import "MDViewOptionsController.h"
#import "MDAppController.h"
#import "MDOutlineView.h"
#import "MDBrowser.h"
#import "MDAppKitAdditions.h"


#pragma mark controller
#define MD_DEBUG 0



@interface MDViewOptionsController (MDPrivate)
- (void)updateUIWithDocument:(MDHLDocument *)document;
@end


@implementation MDViewOptionsController

- (id)init {
	if ((self = [super initWithWindowNibName:@"MDViewOptions"])) {
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewModeDidChange:) name:MDHLDocumentViewModeDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentWillClose:) name:MDHLDocumentWillCloseNotification object:nil];

	} else {
		[NSBundle runFailedNibLoadAlert:@"MDViewOptions"];
	}
	return self;
}


- (void)dealloc {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


- (void)awakeFromNib {
	viewMode = [[[NSUserDefaults standardUserDefaults] objectForKey:MDHLDocumentViewModeKey] integerValue];
	
	[[[self window] standardWindowButton:NSWindowZoomButton] setHidden:YES];
	[[[self window] standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
	[(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];
	
	[self updateUIWithDocument:nil];
}


- (void)updateUIWithDocument:(MDHLDocument *)document {
#if MD_DEBUG
//    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (document == nil) {
		[[self window] setTitle:NSLocalizedString(@"View Options", @"")];
		[noViewOptionsField setStringValue:NSLocalizedString(@"No document", @"")];
		[contentBox setContentView:noViewOptionsView];
		
	} else {
		viewMode = document.viewMode;
		
		if (viewMode == MDHLDocumentNoViewMode) {
			[noViewOptionsField setStringValue:NSLocalizedString(@"There are no view options for this document.", @"")];
			[contentBox setContentView:noViewOptionsView];
		} else if (viewMode == MDHLDocumentListViewMode) {
			[contentBox setContentView:listViewOptionsView];
		} else if (viewMode == MDHLDocumentColumnViewMode) {
			[contentBox setContentView:browserViewOptionsView];
		}
		
		if (document.displayName) {
			[[self window] setTitle:document.displayName];
		} else {
			[[self window] setTitle:NSLocalizedString(@"View Options", @"")];
		}
	}
}


- (void)viewModeDidChange:(NSNotification *)notification {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[self updateUIWithDocument:[notification object]];
}


- (void)documentWillClose:(NSNotification *)notification {
#if MD_DEBUG
//    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	NSLog(@"[%@ %@] notification == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), notification);
#endif
	
	MDHLDocument *closingDocument = [notification object];
	
	/* If a document is closing, and it's the document we're currently showing data for,
	 find the next appropriate document to show data for. This is intended for instances where 
	 an MDHLDocument is closed in the background while another non-document window is currently
	 the main window -- in which case there may be no other MDHLDocument that will become 
	 the main window (which is how we get notifications that the user has switched documents). */
	
	/* It's possible that orderedDocuments might be in the wrong order, so we'll remove
	 the closing document from the array, and then use the first of the remaining documents
	 that is found. */
	
	NSMutableArray *orderedDocuments = [[[MDHLDocument orderedDocuments] mutableCopy] autorelease];
	[orderedDocuments removeObject:closingDocument];
	
	if (orderedDocuments.count) {
		[self updateUIWithDocument:[orderedDocuments objectAtIndex:0]];
		
	} else {
		// no documents left
		[self updateUIWithDocument:nil];
	}
	
}



- (IBAction)showWindow:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[[self window] orderFront:nil];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:MDShouldShowViewOptions] forKey:MDHLDocumentShouldShowViewOptionsKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:MDHLDocumentShouldShowViewOptionsDidChangeNotification object:self userInfo:nil];
}


- (void)windowWillClose:(NSNotification *)notification {
	
	if ([notification object] == [self window]) {
#if MD_DEBUG
		NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		MDShouldShowViewOptions = NO;
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:MDShouldShowViewOptions] forKey:MDHLDocumentShouldShowViewOptionsKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:MDHLDocumentShouldShowViewOptionsDidChangeNotification object:self userInfo:nil];
	}
}



- (IBAction)changeListViewIconSize:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:[sender tag]] forKey:MDOutlineViewIconSizeKey];
}


@end

