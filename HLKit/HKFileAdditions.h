//
//  HKFileAdditions.h
//  Source Finagler
//
//  Created by Mark Douma on 9/30/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKFile.h>

@class NSImage, NSSound, QTMovie;

@interface HKFile (HKAdditions)

- (NSString *)stringValue;
- (NSString *)stringValueByExtractingToTempFile:(BOOL)shouldExtractToTempFile;

- (NSImage *)image;

- (NSSound *)sound;

- (QTMovie *)movie;

@end


