//
//  MDInspectorView.m
//  MDInspectorView
//
//  Created by Mark Douma on 8/14/2007.
//  Copyright © 2008 Mark Douma . All rights reserved.
//  


#import "MDInspectorView.h"


NSString * const MDInspectorViewWillShowNotification			= @"MDInspectorViewWillShow";
NSString * const MDInspectorViewDidShowNotification				= @"MDInspectorViewDidShow";

NSString * const MDInspectorViewWillHideNotification			= @"MDInspectorViewWillHide";
NSString * const MDInspectorViewDidHideNotification				= @"MDInspectorViewDidHide";



static NSString * const MDInspectorViewAutosaveNameKey			= @"MDInspectorViewAutosaveName";
static NSString * const MDInspectorViewIsIntiallyExpandedKey	= @"MDInspectorViewIsIntiallyExpanded";

static NSString * const MDInspectorViewIsShownFormatKey			= @"MDInspectorView %@ isShown";

static NSString * const MDIdentifierKey							= @"MDIdentifier";

#pragma mark view
#define MD_DEBUG 0


@interface MDInspectorView (MDPrivate)


- (void)hideAndNotify:(BOOL)shouldNotify;
- (void)showAndNotify:(BOOL)shouldNotify;

- (void)removeSubviews;
- (void)restoreSubviews;

@end



@implementation MDInspectorView

static inline NSString *NSStringFromInspectorViewAutosaveName(NSString *anAutosaveName) {
	return [NSString stringWithFormat:MDInspectorViewIsShownFormatKey, anAutosaveName];
}


- (id)initWithFrame:(NSRect)frame {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithFrame:frame])) {
		isShown = YES;
		
		originalHeight = [self frame].size.height;
		hiddenHeight = 0.0;
		
		autosaveName = [@"" retain];
		
//		[self setAutosaveName:@""];
		[self setInitiallyShown:YES];
		
//		hiddenHeight = 1.0;
	} else {
		[self release];
		return nil;
	}
	
	return self;
}



- (id)initWithCoder:(NSCoder *)coder {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    if ((self = [super initWithCoder:coder])) {
		isShown = YES;
		
		originalHeight = [self frame].size.height;
		hiddenHeight = 0.0;
		
		NSString *encodedName = [coder decodeObjectForKey:MDInspectorViewAutosaveNameKey];
		if (encodedName == nil) {
			encodedName = [coder decodeObjectForKey:MDIdentifierKey];
			NSLog(@"[%@ %@] found legacy MDIdentifier", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		}
		
		autosaveName = [encodedName retain];
		
//		[self setAutosaveName:encodedName];
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


- (void)dealloc {
	delegate = nil;
	[autosaveName release];
	[hiddenSubviews release];
	[super dealloc];
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


- (void)setNilValueForKey:(NSString *)key {
#if MD_DEBUG
	NSLog(@"\"%@\" [%@ %@]", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([key isEqualToString:@"isInitiallyShown"]) {
		isInitiallyShown = YES;
	} else if ([key isEqualToString:@"autosaveName"]) {
		[autosaveName release];
		autosaveName = [@"" copy];
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


- (NSButton *)titleButton {
    return titleButton;
}

- (void)setTitleButton:(NSButton *)value {
	titleButton = value;
}


- (NSButton *)disclosureButton {
    return disclosureButton;
}

- (void)setDisclosureButton:(NSButton *)value {
	disclosureButton = value;
}


- (NSString *)autosaveName {
    return autosaveName;
}

- (void)setAutosaveName:(NSString *)value {
	NSString *aCopy = [value copy];
	[autosaveName release];
	autosaveName = aCopy;
}


//@property (assign, setter=setInitiallyShown:) BOOL isInitiallyShown;

- (BOOL)isInitiallyShown {
    return isInitiallyShown;
}

- (void)setInitiallyShown:(BOOL)value {
	isInitiallyShown = value;
}


- (id <MDInspectorViewDelegate>)delegate {
#if MD_DEBUG
	NSLog(@"\"%@\" [%@ %@]", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return delegate;
}


- (void)setDelegate:(id <MDInspectorViewDelegate>)aDelegate {
#if MD_DEBUG
	NSLog(@"\"%@\" [%@ %@]", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	delegate = aDelegate;
}


- (BOOL)isShown {
	return isShown;
}


- (void)setShown:(BOOL)shouldShow {
#if MD_DEBUG
	NSLog(@"\"%@\" [%@ %@]", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (shouldShow != isShown) {
		(shouldShow ? [self showAndNotify:YES] : [self hideAndNotify:YES]);
	}
	
	if (autosaveName && ![autosaveName isEqualToString:@""]) {
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:isShown] forKey:NSStringFromInspectorViewAutosaveName(autosaveName)];
	}
}


- (IBAction)toggleShown:(id)sender {
#if MD_DEBUG
	NSLog(@"\"%@\" [%@ %@]", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self setShown:!isShown];
	
}


- (void)hideAndNotify:(BOOL)shouldNotify {
#if MD_DEBUG
	NSLog(@"\"%@\" [%@ %@]", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (shouldNotify) {
		if (delegate && [delegate respondsToSelector:@selector(inspectorViewWillHide:)]) {
			NSNotification *notification = [NSNotification notificationWithName:MDInspectorViewWillHideNotification object:self];
			[delegate inspectorViewWillHide:notification];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:MDInspectorViewWillHideNotification object:self];
	}
	
	
	if (disclosureButton) [disclosureButton setState:NSOffState];
	
	NSView *keyLoopView = [self nextKeyView];
	
    if ([keyLoopView isDescendantOf:self]) {
        // We need to remove our subviews (which will be hidden) from the key loop.
		
        // Remember our nextKeyView so we can restore it later.
        nonretainedOriginalNextKeyView = keyLoopView;
		
        // Find the last view in the key loop which is one of our descendants.
		
        nonretainedLastChildKeyView = keyLoopView;
		
        while ((keyLoopView = [nonretainedLastChildKeyView nextKeyView])) {
            if ([keyLoopView isDescendantOf:self]) {
                nonretainedLastChildKeyView = keyLoopView;
			} else {
                break;
			}
        }
		
        // Set our nextKeyView to its nextKeyView, and set its nextKeyView to nil.
        // (If we don't do the last step, when we restore the key loop later, it will be missing views in the backwards direction.)
		
        [self setNextKeyView:keyLoopView];
        [nonretainedLastChildKeyView setNextKeyView:nil];
		
    } else {
		
        nonretainedOriginalNextKeyView = nil;
    }
	
    // Remember our current size.
    // When showing, we will use this to resize the subviews properly.
    // (The window width may change while the subviews are hidden.)
	
	// *** MD: The window height may also change.
	
    sizeBeforeHidden = [self frame].size;
	
    // Now shrink the window, causing this view to shrink and our subviews to be obscured.
    // Also remove the subviews from the view hierarchy.
	
	// *** MD: change:
	// This is going to have to take into account the current height of the view,
	// not just the originalHeight
	
//	[self changeWindowHeightBy:-(originalHeight - hiddenHeight)];
	[self changeWindowHeightBy:-(sizeBeforeHidden.height - hiddenHeight)];
	
	[self removeSubviews];
	
    isShown = NO;
	
    [self setNeedsDisplay:YES];
	
	if (shouldNotify) {
		if (delegate && [delegate respondsToSelector:@selector(inspectorViewDidHide:)]) {
			NSNotification *notification = [NSNotification notificationWithName:MDInspectorViewDidHideNotification object:self];
			[delegate inspectorViewDidHide:notification];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:MDInspectorViewDidHideNotification object:self];
		
	}
}


- (void)showAndNotify:(BOOL)shouldNotify {
#if MD_DEBUG
	NSLog(@"\"%@\" [%@ %@]", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (shouldNotify) {
		if (delegate && [delegate respondsToSelector:@selector(inspectorViewWillShow:)]) {
			NSNotification *notification = [NSNotification notificationWithName:MDInspectorViewWillShowNotification object:self];
			[delegate inspectorViewWillShow:notification];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:MDInspectorViewWillShowNotification object:self];
	}
	
	if (disclosureButton) [disclosureButton setState:NSOnState];
	
    // Expand the window, causing this view to expand, and put our hidden subviews back into the view hierarchy.
	
	[self restoreSubviews];
		
	// Temporarily set our frame back to its original height.
	// Then tell our subviews to resize themselves, according to their normal autoresize masks.
	// (This may cause their widths to change, if the window was resized horizontally while the subviews were out of the view hierarchy.)
	// Then set our frame size back so we are hidden again.
	
//	hiddenSize = [self frame].size;
//	[self setFrameSize:NSMakeSize(hiddenSize.width, originalHeight)];
//	[self resizeSubviewsWithOldSize:sizeBeforeHidden];
//	[self setFrameSize:hiddenSize];
//	
//	[self changeWindowHeightBy:(originalHeight - hiddenHeight)];
	
	
	
	NSSize hiddenSize = [self frame].size;
	
	[self setFrameSize:NSMakeSize(hiddenSize.width, sizeBeforeHidden.height)];
	[self resizeSubviewsWithOldSize:sizeBeforeHidden];
	[self setFrameSize:hiddenSize];
	
	[self changeWindowHeightBy:(sizeBeforeHidden.height - hiddenHeight)];
	
	
	
    if (nonretainedOriginalNextKeyView) {
        // Restore the key loop to its old configuration.
        [nonretainedLastChildKeyView setNextKeyView:[self nextKeyView]];
        [self setNextKeyView:nonretainedOriginalNextKeyView];
    }

    isShown = YES;

    [self setNeedsDisplay:YES];
	
	if (shouldNotify) {
		if (delegate && [delegate respondsToSelector:@selector(inspectorViewDidShow:)]) {
			NSNotification *notification = [NSNotification notificationWithName:MDInspectorViewDidShowNotification object:self];
			[delegate inspectorViewDidShow:notification];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:MDInspectorViewDidShowNotification object:self];
		
	}
	
}


- (void)removeSubviews {
#if MD_DEBUG
	NSLog(@"\"%@\" [%@ %@]", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSString *assertString = [NSString stringWithFormat:@"\"%@\" [%@ %@] should have no hidden subviews yet", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd)];

    NSAssert(hiddenSubviews == nil, assertString);
	
    hiddenSubviews = [[NSArray alloc] initWithArray:[self subviews]];
	
    NSUInteger subviewIndex = [hiddenSubviews count];
	
    while (subviewIndex--) {
        [[hiddenSubviews objectAtIndex:subviewIndex] removeFromSuperview];
	}
	
}


- (void)restoreSubviews {
#if MD_DEBUG
	NSLog(@"\"%@\" [%@ %@]", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSString *assertString = [NSString stringWithFormat:@"\"%@\" [%@ %@] should have no hidden subviews yet", autosaveName, NSStringFromClass([self class]), NSStringFromSelector(_cmd)];

    NSAssert(hiddenSubviews != nil, assertString);

    NSUInteger subviewIndex = [hiddenSubviews count];
	
    while (subviewIndex--) {
        [self addSubview:[hiddenSubviews objectAtIndex:subviewIndex]];
	}

    [hiddenSubviews release];
    hiddenSubviews = nil;
	
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
	
	for (NSUInteger	windowSubviewIndex = 0; windowSubviewIndex < windowSubviewCount; windowSubviewIndex++) {
		
		NSView *windowSubview = [windowSubviews objectAtIndex:windowSubviewIndex];
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
	
	for (NSUInteger ourSubviewIndex = 0; ourSubviewIndex < ourSubviewCount; ourSubviewIndex++) {
		NSView *ourSubview;
		NSUInteger mask;
		
		ourSubview = [ourSubviews objectAtIndex:ourSubviewIndex];
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
	
	for (NSUInteger index = 0; index < count; index++) {
		[(NSView *)[ourSubviews objectAtIndex:index] setAutoresizingMask:[[ourSubviewMasks objectAtIndex:index] unsignedLongValue]];
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


//- (NSString *)identifier {
//	NSLog(@"[%@ %@] is deprecated; you should use [%@ %@] instead...", NSStringFromClass([self class]),
//		  NSStringFromSelector(_cmd),
//		  NSStringFromClass([self class]),
//		  NSStringFromSelector(@selector(autosaveName)));
//	return [self autosaveName];
//}
//
//
//- (void)setIdentifier:(NSString *)anIdentifier {
//	NSLog(@"[%@ %@] is deprecated; you should use [%@ %@] instead...", NSStringFromClass([self class]),
//		  NSStringFromSelector(_cmd),
//		  NSStringFromClass([self class]),
//		  NSStringFromSelector(@selector(setAutosaveName:)));
//	return [self setAutosaveName:anIdentifier];
//}



@end


