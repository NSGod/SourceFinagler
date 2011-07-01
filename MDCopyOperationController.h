//
//  MDCopyProgressController.h
//  Source Finagler
//
//  Created by Mark Douma on 4/4/2006.
//  Copyright (c) 2006 Mark Douma. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "MDCopyOperationView.h"


@class MDCopyOperation, MDCopyOperationContentView;

@interface MDCopyOperationController : NSWindowController {
	
	IBOutlet MDCopyOperationContentView			*contentView;
	
	NSMutableArray								*operations;
	
	NSMutableDictionary							*viewControllersAndTags;
	
	MDCopyOperationViewBackgroundColorType		colorType;
	
	NSInteger									tag;
	
}

+ (MDCopyOperationController *)sharedController;


@property (assign) NSInteger tag;
@property (assign) MDCopyOperationViewBackgroundColorType colorType;


- (void)addOperation:(MDCopyOperation *)operation;
- (void)endOperation:(MDCopyOperation *)operation;


@end



