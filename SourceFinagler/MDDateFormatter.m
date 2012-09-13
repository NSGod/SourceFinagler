//
//  MDDateFormatter.m
//  Font Finagler
//
//  Created by Mark Douma on 6/19/2009.
//  Copyright © 2009 - 2010 Mark Douma. All rights reserved.
//  


#import "MDDateFormatter.h"


#pragma mark view
#define MD_DEBUG 0

static const NSTimeInterval MDNilDateTimeIntervalSinceReferenceDate = -3061152000.0;

static NSDate *MDNilDate = nil;


@implementation MDDateFormatter

+ (void)initialize {
	MDNilDate = [[NSDate dateWithTimeIntervalSinceReferenceDate:MDNilDateTimeIntervalSinceReferenceDate] retain];
}


- (id)initWithStyle:(MDDateFormatterStyle)aStyle isRelative:(BOOL)value {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if ((self = [super init])) {
		style = -1;
		relative = YES;
		
		__mdFormatter = NULL;
		__mdTimeFormatter = NULL;
		
		CFLocaleRef currentLocale = CFLocaleCopyCurrent();
		
		__mdTimeFormatter = CFDateFormatterCreate(NULL, currentLocale, MDDateFormatterNoStyle, MDDateFormatterShortStyle);
		
		CFRelease(currentLocale);
		
		
		[self setStyle:aStyle];
		[self setRelative:value];
		
		today = @"Today";
		yesterday = @"Yesterday";
		tomorrow = @"Tomorrow";
		
		today = NSLocalizedString(@"Today", @"");
		yesterday = NSLocalizedString(@"Yesterday", @"");
		tomorrow = NSLocalizedString(@"Tomorrow", @"");
		
		[today retain];
		[yesterday retain];
		[tomorrow retain];
		
		
	}
	return self;
}



- (id)initWithCoder:(NSCoder *)coder {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if ((self = [super initWithCoder:coder])) {
		style = -1;
		relative = YES;
		
		__mdFormatter = NULL;
		__mdTimeFormatter = NULL;
		
		CFLocaleRef currentLocale = CFLocaleCopyCurrent();
		
		__mdTimeFormatter = CFDateFormatterCreate(NULL, currentLocale, MDDateFormatterNoStyle, MDDateFormatterShortStyle);
		
		CFRelease(currentLocale);
		
		
		[self setStyle:[[coder decodeObjectForKey:@"MDStyle"] longValue]];
		[self setRelative:[[coder decodeObjectForKey:@"MDRelative"] boolValue]];
		

		today = @"Today";
		yesterday = @"Yesterday";
		tomorrow = @"Tomorrow";
		
		today = NSLocalizedString(@"Today", @"");
		yesterday = NSLocalizedString(@"Yesterday", @"");
		tomorrow = NSLocalizedString(@"Tomorrow", @"");
		
		[today retain];
		[yesterday retain];
		[tomorrow retain];
		
		
	}
	return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[super encodeWithCoder:coder];
	
	[coder encodeObject:[NSNumber numberWithLong:style] forKey:@"MDStyle"];
	[coder encodeObject:[NSNumber numberWithBool:relative] forKey:@"MDRelative"];
	
}



- (id)copyWithZone:(NSZone *)zone {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	MDDateFormatter *copy = [[[self class] allocWithZone:zone] initWithStyle:[self style] isRelative:[self isRelative]];
	
	return copy;
}



- (void)dealloc {
	if (__mdFormatter != NULL) {
		CFRelease(__mdFormatter);
		__mdFormatter = NULL;
	}
	if (__mdTimeFormatter != NULL) {
		CFRelease(__mdTimeFormatter);
		__mdTimeFormatter = NULL;
	}
	
	[today release];
	[yesterday release];
	[tomorrow release];
	
	[super dealloc];
}


- (MDDateFormatterStyle)style {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    return style;
}


- (void)setStyle:(MDDateFormatterStyle)value {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (style != value) {
		style = value;
		if (__mdFormatter != NULL) {
			CFRelease(__mdFormatter);
			__mdFormatter = NULL;
		}
		CFLocaleRef currentLocale = CFLocaleCopyCurrent();
		if (style == MDDateFormatterFullStyle) {
			__mdFormatter = CFDateFormatterCreate(NULL, currentLocale, MDDateFormatterFullStyle, MDDateFormatterShortStyle);
		} else if (style == MDDateFormatterLongStyle) {
			__mdFormatter = CFDateFormatterCreate(NULL, currentLocale, MDDateFormatterLongStyle, MDDateFormatterShortStyle);
		} else if (style == MDDateFormatterMediumStyle) {
			__mdFormatter = CFDateFormatterCreate(NULL, currentLocale, MDDateFormatterMediumStyle, MDDateFormatterShortStyle);
		} else if (style == MDDateFormatterShortStyle) {
			__mdFormatter = CFDateFormatterCreate(NULL, currentLocale, MDDateFormatterShortStyle, MDDateFormatterShortStyle);
		} else if (style == MDDateFormatterNoStyle) {
			__mdFormatter = CFDateFormatterCreate(NULL, currentLocale, MDDateFormatterShortStyle, MDDateFormatterNoStyle);
		}
		CFRelease(currentLocale);
	}
}


- (BOOL)isRelative {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    return relative;
}

- (void)setRelative:(BOOL)value {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	relative = value;
}


- (NSString *)stringForObjectValue:(id)anObject {
#if MD_DEBUG
	NSLog(@"[%@ %@] anObject == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), anObject);
#endif
	
	if ([anObject isKindOfClass:[NSDate class]]) {
//		NSLog(@"[%@ %@] timeIntervalSinceReferenceDate == %f; MDNilDate == %@, %f", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [anObject timeIntervalSinceReferenceDate], MDNilDate, [MDNilDate timeIntervalSinceReferenceDate]);
	
		if ([anObject isEqualToDate:MDNilDate]) {
			return NSLocalizedString(@"--", @"");
		}
		
		NSString *string = nil;

//		NSLog(@"[%@ %@] it is an NSDate == %@, __mdFormatter == %@, __mdTimeFormatter == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), anObject, __mdFormatter, __mdTimeFormatter);

		if (relative) {
			
			NSCalendarDate *calendarDate = [[[NSCalendarDate alloc] initWithTimeIntervalSinceReferenceDate:[anObject timeIntervalSinceReferenceDate]] autorelease];
			
			NSInteger todaysDayOfCommonEra = [[NSCalendarDate calendarDate] dayOfCommonEra];
			NSInteger datesDayOfCommonEra = [calendarDate dayOfCommonEra];
			
			if (datesDayOfCommonEra < (todaysDayOfCommonEra - 1)) {
				
				string = (NSString *)CFDateFormatterCreateStringWithDate(NULL, __mdFormatter, (CFDateRef)anObject);
				
			} else if (datesDayOfCommonEra == (todaysDayOfCommonEra - 1)) {
				/* Yesterday, %@ */
				
				NSString *timeString = (NSString *)CFDateFormatterCreateStringWithDate(NULL, __mdTimeFormatter, (CFDateRef)anObject);
				[timeString autorelease];
				
				string = [[NSString alloc] initWithFormat:@"%@, %@", yesterday, timeString];
				
			} else if (datesDayOfCommonEra == todaysDayOfCommonEra) {
				/* Today, %@ */
				
				NSString *timeString = (NSString *)CFDateFormatterCreateStringWithDate(NULL, __mdTimeFormatter, (CFDateRef)anObject);
				[timeString autorelease];
				
				string = [[NSString alloc] initWithFormat:@"%@, %@", today, timeString];
				
			} else if (datesDayOfCommonEra == (todaysDayOfCommonEra + 1)) {
				/* Tomorrow, %@ */
				NSString *timeString = (NSString *)CFDateFormatterCreateStringWithDate(NULL, __mdTimeFormatter, (CFDateRef)anObject);
				[timeString autorelease];
				
				string = [[NSString alloc] initWithFormat:@"%@, %@", tomorrow, timeString];
				
			} else if (datesDayOfCommonEra > (todaysDayOfCommonEra + 1)) {
				
				string = (NSString *)CFDateFormatterCreateStringWithDate(NULL, __mdFormatter, (CFDateRef)anObject);
			}
			
		} else {
			string = (NSString *)CFDateFormatterCreateStringWithDate(NULL, __mdFormatter, (CFDateRef)anObject);
		}
		
		return [string autorelease];
	}
	return nil;
}


- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	BOOL returnValue = NO;
	NSDate *date = nil;
	
	date = (NSDate *)CFDateFormatterCreateDateFromString(NULL, __mdFormatter, (CFStringRef)string, NULL);
	
	if (date) {
		returnValue = YES;
	}
	
	[date autorelease];
	
	return returnValue;
}


- (NSAttributedString *)attributedStringForObjectValue:(id)obj withDefaultAttributes:(NSDictionary *)attrs {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	return nil;
}



@end


