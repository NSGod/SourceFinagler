//
//  MDPrefsController.m
//  Source Finagler
//
//  Created by Mark Douma on 9/12/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDPrefsController.h"
#import "MDViewController.h"
#import "MDAppKitAdditions.h"



#define MD_DEBUG 0


static NSString * const MDPrefsCurrentViewIndexKey			= @"MDPrefsCurrentViewIndex";

static NSArray *prefsClassNames = nil;


@implementation MDPrefsController


+ (void)initialize {
	@synchronized(self) {
		if (prefsClassNames == nil) {
			prefsClassNames = [[[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MDPrefs" ofType:@"plist"]] objectForKey:@"MDPrefsClassNames"] retain];
		}
		NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
		[defaults setObject:[NSNumber numberWithUnsignedInteger:0]	forKey:MDPrefsCurrentViewIndexKey];
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	}
}


- (id)init {
	if ((self = [super initWithWindowNibName:@"MDPrefs"])) {
		currentViewIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:MDPrefsCurrentViewIndexKey] unsignedIntegerValue];
		viewControllers = [[NSMutableArray alloc] init];
		NSUInteger count = prefsClassNames.count;
		for (NSUInteger i = 0; i < count; i++) {
			[viewControllers addObject:[NSNull null]];
		}
		[self window];
		
	} else {
		[NSBundle runFailedNibLoadAlert:@"MDPrefs"];
	}
	return self;
}

- (void)dealloc {
	[viewControllers release];
	[super dealloc];
}


- (void)awakeFromNib {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self changeView:self];
}


- (IBAction)changeView:(id)sender {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (sender == self || sender == nil) {
		
		NSUInteger count = viewControllers.count;
		
		while (currentViewIndex >= count) {
			currentViewIndex--;
		}
		
		NSArray *toolbarItems = self.window.toolbar.items;
		for (NSToolbarItem *toolbarItem in toolbarItems) {
			if (toolbarItem.tag == currentViewIndex) {
				[self.window.toolbar setSelectedItemIdentifier:toolbarItem.itemIdentifier]; break;
			}
		}
	} else {
		currentViewIndex = [(NSToolbarItem *)sender tag];
	}
	
	MDViewController *viewController = [viewControllers objectAtIndex:currentViewIndex];

	if ((NSNull *)viewController == [NSNull null]) {
		NSString *className = [prefsClassNames objectAtIndex:currentViewIndex];
		
		Class viewControllerClass = NSClassFromString(className);
		
		viewController = [[viewControllerClass alloc] init];
		
		[viewControllers replaceObjectAtIndex:currentViewIndex withObject:viewController];
		
		[viewController release];
		
	}
	
	[self.window switchView:viewController.view newTitle:viewController.title];
	[viewController didSwitchToView:self];
	
}


- (IBAction)showWindow:(id)sender {
	if ([[self window] isVisible] == NO) [[self window] center];
	[super showWindow:sender];
}


@end


