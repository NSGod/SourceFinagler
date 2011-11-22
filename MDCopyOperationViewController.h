//
//  MDCopyOperationViewController.h
//  Source Finagler
//
//  Created by Mark Douma on 11/2/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MDCopyOperationView.h"
#import "MDRolloverButton.h"



@interface MDCopyOperationViewController : NSViewController <MDRolloverButtonDelegate> {
	IBOutlet NSProgressIndicator				*progressIndicator;
	MDCopyOperationViewBackgroundColorType		colorType;
	NSInteger									tag;
	
}

+ (id)viewControllerWithViewColorType:(MDCopyOperationViewBackgroundColorType)aColorType tag:(NSInteger)aTag;
- (id)initWithViewColorType:(MDCopyOperationViewBackgroundColorType)aColorType tag:(NSInteger)aTag;

@property (readonly, assign) NSInteger tag;


- (IBAction)stop:(id)sender;

@end



