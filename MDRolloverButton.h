//
//  MDRolloverButton.h
//  Copy Progress Window
//
//  Created by Mark Douma on 4/4/2006.
//  Copyright (c) 2006 Mark Douma. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class MDRolloverButton;


@protocol MDRolloverButtonDelegate <NSObject>
- (void)mouseDidEnterRolloverButton:(MDRolloverButton *)button;
- (void)mouseDidExitRolloverButton:(MDRolloverButton *)button;
@end



@interface MDRolloverButton : NSButton {
	
	IBOutlet id <MDRolloverButtonDelegate> delegate;
}


@end
