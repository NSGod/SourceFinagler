//
//  MDFileAdditions.h
//  Source Finagler
//
//  Created by Mark Douma on 9/30/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDFile.h"

#if defined(MD_BUILDING_FOR_SOURCE_ADDON_FINAGLER)
@class NSSound;
#else
@class NSImage, NSSound, QTMovie;
#endif

@interface MDFile (MDAdditions)

- (NSString *)stringValue;
- (NSString *)stringValueByExtractingToTempFile:(BOOL)shouldExtractToTempFile;

- (NSSound *)sound;

#if !defined(MD_BUILDING_FOR_SOURCE_ADDON_FINAGLER)
- (NSImage *)image;
- (QTMovie *)movie;
#endif
@end


