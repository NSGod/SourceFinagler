//
//  MDQuickLookController.m
//  Source Finagler
//
//  Created by Mark Douma on 2/24/2009.
//  Copyright 2009 Mark Douma. All rights reserved.
//

#import "MDQuickLookController.h"
#import "MDAppController.h"
#import "MDHLDocument.h"

#import <HLKit/HLKit.h>

#import <CoreServices/CoreServices.h>
#import "MDQuickLookPreviewViewController.h"
#import "MDAppKitAdditions.h"


//#define MD_DEBUG 1
#define MD_DEBUG 0


NSString * const MDQuickLookStartFrameKey	= @"MDQuickLookStartFrame";
NSString * const MDQuickLookEndFrameKey		= @"MDQuickLookEndFrame";




static MDQuickLookController *sharedQuickLookController = nil;


@implementation MDQuickLookController


@synthesize items, document;


+ (MDQuickLookController *)sharedQuickLookController {
	if (sharedQuickLookController == nil) {
		sharedQuickLookController = [[super allocWithZone:NULL] init];
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
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
#if MD_DEBUG
	BOOL floats = [[self window] isFloatingPanel];
	NSLog(@"[%@ %@] isFloatingPanel == %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), floats);
#endif
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedItemsDidChange:) name:MDSelectedItemsDidChangeNotification object:nil];
	
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


- (IBAction)showWindow:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	MDShouldShowQuickLook = YES;
	[[self window] orderFront:nil];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:MDShouldShowQuickLook] forKey:MDShouldShowQuickLookKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:MDShouldShowQuickLookDidChangeNotification object:self userInfo:nil];
}


- (void)windowWillClose:(NSNotification *)notification {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([notification object] == [self window]) {
		MDShouldShowQuickLook = NO;
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:MDShouldShowQuickLook] forKey:MDShouldShowQuickLookKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:MDShouldShowQuickLookDidChangeNotification object:self userInfo:nil];
	}
}


- (void)selectedItemsDidChange:(NSNotification *)notification {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	// We need to check this notification to see if it is being sent by a suitcase document that 
	// is being closed. When a document is closed, it posts this notification, with itself
	// as the object, and -- this is unique to a "document-that-is-closing" -- a nil userInfo dictionary.
	// If the notification's object is the same document as our currently retained document, and
	// the userInfo dictionary == nil, then we should be sure to release our document, 
	// as well as the selected items, so that that document can be properly deallocated. 
	
	NSArray *newSelectedItems = [[notification userInfo] objectForKey:MDSelectedItemsKey];
	MDHLDocument *newDocument = [notification object];
	
	if (document == newDocument && newSelectedItems == nil) {
		// let go!
		
		[document release];
		document = nil;
		
		[items release];
		items = nil;
		
		[previewViewController setRepresentedObject:nil];
		
	} else {
		[self setItems:newSelectedItems];
		[self setDocument:newDocument];
	}
	
	if (newDocument && newSelectedItems) {
		
		if ([newSelectedItems count] == 0) {
			[self loadItemAtIndex:-1];
		} else if ([newSelectedItems count] == 1) {
			currentItemIndex = 0;
			[self loadItemAtIndex:currentItemIndex];
		} else if ([newSelectedItems count] > 1) {
			currentItemIndex = 0;
			[self loadItemAtIndex:currentItemIndex];
		}
		
	} else {
		[self loadItemAtIndex:-1];
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
	
	[self loadItemAtIndex:currentItemIndex];
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
	
	[self loadItemAtIndex:currentItemIndex];
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


- (void)loadItemAtIndex:(NSInteger)anIndex {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (anIndex == -1) {
		if (document && items) {
			if ([items count] == 0) {
				[[self window] setTitle:[document displayName]];
				
				[previewViewController setRepresentedObject:document];
				[controlsView setHidden:YES];
			}
		} else {
			
			[[self window] setTitle:@""];
			
			[previewViewController setRepresentedObject:nil];
			[controlsView setHidden:YES];
		}
		
	} else if (anIndex >= 0) {
		if (document && items) {
			
			if ([items count] == 0) {
				
				
			} else if ([items count] == 1) {
				HKItem *item = [items objectAtIndex:anIndex];
				[[self window] setTitle:[item name]];
				[previewViewController setRepresentedObject:item];
				[controlsView setHidden:YES];
				
			} else if ([items count] > 1) {
				HKItem *item = [items objectAtIndex:anIndex];
				[[self window] setTitle:[item name]];
				[previewViewController setRepresentedObject:item];
				[controlsView setHidden:NO];

			}
		}
	}
}


@end



