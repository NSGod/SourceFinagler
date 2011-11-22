//
//  MDFolderAdditions.m
//  Source Finagler
//
//  Created by Mark Douma on 9/30/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDFolderAdditions.h"
#import "MDHLDocument.h"
#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>


@implementation MDFolder (MDAdditions)

- (NSImage *)image {
	NSImage *image = MDCopiedImageForItem(self);
	[image setSize:NSMakeSize(128.0, 128.0)];
	return image;
}

- (QTMovie *)movie {
	return nil;
}


@end
