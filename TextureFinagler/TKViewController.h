//
//  TKViewController.h
//  Source Finagler
//
//  Created by Mark Douma on 4/14/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString * const TKViewControllerViewDidChangeNotification;


@interface TKViewController : NSResponder {
	
	IBOutlet NSWindow		*window;	// non-retained
    IBOutlet NSView			*view;
	
    NSString				*nibName;
    NSBundle				*nibBundle;
    NSString				*title;

	NSSize					minSize;
	NSSize					maxSize;
	BOOL					isResizable;
}

- (id)initWithWindow:(NSWindow *)aWindow;

/* The designated initializer. The specified nib should typically have the class of the file's owner set to NSViewController, or a subclass of yours, with the "view" outlet connected to a view. If you pass in a nil nib name then -nibName will return nil and -loadView will throw an exception; you most likely must also invoke -setView: before -view is invoked, or override -loadView. If you pass in a nil bundle then -nibBundle will return nil and -loadView will interpret it using the same rules as -[NSNib initWithNibNamed:bundle:].
*/
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;


/* The localized title of the view. This class doesn't actually do anything with the value of this property other than hold onto it, and be KVC and KVO compliant for "title." The default implementation of -setTitle: copies the passed-in object ("title" is an attribute). This property is here because so many anticipated uses of this class will involve letting the user choose among multiple named views using a pulldown menu or something like that.
*/

@property (copy) NSString *title;


/* Return the view. The default implementation of this method first invokes [self loadView] if the view hasn't been set yet.
*/
- (NSView *)view;

/* Instantiate the view and then set it. The default implementation of this method invokes [self nibName] and [self nibBundle] and then uses the NSNib class to load the nib with this object as the file's owner. If the "view" outlet of the file's owner in the nib is properly connected, the regular nib loading machinery will send this object a -setView: message. You can override this method to customize how nib loading is done, including merely adding new behavior immediately before or immediately after nib loading done by the default implementation. You should not invoke this method from other objects unless you take care to avoid redundant invocations; NSViewController's default implement can handle them but overrides in subclasses might not. (Typically other objects should instead invoke -view and let the view controller do whatever it takes to fulfill the request.)
*/
- (void)loadView;

/* Return the name of the nib to be loaded to instantiate the view, and the bundle from which to load it. The default implementations of these merely return whatever value was passed to the initializer.
*/
- (NSString *)nibName;
- (NSBundle *)nibBundle;

/* Set the view. You can invoke this method immediately after creating the object to specify a view that's created in a different manner than what -view's default implementation would do.
*/
- (void)setView:(NSView *)aView;


- (void)viewControllerDidLoadNib;


- (void)viewDidChange:(NSNotification *)notification;

- (NSWindow *)window;

@end


