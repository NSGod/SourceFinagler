//
//  TKViewController.h
//  Procon Finagler
//
//  Created by Mark Douma on 6/9/2012.
//  Copyright (c) 2012 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TKViewController : NSViewController {
	
	NSSize					minWinSize;
	NSSize					maxWinSize;
	
	BOOL					resizable;
}

@property (nonatomic, assign) NSSize minWinSize;
@property (nonatomic, assign) NSSize maxWinSize;

@property (nonatomic, assign, getter=isResizable) BOOL resizable;


- (void)didSwitchToView:(id)sender;

- (void)cleanup;

- (NSString *)viewControllerViewSizeAutosaveString;

- (NSString *)viewSizeAutosaveName;

- (void)viewDidLoad;


+ (NSSize)windowSizeForViewWithSize:(NSSize)size;

@end


