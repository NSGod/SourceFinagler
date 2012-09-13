//
//  MDFileSizeFormatter.h
//  Font Finagler
//
//  Created by Mark Douma on 6/19/2009.
//  Copyright © 2009 - 2010 Mark Douma. All rights reserved.
//  


#import <Foundation/Foundation.h>

enum {
	MDFileSizeFormatterAutomaticUnitsType		= 1,
	MDFileSizeFormatter1000BytesInKBUnitsType	= 2,
	MDFileSizeFormatter1024BytesInKBUnitsType	= 3
};

typedef NSUInteger MDFileSizeFormatterUnitsType;

enum {
	MDFileSizeFormatterLogicalStyle		= 0,	// 19,088 bytes
	MDFileSizeFormatterPhysicalStyle	= 1,	// 20 KB
	MDFileSizeFormatterFullStyle		= 2		// 20 KB on disk (19,088 bytes)
};

typedef NSUInteger MDFileSizeFormatterStyle;


@interface MDFileSizeFormatter : NSFormatter <NSCopying, NSCoding> {
	MDFileSizeFormatterUnitsType	unitsType;
	MDFileSizeFormatterStyle		style;
	NSNumberFormatter				*numberFormatter;
	NSNumberFormatter				*bytesFormatter;
}
- (id)initWithUnitsType:(MDFileSizeFormatterUnitsType)aUnitsType style:(MDFileSizeFormatterStyle)aStyle;

- (MDFileSizeFormatterUnitsType)unitsType;
- (void)setUnitsType:(MDFileSizeFormatterUnitsType)aUnitsType;

- (MDFileSizeFormatterStyle)style;
- (void)setStyle:(MDFileSizeFormatterStyle)aStyle;

@end

