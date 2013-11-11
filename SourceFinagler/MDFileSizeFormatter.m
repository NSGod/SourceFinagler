//
//  MDFileSizeFormatter.m
//  Font Finagler
//
//  Created by Mark Douma on 6/19/2009.
//  Copyright © 2009 - 2010 Mark Douma. All rights reserved.
//  


#import "MDFileSizeFormatter.h"
#import <CoreServices/CoreServices.h>


enum {
	MDUndeterminedVersion	= -1,
	MDCheetah				= 0x1000,
	MDPuma					= 0x1010,
	MDJaguar				= 0x1020,
	MDPanther				= 0x1030,
	MDTiger					= 0x1040,
	MDLeopard				= 0x1050,
	MDSnowLeopard			= 0x1060,
	MDLion					= 0x1070,
	MDMountainLion			= 0x1080,
	MDUnknownKitty			= 0x1090,
	MDUnknownVersion		= 0x1100
};

#define MD_DEBUG 0

static SInt32 MDSystemVersion = MDUndeterminedVersion;


unsigned long long		MDNumberOfBytesInKB = 1000;
double					MDFloatNumberOfBytesInKB = 1000.0;

NSString * const MDFileSizeFormatterStyleKey		= @"MDFileSizeFormatterStyle";
NSString * const MDFileSizeFormatterUnitsTypeKey	= @"MDFileSizeFormatterUnitsType";


@implementation MDFileSizeFormatter

- (id)copyWithZone:(NSZone *)zone {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	MDFileSizeFormatter *copy = [[[self class] allocWithZone:zone] initWithUnitsType:[self unitsType] style:[self style]];
	return copy;
}


- (id)init {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self initWithUnitsType:MDFileSizeFormatterAutomaticUnitsType style:MDFileSizeFormatterPhysicalStyle];
}


- (id)initWithUnitsType:(MDFileSizeFormatterUnitsType)aUnitsType style:(MDFileSizeFormatterStyle)aStyle {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		numberFormatter = [[NSNumberFormatter alloc] init];
		[self setUnitsType:aUnitsType];
		[self setStyle:aStyle];
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)coder {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithCoder:coder])) {
		numberFormatter = [[NSNumberFormatter alloc] init];
		
		NSNumber *unitsTypeNum = [coder decodeObjectForKey:MDFileSizeFormatterUnitsTypeKey];
		
		if (unitsTypeNum == nil) {
			// old version archive
			[self setUnitsType:(MDFileSizeFormatterUnitsType) [[coder decodeObjectForKey:MDFileSizeFormatterStyleKey] unsignedLongLongValue]];
			[self setStyle:MDFileSizeFormatterPhysicalStyle];
		} else {
			// current version archive
			[self setUnitsType:(MDFileSizeFormatterUnitsType) [[coder decodeObjectForKey:MDFileSizeFormatterUnitsTypeKey] unsignedLongLongValue]];
			[self setStyle:(MDFileSizeFormatterStyle) [[coder decodeObjectForKey:MDFileSizeFormatterStyleKey] unsignedLongLongValue]];
		}
	}
	return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super encodeWithCoder:coder];
	
	[coder encodeObject:[NSNumber numberWithUnsignedLongLong:(unsigned long long)unitsType] forKey:MDFileSizeFormatterUnitsTypeKey];
	[coder encodeObject:[NSNumber numberWithUnsignedLongLong:(unsigned long long)style] forKey:MDFileSizeFormatterStyleKey];
}


- (void)dealloc {
	[numberFormatter release];
	[bytesFormatter release];
	[super dealloc];
}


- (MDFileSizeFormatterUnitsType)unitsType {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    return unitsType;
}

- (void)setUnitsType:(MDFileSizeFormatterUnitsType)aUnitsType {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	unitsType = aUnitsType;
	if (unitsType == MDFileSizeFormatterAutomaticUnitsType) {
		MDSystemVersion = MDUndeterminedVersion;
		SInt32 fullSystemVersion = 0;
		Gestalt(gestaltSystemVersion, &fullSystemVersion);
		MDSystemVersion = fullSystemVersion & 0xfffffff0;
		MDNumberOfBytesInKB			= (MDSystemVersion < MDSnowLeopard ? 1024 : 1000);
		MDFloatNumberOfBytesInKB	= (MDSystemVersion < MDSnowLeopard ? 1024.0 : 1000.0);
		
	} else if (unitsType == MDFileSizeFormatter1000BytesInKBUnitsType) {
		MDNumberOfBytesInKB			= 1000;
		MDFloatNumberOfBytesInKB	= 1000.0;
		
	} else if (unitsType == MDFileSizeFormatter1024BytesInKBUnitsType) {
		MDNumberOfBytesInKB			= 1024;
		MDFloatNumberOfBytesInKB	= 1024.0;
	}
}


- (MDFileSizeFormatterStyle)style {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return style;
}

- (void)setStyle:(MDFileSizeFormatterStyle)aStyle {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	style = aStyle;
	if (style == MDFileSizeFormatterFullStyle) {
		if (bytesFormatter == nil) bytesFormatter = [[NSNumberFormatter alloc] init];
		[bytesFormatter setFormat:@"#,##0"];
	} else {
		[bytesFormatter release]; bytesFormatter = nil;
	}
}


- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	NSLog(@"[%@ %@] string == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), string);
#endif
	if (anObject) *anObject = nil;
	
	if (outError) *outError = @"Why the hell is this being called?";
	return NO;
}


- (NSString *)stringForObjectValue:(id)anObject {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([anObject isKindOfClass:[NSNumber class]]) {

		if ([anObject longLongValue] == -1) return @"--";

		unsigned long long size = [anObject unsignedLongLongValue];

		NSNumber *sizeNumber = nil;
		NSString *sizeString = nil;
		
		if (size) {
				if (size < MDNumberOfBytesInKB) {
					[numberFormatter setFormat:@"#,##0"];
					
					if (style == MDFileSizeFormatterFullStyle) {
						
						sizeString = [NSString stringWithFormat:NSLocalizedString(@"1 KB (%@ bytes)", @""), [bytesFormatter stringForObjectValue:anObject]];
						
					} else if (style == MDFileSizeFormatterLogicalStyle) {
						sizeString = [[numberFormatter stringForObjectValue:anObject] stringByAppendingString:NSLocalizedString(@" bytes", @"")];
						
					} else if (style == MDFileSizeFormatterPhysicalStyle) {
						sizeString = NSLocalizedString(@"1 KB", @"");
					}
					
				} else if (size < MDNumberOfBytesInKB * MDNumberOfBytesInKB) {
					
					[numberFormatter setFormat:@"#,##0"];
					sizeNumber = [NSNumber numberWithUnsignedLongLong:((size + (MDNumberOfBytesInKB/2))/MDNumberOfBytesInKB)];
					
					if (style == MDFileSizeFormatterFullStyle) {
						
						sizeString = [NSString stringWithFormat:NSLocalizedString(@"%@ KB (%@ bytes)", @""), [numberFormatter stringForObjectValue:sizeNumber], [bytesFormatter stringForObjectValue:anObject]];
						
					} else {
						sizeString = [[numberFormatter stringForObjectValue:sizeNumber] stringByAppendingString:NSLocalizedString(@" KB", @"")];
					}
					
				} else if (size < MDNumberOfBytesInKB * MDNumberOfBytesInKB * MDNumberOfBytesInKB) {
					
					[numberFormatter setFormat:@"#,###.#"];
					sizeNumber = [NSNumber numberWithDouble:(double)((double)size/(MDFloatNumberOfBytesInKB * MDFloatNumberOfBytesInKB))];
					
					if (style == MDFileSizeFormatterFullStyle) {
						
						sizeString = [NSString stringWithFormat:NSLocalizedString(@"%@ MB (%@ bytes)", @""), [numberFormatter stringForObjectValue:sizeNumber], [bytesFormatter stringForObjectValue:anObject]];
						
					} else {
						sizeString = [[numberFormatter stringForObjectValue:sizeNumber] stringByAppendingString:NSLocalizedString(@" MB", @"")];
						
					}
					
				} else if (size < (UInt64)MDNumberOfBytesInKB * MDNumberOfBytesInKB * MDNumberOfBytesInKB * MDNumberOfBytesInKB) {
					
					[numberFormatter setFormat:@"#,###.##"];
					sizeNumber = [NSNumber numberWithDouble:(double)((double)size/(MDFloatNumberOfBytesInKB * MDFloatNumberOfBytesInKB * MDFloatNumberOfBytesInKB))];
					
					if (style == MDFileSizeFormatterFullStyle) {
						
						sizeString = [NSString stringWithFormat:NSLocalizedString(@"%@ GB (%@ bytes)", @""), [numberFormatter stringForObjectValue:sizeNumber], [bytesFormatter stringForObjectValue:anObject]];
						
					} else {
						sizeString = [[numberFormatter stringForObjectValue:sizeNumber] stringByAppendingString:NSLocalizedString(@" GB", @"")];
						
					}
					
				} else if (size < (UInt64)MDNumberOfBytesInKB * MDNumberOfBytesInKB * MDNumberOfBytesInKB * MDNumberOfBytesInKB * MDNumberOfBytesInKB) {
					
					[numberFormatter setFormat:@"#,###.##"];
					sizeNumber = [NSNumber numberWithDouble:(double)(size/(MDFloatNumberOfBytesInKB * MDFloatNumberOfBytesInKB * MDFloatNumberOfBytesInKB * MDFloatNumberOfBytesInKB))];
					
					if (style == MDFileSizeFormatterFullStyle) {
						
						sizeString = [NSString stringWithFormat:NSLocalizedString(@"%@ TB (%@ bytes)", @""), [numberFormatter stringForObjectValue:sizeNumber], [bytesFormatter stringForObjectValue:anObject]];
						
					} else {
						sizeString = [[numberFormatter stringForObjectValue:sizeNumber] stringByAppendingString:NSLocalizedString(@" TB", @"")];
						
					}
					
				} else if (size < (UInt64)MDNumberOfBytesInKB*MDNumberOfBytesInKB*MDNumberOfBytesInKB*MDNumberOfBytesInKB*MDNumberOfBytesInKB * MDNumberOfBytesInKB) {
					
					[numberFormatter setFormat:@"#,###.##"];
					sizeNumber = [NSNumber numberWithDouble:(double)(size/(MDFloatNumberOfBytesInKB*MDFloatNumberOfBytesInKB*MDFloatNumberOfBytesInKB*MDFloatNumberOfBytesInKB*MDFloatNumberOfBytesInKB))];
					
					if (style == MDFileSizeFormatterFullStyle) {
						
						sizeString = [NSString stringWithFormat:NSLocalizedString(@"%@ PB (%@ bytes)", @""), [numberFormatter stringForObjectValue:sizeNumber], [bytesFormatter stringForObjectValue:anObject]];
						
					} else {
						sizeString = [[numberFormatter stringForObjectValue:sizeNumber] stringByAppendingString:NSLocalizedString(@" PB", @"")];
					}
					
				} else if (size < (UInt64)MDNumberOfBytesInKB*MDNumberOfBytesInKB*MDNumberOfBytesInKB*MDNumberOfBytesInKB*MDNumberOfBytesInKB*MDNumberOfBytesInKB*MDNumberOfBytesInKB) {
					
					[numberFormatter setFormat:@"#,###.##"];
					sizeNumber = [NSNumber numberWithDouble:(double)(size/(MDFloatNumberOfBytesInKB*MDFloatNumberOfBytesInKB*MDFloatNumberOfBytesInKB*MDFloatNumberOfBytesInKB*MDFloatNumberOfBytesInKB*MDFloatNumberOfBytesInKB))];
					
					if (style == MDFileSizeFormatterFullStyle) {
						
						sizeString = [NSString stringWithFormat:NSLocalizedString(@"%@ EB (%@ bytes)", @""), [numberFormatter stringForObjectValue:sizeNumber], [bytesFormatter stringForObjectValue:anObject]];
						
					} else {
						sizeString = [[numberFormatter stringForObjectValue:sizeNumber] stringByAppendingString:NSLocalizedString(@" EB", @"")];
					}
				}
				return sizeString;
		}
		return (style == MDFileSizeFormatterFullStyle ? NSLocalizedString(@"Zero KB (Zero bytes)", @"") : NSLocalizedString(@"Zero KB", @""));
	}
	return nil;
}


@end



