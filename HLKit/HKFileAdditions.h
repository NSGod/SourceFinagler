//
//  HKFileAdditions.h
//  HLKit
//
//  Created by Mark Douma on 9/30/2010.
//  Copyright (c) 2009-2012 Mark Douma LLC. All rights reserved.
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


