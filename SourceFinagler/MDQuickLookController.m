//
//  MDQuickLookController.m
//  Source Finagler
//
//  Created by Mark Douma on 2/24/2009.
//  Copyright 2009 Mark Douma. All rights reserved.
//

#import "MDQuickLookController.h"
#import "MDHLDocument.h"
#import <HLKit/HLKit.h>
#import <CoreServices/CoreServices.h>
#import "MDQuickLookPreviewViewController.h"
#import "MDAppKitAdditions.h"


#define MD_DEBUG 0


@interface MDQuickLookController (MDPrivate)
- (void)updateUI;
@end



static MDQuickLookController *sharedQuickLookController = nil;


@implementation MDQuickLookController


@synthesize items;
@synthesize document;


+ (MDQuickLookController *)sharedQuickLookController {
	@synchronized(self) {
		if (sharedQuickLookController == nil) {
			sharedQuickLookController = [[super allocWithZone:NULL] init];
		}
	}
	return sharedQuickLookController;
}

+ (id)allocWithZone:(NSZone *)zone {
	return [[self sharedQuickLookController] retain];
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

- (id)init {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithWindowNibName:@"MDQuickLook"])) {
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedItemsDidChange:) name:MDHLDocumentSelectedItemsDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentWillClose:) name:MDHLDocumentWillCloseNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
	
	} else {
		[NSBundle runFailedNibLoadAlert:@"MDQuickLoook"];
	}
	return self;
}

- (id)retain {
	return self;
}

- (NSUInteger)retainCount {
	return NSUIntegerMax; //denotes an object that cannot be released
}

- (oneway void)release {
	// do nothing
}

- (id)autorelease {
	return self;
}


- (void)windowDidLoad {
#if MD_DEBUG
	BOOL floats = [[self window] isFloatingPanel];
	NSLog(@"[%@ %@] isFloatingPanel == %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), floats);
#endif
	
}


- (void)showWindowByAnimatingFromStartFrame:(NSRect)startFrame toEndFrame:(NSRect)endFrame {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSDictionary *firstDict = [NSDictionary dictionaryWithObjectsAndKeys:[self window],NSViewAnimationTargetKey, 
							   [NSValue valueWithRect:startFrame],NSViewAnimationStartFrameKey,
							   [NSValue valueWithRect:endFrame],NSViewAnimationEndFrameKey, 
							   NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, nil];
	NSViewAnimation *windowAnimation = [[[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:firstDict]] autorelease];
	[windowAnimation startAnimation];
	
}


- (void)updateUI {
#if MD_DEBUG
//    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (document == nil) {
		[[self window] setTitle:@""];
		
		[previewViewController setRepresentedObject:nil];
		[controlsView setHidden:YES];
		
	} else {
		
		if (items.count == 0) {
			[[self window] setTitle:[document displayName]];
			
			[previewViewController setRepresentedObject:document];
			[controlsView setHidden:YES];
			
		} else {
			HKItem *item = [items objectAtIndex:currentItemIndex];
			[[self window] setTitle:[item name]];
			[previewViewController setRepresentedObject:item];
			
			[controlsView setHidden:(items.count == 1)];
			
		}
	}
}



- (IBAction)showPreviousItem:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (currentItemIndex == 0) {
		currentItemIndex = [items count] - 1;
	} else {
		currentItemIndex--;
	}
	[self updateUI];
}


- (IBAction)showNextItem:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (currentItemIndex + 1 >= [items count]) {
		currentItemIndex = 0;
	} else {
		currentItemIndex++;
	}
	[self updateUI];
}


- (IBAction)playPause:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	isPlaying = !isPlaying;
	
	if (isPlaying) {
		
	} else {
		
	}
}



- (void)selectedItemsDidChange:(NSNotification *)notification {
#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	NSLog(@"[%@ %@] notification == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), notification);
#endif
	
	// if we're not showing Quick Look, ignore the notification
	
	if ([MDHLDocument shouldShowQuickLook] == NO) return;
	
	self.document = [notification object];
	self.items = document.selectedItems;
	
	currentItemIndex = 0;
	
	[self updateUI];
}



- (void)documentWillClose:(NSNotification *)notification {
#if MD_DEBUG
//    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	NSLog(@"[%@ %@] notification == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), notification);
#endif
	
	/*
	 When an MDHLDocument is closed, it posts this notification with itself as the object.
	 If the notification's object is the same document as our currently retained document, 
	 then we need to make sure to release our document, as well as the selected items,
	 so that the document can be properly deallocated. */
	
	MDHLDocument *closingDocument = [notification object];
	
	if (document == closingDocument) {
		
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
			self.document = [orderedDocuments objectAtIndex:0];
			self.items = document.selectedItems;
			
		} else {
			// no documents left
			// let go!
			self.document = nil;
			self.items = nil;
			
		}
		
		currentItemIndex = 0;
		[self updateUI];
	}
}



- (void)applicationWillTerminate:(NSNotification *)notification {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	appIsTerminating = YES;
}


- (IBAction)showWindow:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[[self window] orderFront:nil];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[MDHLDocument shouldShowQuickLook]] forKey:MDHLDocumentShouldShowQuickLookKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:MDHLDocumentShouldShowQuickLookDidChangeNotification object:self userInfo:nil];
}


- (void)windowWillClose:(NSNotification *)notification {
	
	if ([notification object] == [self window] && appIsTerminating == NO) {
#if MD_DEBUG
		NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		[MDHLDocument setShouldShowQuickLook:NO];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[MDHLDocument shouldShowQuickLook]] forKey:MDHLDocumentShouldShowQuickLookKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:MDHLDocumentShouldShowQuickLookDidChangeNotification object:self userInfo:nil];
	}
}



@end

