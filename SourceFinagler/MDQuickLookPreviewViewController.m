//
//  MDQuickLookPreviewViewController.m
//  ComplexBrowser
//
//  Created by Mark Douma on 6/27/2009.
//  Copyright 2009 Mark Douma. All rights reserved.
//

#import "MDQuickLookPreviewViewController.h"


#define MD_DEBUG 0


@implementation MDQuickLookPreviewViewController


- (id)initWithCoder:(NSCoder *)coder {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithCoder:coder])) {
		isQuickLookPanel = YES;
	}
	return self;
}


@end

