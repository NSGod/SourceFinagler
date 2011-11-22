//
//  MDController.h
//  Source Finagler
//
//  Created by Mark Douma on 3/02/2006.
//  Copyright © 2006 Mark Douma. All rights reserved.
//  

#import <Cocoa/Cocoa.h>


@interface MDController : NSObject {
	IBOutlet NSView		*view;
	
	BOOL				resizable;
	NSSize				minWinSize;
	NSSize				maxWinSize;
	
}
- (void)appControllerDidLoadNib:(id)sender;
- (NSView *)view;
- (void)didSwitchToView:(id)sender;
- (void)cleanup;
@end



