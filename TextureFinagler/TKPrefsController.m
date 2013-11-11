//
//  TKPrefsController.m
//  Source Finagler
//
//  Created by Mark Douma on 9/12/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "TKPrefsController.h"
#import "TKPrefsGeneralController.h"
#import "TKAppKitAdditions.h"



#define TK_DEBUG 1


static NSString * const TKPrefsCurrentViewKey			= @"TKPrefsCurrentView";

static NSArray *prefsClassNames = nil;


@implementation TKPrefsController


+ (void)initialize {
	@synchronized(self) {
		if (prefsClassNames == nil) {
			prefsClassNames = [[[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"TKPrefs" ofType:@"plist"]] objectForKey:@"TKPrefsClassNames"] retain];
		}
		NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
		[defaults setObject:[NSNumber numberWithUnsignedInteger:TKPrefsGeneralView]	forKey:TKPrefsCurrentViewKey];
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	}
}


- (id)init {
	if ((self = [super initWithWindowNibName:@"TKPrefs"])) {
		currentView = [[[NSUserDefaults standardUserDefaults] objectForKey:TKPrefsCurrentViewKey] unsignedIntegerValue];
		viewControllers = [[NSMutableArray alloc] init];
		NSUInteger count = prefsClassNames.count;
		for (NSUInteger i = 0; i < count; i++) {
			[viewControllers addObject:[NSNull null]];
		}
		[self window];
		
	} else {
		[NSBundle runFailedNibLoadAlert:@"TKPrefs"];
	}
	return self;
}

- (void)dealloc {
	[viewControllers release];
	[super dealloc];
}


- (void)awakeFromNib {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self changeView:self];
}


- (IBAction)changeView:(id)sender {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (sender == self || sender == nil) {
		NSArray *toolbarItems = self.window.toolbar.items;
		for (NSToolbarItem *toolbarItem in toolbarItems) {
			if (toolbarItem.tag == currentView) {
				[self.window.toolbar setSelectedItemIdentifier:toolbarItem.itemIdentifier]; break;
			}
		}
	} else {
		currentView = [(NSToolbarItem *)sender tag];
	}
	
	TKViewController *viewController = [viewControllers objectAtIndex:currentView];

	if ((NSNull *)viewController == [NSNull null]) {
		NSString *className = [prefsClassNames objectAtIndex:currentView];
		
		Class viewControllerClass = NSClassFromString(className);
		
		viewController = [[viewControllerClass alloc] init];
		
		[viewControllers replaceObjectAtIndex:currentView withObject:viewController];
		
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


