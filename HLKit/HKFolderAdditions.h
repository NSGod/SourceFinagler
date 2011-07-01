//
//  HKFolderAdditions.h
//  Source Finagler
//
//  Created by Mark Douma on 9/30/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKFolder.h>

@class NSImage, QTMovie;

@interface HKFolder (HKAdditions)
- (NSImage *)image;
- (QTMovie *)movie;
@end


