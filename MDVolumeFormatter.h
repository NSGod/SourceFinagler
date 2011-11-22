//
//  MDVolumeFormatter.h
//  Font Finagler
//
//  Created by Mark Douma on 6/19/2009.
//  Copyright © 2009 - 2010 Mark Douma. All rights reserved.
//  


#import <Foundation/Foundation.h>

enum {
	MDVolumeFormatterMetricUnitsType			= 1,
	MDVolumeFormatterOurStupidAmericanUnitsType	= 2,
	MDVolumeFormatterDefaultUnitsType = MDVolumeFormatterMetricUnitsType
};

typedef NSUInteger MDVolumeFormatterUnitsType;


@interface MDVolumeFormatter : NSFormatter {
	MDVolumeFormatterUnitsType			unitsType;
	NSNumberFormatter					*numberFormatter;
}
- (id)initWithUnitsType:(MDVolumeFormatterUnitsType)aUnitsType;

@property (assign) MDVolumeFormatterUnitsType unitsType;

@end

