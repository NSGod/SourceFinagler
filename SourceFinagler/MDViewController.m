//
//  MDViewController.m
//  Procon Finagler
//
//  Created by Mark Douma on 6/9/2012.
//  Copyright (c) 2012 Mark Douma LLC. All rights reserved.
//

#import "MDViewController.h"


#define MD_DEBUG 1


#define MD_WINDOW_TITLEBAR_HEIGHT 22.0


@implementation MDViewController

@synthesize minWinSize;
@synthesize maxWinSize;
@synthesize resizable;


- (id)init {
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
		resizable = YES;
	}
	return self;
}

+ (NSSize)windowSizeForViewWithSize:(NSSize)size {
	return NSMakeSize(size.width, size.height + MD_WINDOW_TITLEBAR_HEIGHT);
}


- (void)didSwitchToView:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (NSEqualSizes(minWinSize, NSZeroSize) && NSEqualSizes(maxWinSize, NSZeroSize)) {
		NSRect viewFrame = self.view.frame;
		if (resizable) {
			minWinSize = [MDViewController windowSizeForViewWithSize:viewFrame.size];
			maxWinSize = NSMakeSize(FLT_MAX, FLT_MAX);
		} else {
			minWinSize = [MDViewController windowSizeForViewWithSize:viewFrame.size];
			maxWinSize = [MDViewController windowSizeForViewWithSize:viewFrame.size];
		}
	}
	
	[self.view.window setShowsResizeIndicator:resizable];
	
	[self.view.window setMinSize:minWinSize];
	[self.view.window setMaxSize:maxWinSize];
	
	[[self.view.window standardWindowButton:NSWindowZoomButton] setEnabled:resizable];
	
}
	
	
- (NSString *)viewControllerViewSizeAutosaveString {
	return [NSString stringWithFormat:@"MDViewController viewSize %@", self.viewSizeAutosaveName];
}


- (void)cleanup {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (self.viewSizeAutosaveName) {
		NSString *existingSize = [[NSUserDefaults standardUserDefaults] objectForKey:[self viewControllerViewSizeAutosaveString]];
		NSString *currentSize = NSStringFromSize(self.view.frame.size);
		
#if MD_DEBUG
		NSLog(@"[%@ %@] existingSize == %@, currentSize == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), existingSize, currentSize);
#endif
		
		[[NSUserDefaults standardUserDefaults] setObject:currentSize forKey:[self viewControllerViewSizeAutosaveString]];
		
		NSString *newSavedSize = [[NSUserDefaults standardUserDefaults] objectForKey:[self viewControllerViewSizeAutosaveString]];
		
#if MD_DEBUG
		NSLog(@"[%@ %@] ******* SAVING %@'s viewSize == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [self viewSizeAutosaveName], newSavedSize);
#endif

	}
}

- (NSString *)viewSizeAutosaveName {
	return nil;
}

- (void)viewDidLoad {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}


- (void)loadView {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super loadView];
	
	if (self.viewSizeAutosaveName) {
		
		NSString *savedSize = [[NSUserDefaults standardUserDefaults] objectForKey:[self viewControllerViewSizeAutosaveString]];
		
		if (savedSize == nil) {
			[[NSUserDefaults standardUserDefaults] setObject:NSStringFromSize(self.view.frame.size) forKey:[self viewControllerViewSizeAutosaveString]];
		}
		
#if MD_DEBUG
//		NSLog(@"[%@ %@] self.view == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.view);
		NSLog(@"[%@ %@] self.view.frame == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(self.view.frame));
		NSLog(@"[%@ %@] ******* RESTORING %@'s viewSize == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [self viewSizeAutosaveName], [[NSUserDefaults standardUserDefaults] objectForKey:[self viewControllerViewSizeAutosaveString]]);
#endif
		[self.view setFrameSize:NSSizeFromString([[NSUserDefaults standardUserDefaults] objectForKey:[self viewControllerViewSizeAutosaveString]])];
		
#if MD_DEBUG
		NSLog(@"[%@ %@] self.view.frame == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(self.view.frame));
#endif
		
	}
	[self viewDidLoad];
}


@end



