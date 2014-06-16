//
//  MDPrefsController.h
//  Source Finagler
//
//  Created by Mark Douma on 9/12/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MDPrefsController : NSWindowController <NSToolbarDelegate> {
	NSMutableArray				*viewControllers;
	NSUInteger					currentViewIndex;
}

- (IBAction)changeView:(id)sender;

@end


