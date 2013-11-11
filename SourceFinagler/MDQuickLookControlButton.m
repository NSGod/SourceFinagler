//
//  MDQuickLookButton.m
//  Source Finagler
//
//  Created by Mark Douma on 2/24/2009.
//  Copyright 2009 Mark Douma. All rights reserved.
//

#import "MDQuickLookControlButton.h"

@interface MDQuickLookControlButton (MDPrivate)
- (void)finishSetup;
@end



#define MD_DEBUG 0




@implementation MDQuickLookControlButton



- (id)initWithFrame:(NSRect)frame {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithFrame:frame])) {
		[self finishSetup];
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)coder {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithCoder:coder])) {
		[self finishSetup];
	}
	return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super encodeWithCoder:coder];
}



- (void)finishSetup {

}


//- (void)dealloc {
//
//	[super dealloc];
//	
//}


- (BOOL)acceptsFirstResponder {
#if MD_DEBUG
	BOOL accepts = [super acceptsFirstResponder];
	NSLog(@"[%@ %@] super's acceptsFirstResponder == %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), accepts);
#endif
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


@end
