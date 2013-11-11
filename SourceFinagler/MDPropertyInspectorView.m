//
//  MDPropertyInspectorView.m
//  MDPropertyInspectorView
//
//  Created by Mark Douma on 8/14/2007.
//  Copyright © 2008 Mark Douma . All rights reserved.
//  


#import "MDPropertyInspectorView.h"
#import "TKMaterialPropertyViewController.h"


static NSString * const MDInspectorViewAutosaveNameKey			= @"MDInspectorViewAutosaveName";
static NSString * const MDInspectorViewIsIntiallyExpandedKey	= @"MDInspectorViewIsIntiallyExpanded";

static NSString * const MDInspectorViewIsShownFormatKey			= @"MDInspectorView %@ isShown";

static NSString * const MDIdentifierKey							= @"MDIdentifier";

#pragma mark view
#define MD_DEBUG 1


@interface MDPropertyInspectorView (MDPrivate)


- (void)hideAndNotify:(BOOL)shouldNotify;
- (void)showAndNotify:(BOOL)shouldNotify;

- (void)removeSubviews;
- (void)restoreSubviews;

@end



@implementation MDPropertyInspectorView


@synthesize titleButton;
@synthesize disclosureButton;
@synthesize delegate;
@synthesize autosaveName;
@synthesize isInitiallyShown;
@synthesize viewController;



static inline NSString *NSStringFromInspectorViewAutosaveName(NSString *anAutosaveName) {
	return [NSString stringWithFormat:MDInspectorViewIsShownFormatKey, anAutosaveName];
}


- (id)initWithFrame:(NSRect)frame {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithFrame:frame])) {
//		isShown = YES;
		
		originalHeight = [self frame].size.height;
		hiddenHeight = 0.0;
		
		autosaveName = @"";
		
//		[self setAutosaveName:@""];
//		[self setInitiallyShown:YES];
		
//		hiddenHeight = 1.0;
	} else {
//		[self release];
		return nil;
	}
	
	return self;
}



- (id)initWithCoder:(NSCoder *)coder {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    if ((self = [super initWithCoder:coder])) {
//		isShown = YES;
		
		originalHeight = [self frame].size.height;
		hiddenHeight = 0.0;
		
		NSString *encodedName = [coder decodeObjectForKey:MDInspectorViewAutosaveNameKey];
		if (encodedName == nil) {
			encodedName = [coder decodeObjectForKey:MDIdentifierKey];
			NSLog(@"[%@ %@] found legacy MDIdentifier", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		}
		
		autosaveName = encodedName;
		
		[self setInitiallyShown:[[coder decodeObjectForKey:MDInspectorViewIsIntiallyExpandedKey] boolValue]];
		
//		hiddenHeight = 1.0;
	}
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
#if MD_DEBUG
	NSLog(@"\"%@\" [%@ %@]", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    [super encodeWithCoder:coder];
	[coder encodeObject:autosaveName forKey:MDInspectorViewAutosaveNameKey];
	[coder encodeObject:[NSNumber numberWithBool:isInitiallyShown] forKey:MDInspectorViewIsIntiallyExpandedKey];
	
}

- (void)awakeFromNib {
#if MD_DEBUG
	NSLog(@"\"%@\" [%@ %@] delegate == %@", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd), delegate);
#endif
	
	isShown = isInitiallyShown;
	
	if (autosaveName && ![autosaveName isEqualToString:@""]) {
		NSNumber *isShownNumber = [[NSUserDefaults standardUserDefaults] objectForKey:NSStringFromInspectorViewAutosaveName(autosaveName)];
		if (isShownNumber == nil) {
			// if no value is present in user defaults, then set the default value of YES (or whatever the present value is by this point)
			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:isShown] forKey:NSStringFromInspectorViewAutosaveName(autosaveName)];
		}
		isShown = [[[NSUserDefaults standardUserDefaults] objectForKey:NSStringFromInspectorViewAutosaveName(autosaveName)] boolValue];
		
		if (isShown) {
			NSLog(@"\"%@\" [%@ %@] isShown == YES", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		} else {
			NSLog(@"\"%@\" [%@ %@] isShown == NO", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		}
	}
	
	if (!isShown) {
		if ([self window] == nil) {
			havePendingWindowHeightChange = YES;
		} else {
//			[self hideAndNotify:NO];
			[self hideAndNotify:YES];
		}
	} else {
		if (disclosureButton) [disclosureButton setState:NSOnState];

	}
	
    if ([self autoresizingMask] & NSViewHeightSizable) {
//		NSLog(@"\"%@\" [%@ %@] WARNING: You probably don't want this view to be resizeable vertically; you should turn that off in the inspector in IB.", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	}
	
}


- (IBAction)toggleShown:(id)sender {
#if MD_DEBUG
//	NSLog(@"\"%@\" [%@ %@] self.frame == %@", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(self.frame));
#endif
	[self setShown:!isShown];
	
}


- (BOOL)isShown {
	return isShown;
}


- (void)setShown:(BOOL)shouldShow {
#if MD_DEBUG
//	NSLog(@"\"%@\" [%@ %@]", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (shouldShow != isShown) {
		(shouldShow ? [self showAndNotify:YES] : [self hideAndNotify:YES]);
	}
	
	if (autosaveName && ![autosaveName isEqualToString:@""]) {
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:isShown] forKey:NSStringFromInspectorViewAutosaveName(autosaveName)];
	}
}


- (void)hideAndNotify:(BOOL)shouldNotify {
#if MD_DEBUG
//	NSLog(@"\"%@\" [%@ %@]", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (disclosureButton) [disclosureButton setState:NSOffState];
	
	NSRect frame = self.frame;
	
	NSArray *subviews = self.superview.subviews;
	
	for (NSView *subview in subviews) {
		
		if (subview == self) continue;
		
		NSRect subviewFrame = subview.frame;
		
		if (NSMaxY(subviewFrame) - 2.0 <= NSMaxY(frame)) {
            // This subview is below us. Make it stick to the bottom of the window.
			
			[subview setFrameOrigin:NSMakePoint(subviewFrame.origin.x, subviewFrame.origin.y + (frame.size.height - 1.0))];
			
			[subview setNeedsDisplay:YES];
		}
	}
	
	[viewController.view removeFromSuperview];
	
	[self setFrame:NSMakeRect(frame.origin.x, frame.origin.y + NSHeight(frame) - 1.0, NSWidth(frame), 1.0)];
	
	[self.superview setNeedsDisplay:YES];
	
	isShown = NO;
	
	[self setNeedsDisplay:YES];
}


- (void)showAndNotify:(BOOL)shouldNotify {
#if MD_DEBUG
//	NSLog(@"\"%@\" [%@ %@]", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (disclosureButton) [disclosureButton setState:NSOnState];
	
	if (viewController == nil) {
		self.viewController = [[TKMaterialPropertyViewController alloc] init];
	}
	
	NSSize newViewSize = viewController.view.frame.size;
	
	NSRect frame = self.frame;
	
	NSArray *subviews = self.superview.subviews;
	
	for (NSView *subview in subviews) {
		
		if (subview == self) continue;
		
		NSRect subviewFrame = subview.frame;
		
		if (NSMaxY(subviewFrame) - 2.0 <= NSMaxY(frame)) {
            // This subview is below us. Make it stick to the bottom of the window.
			
			[subview setFrameOrigin:NSMakePoint(subviewFrame.origin.x, subviewFrame.origin.y - (newViewSize.height - 1.0))];
			
			[subview setNeedsDisplay:YES];
		}
	}
	
	[self setFrame:NSMakeRect(frame.origin.x, frame.origin.y - newViewSize.height, newViewSize.width, newViewSize.height)];
	
	[self setNeedsDisplay:YES];
	
	[self addSubview:viewController.view];
	
	[self.superview setNeedsDisplay:YES];
	
    isShown = YES;

    [self setNeedsDisplay:YES];
}


- (void)changeWindowHeightBy:(CGFloat)value {
#if MD_DEBUG
	NSLog(@"\"%@\" [%@ %@]", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
    // This turns out to be more complicated than one might expect, because the way that the other views in the window should move is different than the normal case that the AppKit handles.
    //
    // We want the other views in the window to stay the same size. If a view is above us, we want it to stay in the same position relative to the top of the window; likewise, if a view is below us, we want it to stay in the same position relative to the bottom of the window.
    // Also, we want this view to resize vertically, with its top and bottom attached to the top and bottom of its parent.
    // And: this view's subviews should not resize vertically, and should stay attached to the top of this view.  (This only matters if showSubviewsWhileResizing is YES; otherwise, we have no subviews at this point in time.)
    //
    // However, all of these views may have their autoresize masks configured differently than we want. So:
    //
    // * For each of the window's content view's immediate subviews, including this view,
    //   - Save the current autoresize mask
    //   - And set the autoresize mask how we want
    // * Do the same for the view's subviews.
    // * Then resize the window, and fix up the window's min/max sizes.
    // * For each view that we touched earlier, restore the old autoresize mask.
	
	
	NSRect			ourFrame = [self frame];
	NSWindow		*window = [self window];
	
//	if (window == nil && delegate && [delegate respondsToSelector:@selector(window)]) {
//		window = [delegate window];
//	}
	
	NSView			*contentView = [window contentView];
	
    // Adjust the autoresize masks of the window's subviews, remembering the original masks.
	
	NSArray			*windowSubviews = [contentView subviews];
	NSUInteger		windowSubviewCount = [windowSubviews count];
	NSMutableArray	*windowSubviewMasks = [NSMutableArray array];
	
	for (NSUInteger	i = 0; i < windowSubviewCount; i++) {
		
		NSView *windowSubview = [windowSubviews objectAtIndex:i];
		NSUInteger mask = [windowSubview autoresizingMask];
		
		[windowSubviewMasks addObject:[NSNumber numberWithUnsignedLong:mask]];
		
		if (windowSubview == self) {
            // This is us.  Make us stick to the top and bottom of the window, and resize vertically.
			mask |= NSViewHeightSizable;
			mask &= ~NSViewMaxYMargin;
			mask &= ~NSViewMinYMargin;
			
		} else if (NSMaxY([windowSubview frame])- 2.0 <= NSMaxY(ourFrame)) {
//		} else if (NSMaxY([windowSubview frame]) <= NSMaxY(ourFrame)) {
            // This subview is below us. Make it stick to the bottom of the window.
            // It should not change height.
			
			mask &= ~NSViewHeightSizable;
			mask |= NSViewMaxYMargin;
			mask &= ~NSViewMinYMargin;
			
		} else {
            // This subview is above us. Make it stick to the top of the window.
            // It should not change height.
			
			mask &= ~NSViewHeightSizable;
			mask &= ~NSViewMaxYMargin;
			mask |= NSViewMinYMargin;
		}
		
		[windowSubview setAutoresizingMask:mask];
	}
	
	
    // Adjust the autoresize masks of our subviews, remembering the original masks.
    // (Note that if showSubviewsWhileResizing is NO, [self subviews] will be empty.)
	
	NSArray			*ourSubviews = [self subviews];
	NSUInteger		ourSubviewCount = [ourSubviews count];
	NSMutableArray	*ourSubviewMasks = [NSMutableArray array];
	
	for (NSUInteger i = 0; i < ourSubviewCount; i++) {
		NSView *ourSubview;
		NSUInteger mask;
		
		ourSubview = [ourSubviews objectAtIndex:i];
		mask = [ourSubview autoresizingMask];
		[ourSubviewMasks addObject:[NSNumber numberWithUnsignedLong:mask]];
		
        // Don't change height, and stick to the top of the view.
		mask &= ~NSViewHeightSizable;
		mask &= ~NSViewMaxYMargin;
		mask |= NSViewMinYMargin;
		
		[ourSubview setAutoresizingMask:mask];
	}
	
    // Compute the window's new frame, and resize it.
	NSRect newWindowFrame = [window frame];
	newWindowFrame.origin.y -= value;
	newWindowFrame.size.height += value;
	
	if ([window isVisible] && havePendingWindowHeightChange == NO) {
		[window setFrame:newWindowFrame display:YES animate:YES];
	} else {
		[window setFrame:newWindowFrame display:NO];
	}
	
    // Adjust the window's min and max sizes to make sense.
	
	NSSize newWindowMinOrMaxSize = [window minSize];
	newWindowMinOrMaxSize.height += value;
	[window setMinSize:newWindowMinOrMaxSize];
	
	newWindowMinOrMaxSize = [window maxSize];
    // If there is no max size set (height of 0), don't change it.
	
	if (newWindowMinOrMaxSize.height) {
		newWindowMinOrMaxSize.height += value;
		[window setMaxSize:newWindowMinOrMaxSize];
	}
	
	
    // Restore the saved autoresize masks.
	NSUInteger count = [windowSubviewMasks count];
	
	for (NSUInteger index = 0; index < count; index++) {
		[(NSView *)[windowSubviews objectAtIndex:index] setAutoresizingMask:[[windowSubviewMasks objectAtIndex:index] unsignedLongValue]];
	}
	
	count = [ourSubviewMasks count];
	
	for (NSUInteger i = 0; i < count; i++) {
		[(NSView *)[ourSubviews objectAtIndex:i] setAutoresizingMask:[[ourSubviewMasks objectAtIndex:i] unsignedLongValue]];
	}
	
}




- (void)setNilValueForKey:(NSString *)key {
#if MD_DEBUG
	NSLog(@"\"%@\" [%@ %@]", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([key isEqualToString:@"isInitiallyShown"]) {
		isInitiallyShown = YES;
	} else if ([key isEqualToString:@"autosaveName"]) {
		self.autosaveName = @"";
	}
}


- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
#if MD_DEBUG
	NSLog(@"\"%@\" [%@ %@]", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [super viewWillMoveToWindow:newWindow];
}


- (void)viewDidMoveToWindow {
#if MD_DEBUG
	NSLog(@"\"%@\" [%@ %@]", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super viewDidMoveToWindow];
	
	if (havePendingWindowHeightChange) {
		if (!isShown) {
			[self hideAndNotify:YES];
		}
		havePendingWindowHeightChange = NO;
	}
}




#define MD_DRAWING_DEBUG 0


- (void)drawRect:(NSRect)frame {
	[super drawRect:frame];
#if MD_DRAWING_DEBUG
	[[NSColor redColor] set];
	[NSBezierPath setDefaultLineWidth:4.0];
	[NSBezierPath strokeRect:frame];
#endif
}




@end






