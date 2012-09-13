//
//  MDCopyProgressController.m
//  Source Finagler
//
//  Created by Mark Douma on 4/4/2006.
//  Copyright (c) 2006 Mark Douma. All rights reserved.
//



#import "MDCopyOperationController.h"
#import "MDHLDocument.h"
#import "MDAppKitAdditions.h"
#import "MDRolloverButton.h"
#import "MDCopyOperation.h"
#import "MDCopyOperationViewController.h"
#import "MDCopyOperationContentView.h"



#define MD_DEBUG 0


static inline NSString *NSStringFromAutoresizingMask(NSUInteger mask) {
	NSMutableString *description = [NSMutableString string];
	if (mask == NSViewNotSizable) {
		[description appendString:@"NSViewNotSizable"];
		return description;
	}
	if (mask & NSViewMinXMargin) [description appendString:@"NSViewMinXMargin | "];
	if (mask & NSViewWidthSizable) [description appendString:@"NSViewWidthSizable | "];
	if (mask & NSViewMaxXMargin) [description appendString:@"NSViewMaxXMargin | "];
	if (mask & NSViewMinYMargin) [description appendString:@"NSViewMinYMargin | "];
	if (mask & NSViewHeightSizable) [description appendString:@"NSViewHeightSizable | "];
	if (mask & NSViewMaxYMargin) [description appendString:@"NSViewMaxYMargin"];
	return description;
}




static MDCopyOperationController *sharedController = nil;

@implementation MDCopyOperationController

@synthesize tag, colorType;

+ (MDCopyOperationController *)sharedController {
	@synchronized(self) {
		if (sharedController == nil) {
			sharedController = [[super allocWithZone:NULL] init];
		}
	}
	return sharedController;
}

+ (id)allocWithZone:(NSZone *)zone {
	return [[self sharedController] retain];
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

- (id)retain {
	return self;
}

- (NSUInteger)retainCount {
	return NSUIntegerMax;	//denotes an object that cannot be released
}

- (oneway void)release {
	// do nothing
}

- (id)autorelease {
	return self;
}

- (id)init {
	if ((self = [super initWithWindowNibName:@"MDCopyOperationWindow"])) {
		operations = [[NSMutableArray alloc] init];
		viewControllersAndTags = [[NSMutableDictionary alloc] init];
		colorType = MDAlternateBackgroundColorType;
		tag = -1;
	} else {
		[NSBundle runFailedNibLoadAlert:@"MDCopyOperationWindow"];
	}		
	return self;
}


- (void)awakeFromNib {
	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"NSWindow Frame copyOperationWindow"] == nil) {
		[[self window] center];
	}
}



- (void)addOperation:(MDCopyOperation *)operation {
	// force the window and nib to be loaded
	[self window];

	if (operation == nil) return;
	
	[self setTag:[operation tag]];
	
#if MD_DEBUG
	NSLog(@"[%@ %@] tag == %ld", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (long)[operation tag]);
#endif
	
	@synchronized(operations) {
		if ([operations count] == 0) {
			[self setColorType:MDWhiteBackgroundColorType];
		} else {
			[self setColorType:(colorType == MDAlternateBackgroundColorType ? MDWhiteBackgroundColorType : MDAlternateBackgroundColorType)];
		}
		[operations addObject:operation];
	}
	
	MDCopyOperationViewController *viewController = [MDCopyOperationViewController viewControllerWithViewColorType:[self colorType] tag:[self tag]];
	
	[viewController setRepresentedObject:operation];
	
	@synchronized(viewControllersAndTags) {
		[viewControllersAndTags setObject:viewController forKey:[NSNumber numberWithInteger:[self tag]]];
	}
	
	@synchronized(contentView) {
		[contentView addCopyOperationView:(MDCopyOperationView *)[viewController view]];
	}
	
	if (![[self window] isVisible]) {
		[self showWindow:self];
	}
}


- (void)endOperation:(MDCopyOperation *)operation {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (operation == nil) return;
		
	MDCopyOperationViewController *viewController = nil;
	
	@synchronized(viewControllersAndTags) {
		viewController = [[[viewControllersAndTags objectForKey:[NSNumber numberWithInteger:[operation tag]]] retain] autorelease];
	}
	
	if (viewController == nil) return;
	
	@synchronized(viewControllersAndTags) {
		[viewControllersAndTags removeObjectForKey:[NSNumber numberWithInteger:[operation tag]]];
	}
	NSUInteger opsCount = 0;
	
	@synchronized(operations) {
		[operations removeObject:operation];
		opsCount = [operations count];
	}
	
	[viewController setRepresentedObject:nil];
	
	if (opsCount == 0) {
		if ([[self window] isVisible]) {
			[[self window] orderOut:self];
		}
	}
	
	@synchronized(contentView) {
		[contentView removeCopyOperationView:(MDCopyOperationView *)[viewController view]];
	}
}

- (IBAction)showWindow:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[[self window] makeKeyAndOrderFront:sender];
}




@end



