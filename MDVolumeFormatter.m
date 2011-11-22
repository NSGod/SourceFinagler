//
//  MDVolumeFormatter.m
//  Font Finagler
//
//  Created by Mark Douma on 6/19/2009.
//  Copyright © 2009 - 2010 Mark Douma. All rights reserved.
//  


#import "MDVolumeFormatter.h"

#define MILLILITERS_PER_OUNCE 29.5735296

@implementation MDVolumeFormatter

@synthesize unitsType;

- (id)init {
    return [self initWithUnitsType:MDVolumeFormatterDefaultUnitsType];
}


- (id)initWithUnitsType:(MDVolumeFormatterUnitsType)aUnitsType {
    if (self = [super init]) {
        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormat:@"#,###.#"];
        [self setUnitsType:aUnitsType];
    }
    return self;
}


- (void)dealloc {
    [numberFormatter release];
    [super dealloc];
}


- (NSString *)stringForObjectValue:(id)anObject {
    if ([anObject isKindOfClass:[NSNumber class]]) {
        NSString *string = nil;
        if (unitsType == MDVolumeFormatterMetricUnitsType) {
            string = [[numberFormatter stringForObjectValue:
                       [NSNumber numberWithFloat:
                        [(NSNumber *)anObject floatValue] * MILLILITERS_PER_OUNCE]]
                      stringByAppendingString:@" ml"];
            
        } else {
            string = [[numberFormatter stringForObjectValue:anObject] stringByAppendingString:@" oz"];
        }
        return string;
    }
    return nil;
}


@end



