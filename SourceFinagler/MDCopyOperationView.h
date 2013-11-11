//
//  MDCopyOperationView.h
//  Copy Progress Window
//
//  Created by Mark Douma on 4/4/2006.
//  Copyright (c) 2006 Mark Douma. All rights reserved.
//


#import <Cocoa/Cocoa.h>

enum {
	MDWhiteBackgroundColorType			= 0,
	MDAlternateBackgroundColorType		= 1
};
typedef NSUInteger MDCopyOperationViewBackgroundColorType;

@class MDCopyOperationSeparatorView;

@interface MDCopyOperationView : NSView {
	MDCopyOperationSeparatorView				*separatorView;
	
	MDCopyOperationViewBackgroundColorType		colorType;
	NSLock										*lock;
	
	NSInteger									tag;
	
	
	NSColor										*whiteColor;
	NSColor										*alternateColor;
}

@property (retain) MDCopyOperationSeparatorView *separatorView;

@property (assign) MDCopyOperationViewBackgroundColorType colorType;
@property (assign) NSInteger tag;


- (void)switchColorType;

+ (NSSize)copyOperationViewSize;

@end



