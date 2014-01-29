//
//  TKPrefsController.h
//  Source Finagler
//
//  Created by Mark Douma on 9/12/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


enum {
	TKPrefsGeneralView	= 0
};
typedef NSUInteger TKPrefsView;



@interface TKPrefsController : NSWindowController <NSToolbarDelegate> {
	NSMutableArray				*viewControllers;
	TKPrefsView					currentView;
}

- (IBAction)changeView:(id)sender;

@end


