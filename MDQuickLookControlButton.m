//
//  MDQuickLookButton.m
//  Source Finagler
//
//  Created by Mark Douma on 2/24/2009.
//  Copyright 2009 Mark Douma. All rights reserved.
//

#import "MDQuickLookControlButton.h"

@interface MDQuickLookControlButton (Private)
- (void)finishSetup;

- (void)_showToolTipWithText:(NSString *)aString;
- (void)_closeToolTip;
- (void)_updateToolTip;
- (void)mouseEntered:(id)sender;
- (void)mouseExited:(id)sender;
- (void)viewWillMoveToWindow:(id)fp8;
- (void)viewDidMoveToWindow;
- (void)viewDidHide;
- (void)viewDidUnhide;
- (void)setTitle:(NSString *)aTitle;

@end

@implementation MDQuickLookControlButton



- (id)initWithFrame:(NSRect)frame {
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	if ((self = [super initWithFrame:frame])) {
		[self finishSetup];
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)coder {
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	if ((self = [super initWithCoder:coder])) {
		[self finishSetup];
	}
	return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	[super encodeWithCoder:coder];
}



- (void)finishSetup {

}


- (void)dealloc {

	[super dealloc];
	
}


- (BOOL)acceptsFirstResponder {
	BOOL accepts = [super acceptsFirstResponder];
	NSLog(@"[%@ %@] super's acceptsFirstResponder == %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), accepts);
	
	return NO;
	
}


- (BOOL)becomeFirstResponder {
	return NO;
}


- (void)_showToolTipWithText:(NSString *)aString {
	
}


- (void)_closeToolTip {
	
}


- (void)_updateToolTip {
	
}


- (void)mouseEntered:(id)sender {
	
}


- (void)mouseExited:(id)sender {
	
	
}


- (void)viewWillMoveToWindow:(id)fp8 {
	
	
}


- (void)viewDidMoveToWindow {
	
	
}



- (void)viewDidHide {
	
	
}


- (void)viewDidUnhide {
	
	
}


- (void)setTitle:(NSString *)aTitle {
	
	
}




//- (void)drawRect:(NSRect)rect {
//    // Drawing code here.
//}

@end
