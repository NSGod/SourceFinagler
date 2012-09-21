//
//  TKViewController.m
//  Source Finagler
//
//  Created by Mark Douma on 4/14/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import "TKViewController.h"
#import "TKAppKitAdditions.h"


#pragma mark controller
#define MD_DEBUG 0


NSString * const TKViewControllerViewDidChangeNotification	= @"TKViewControllerViewDidChange";


@interface TKViewController (MDPrivate)
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil window:(NSWindow *)aWindow;
@end


@implementation TKViewController

@dynamic title;


- (id)init {
	return [self initWithNibName:[self nibName] bundle:[self nibBundle]];
}

- (id)initWithWindow:(NSWindow *)aWindow {
	return [self initWithNibName:[self nibName] bundle:[self nibBundle] window:aWindow];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	return [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil window:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil window:(NSWindow *)aWindow {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		window = aWindow;
		nibName = [nibNameOrNil retain];
		nibBundle = [nibBundleOrNil retain];
	}
	return self;
}


- (void)dealloc {
#if MD_DEBUG
	NSLog(@"[%@ %@] (TKViewController)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	window = nil;
	[view release];
	[nibName release];
	[nibBundle release];
	[title release];
	[super dealloc];
}

- (void)awakeFromNib {
#if MD_DEBUG
	NSLog(@"[%@ %@] view == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), view);
#endif
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidChange:) name:TKViewControllerViewDidChangeNotification object:view];
}


- (void)viewControllerDidLoadNib {
#if MD_DEBUG
	NSLog(@"[%@ %@] (TKViewController)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}


/* Instantiate the view and then set it. The default implementation of this method invokes [self nibName] and [self nibBundle] and then uses the NSNib class to load the nib with this object as the file's owner. If the "view" outlet of the file's owner in the nib is properly connected, the regular nib loading machinery will send this object a -setView: message. You can override this method to customize how nib loading is done, including merely adding new behavior immediately before or immediately after nib loading done by the default implementation. You should not invoke this method from other objects unless you take care to avoid redundant invocations; NSViewController's default implement can handle them but overrides in subclasses might not. (Typically other objects should instead invoke -view and let the view controller do whatever it takes to fulfill the request.)
*/
- (void)loadView {
#if MD_DEBUG
	NSLog(@"[%@ %@] (TKViewController)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (view == nil) {
		if (nibName) {
			if (![NSBundle loadNibNamed:nibName owner:self]) {
				[NSBundle runFailedNibLoadAlert:nibName];
			}
		}
		[view release];
		[self viewControllerDidLoadNib];
	}
}


/* Return the view. The default implementation of this method first invokes [self loadView] if the view hasn't been set yet.
*/
- (NSView *)view {
#if MD_DEBUG
	NSLog(@"[%@ %@] (TKViewController)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (view == nil) [self loadView];
	return view;
}

/* Set the view. You can invoke this method immediately after creating the object to specify a view that's created in a different manner than what -view's default implementation would do.
*/
- (void)setView:(NSView *)aView {
#if MD_DEBUG
	NSLog(@"[%@ %@] (TKViewController)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[aView retain];
	[view release];
	view = aView;
}


- (void)viewDidChange:(NSNotification *)notification {
	if ([notification object] == view) {
#if MD_DEBUG
	NSLog(@"[%@ %@] (TKViewController)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		
		if (isResizable) {
			
			[window setShowsResizeIndicator:YES];
			
			[window setMinSize:minSize];
			[window setMaxSize:maxSize];
			
			[[window standardWindowButton:NSWindowZoomButton] setEnabled:YES];

		} else {
			
			NSSize localMinSize = NSZeroSize;
			NSSize localMaxSize = NSZeroSize;
			
			NSRect viewFrame = [view frame];
			
			localMinSize = NSMakeSize(NSWidth(viewFrame), NSHeight(viewFrame) + 22.0);
			localMaxSize = NSMakeSize(NSWidth(viewFrame), NSHeight(viewFrame) + 22.0);
			
			[window setShowsResizeIndicator:NO];
			
			[window setMinSize:localMinSize];
			[window setMaxSize:localMaxSize];
			
			[[window standardWindowButton:NSWindowZoomButton] setEnabled:NO];
			
		}
	}
}

/* Return the name of the nib to be loaded to instantiate the view, and the bundle from which to load it. The default implementations of these merely return whatever value was passed to the initializer.
*/
- (NSString *)nibName {
	NSLog(@"[%@ %@] subclass should override!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	return nibName;
}


- (NSBundle *)nibBundle {
//	NSLog(@"[%@ %@] subclass should override!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	return nibBundle;
}

/* The localized title of the view. This class doesn't actually do anything with the value of this property other than hold onto it, and be KVC and KVO compliant for "title." The default implementation of -setTitle: copies the passed-in object ("title" is an attribute). This property is here because so many anticipated uses of this class will involve letting the user choose among multiple named views using a pulldown menu or something like that.
 */
- (void)setTitle:(NSString *)aTitle {
	NSString *copy = [aTitle copy];
	[title release];
	title = copy;
}


- (NSString *)title {
	NSLog(@"[%@ %@] subclass should override!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	return title;
}

- (NSWindow *)window {
	return window;
}

@end
