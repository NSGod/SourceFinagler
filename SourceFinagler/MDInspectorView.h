//
//  MDInspectorView.h
//  MDInspectorView
//
//  Created by Mark Douma on 8/14/2007.
//  Copyright © 2008 Mark Douma . All rights reserved.
//  


#import <Cocoa/Cocoa.h>


@protocol MDInspectorViewDelegate <NSObject>
@optional

/*  Notifications  */
- (void)inspectorViewWillShow:(NSNotification *)notification;
- (void)inspectorViewDidShow:(NSNotification *)notification;

- (void)inspectorViewWillHide:(NSNotification *)notification;
- (void)inspectorViewDidHide:(NSNotification *)notification;

@end

extern NSString * const MDInspectorViewWillShowNotification;
extern NSString * const MDInspectorViewDidShowNotification;

extern NSString * const MDInspectorViewWillHideNotification;
extern NSString * const MDInspectorViewDidHideNotification;



@interface MDInspectorView : NSView <NSCoding> {
	
	IBOutlet NSButton						*titleButton;
	IBOutlet NSButton						*disclosureButton;
	
	IBOutlet id <MDInspectorViewDelegate>	delegate;
	
	NSString								*autosaveName;
	
	NSArray									*hiddenSubviews;
	
    NSView									*nonretainedOriginalNextKeyView;
    NSView									*nonretainedLastChildKeyView;
	
	CGFloat									originalHeight;
	CGFloat									hiddenHeight;
	
	NSSize									sizeBeforeHidden;
	
	BOOL									isInitiallyShown;
	
	BOOL									isShown;
	
	BOOL									havePendingWindowHeightChange;
}

- (IBAction)toggleShown:(id)sender;

- (BOOL)isShown;
- (void)setShown:(BOOL)value;


- (NSButton *)titleButton;
- (void)setTitleButton:(NSButton *)value;

- (NSButton *)disclosureButton;
- (void)setDisclosureButton:(NSButton *)value;

- (NSString *)autosaveName;
- (void)setAutosaveName:(NSString *)value;

- (BOOL)isInitiallyShown;
- (void)setInitiallyShown:(BOOL)value;

- (id <MDInspectorViewDelegate>)delegate;
- (void)setDelegate:(id <MDInspectorViewDelegate>)aDelegate;


//- (NSString *)identifier						DEPRECATED_ATTRIBUTE;
//- (void)setIdentifier:(NSString *)anIdentifier	DEPRECATED_ATTRIBUTE;

- (void)changeWindowHeightBy:(CGFloat)value;

@end



