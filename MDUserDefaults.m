//
//  MDUserDefaults.m
//  Font Finagler
//
//  Created by Mark Douma on 1/30/2008.
//  Copyright © 2008-2011 Mark Douma. All rights reserved.
//  


#import "MDUserDefaults.h"

static MDUserDefaults *sharedUserDefaults = nil;


@implementation MDUserDefaults


+ (MDUserDefaults *)standardUserDefaults {
	if (sharedUserDefaults == nil) {
		sharedUserDefaults = [[super allocWithZone:NULL] init];
	}
	return sharedUserDefaults;
}


+ (id)allocWithZone:(NSZone *)zone {
	return [[self standardUserDefaults] retain];
}


- (id)copyWithZone:(NSZone *)zone {
	return self;
}


- (id)retain {
	return self;
}


- (NSUInteger)retainCount {
	return NSUIntegerMax;	//denotes an object that cannot be released
}


- (oneway void)release {
	// do nothing
}


- (id)autorelease {
	return self;
}

- (void)setObject:(id)anObject forKey:(NSString *)aKey forAppIdentifier:(NSString *)anIdentifier inDomain:(MDUserDefaultsDomain)aDomain {
	
	if (anIdentifier == nil) anIdentifier = (NSString *)kCFPreferencesAnyApplication;
	
	if (aDomain == MDUserDefaultsLocalDomain) {
		CFPreferencesSetValue((CFStringRef)aKey, anObject, (CFStringRef)anIdentifier, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
		CFPreferencesSynchronize((CFStringRef)anIdentifier, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
		
	} else if (aDomain == MDUserDefaultsUserDomain) {
		CFPreferencesSetValue((CFStringRef)aKey, anObject, (CFStringRef)anIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		CFPreferencesSynchronize((CFStringRef)anIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	}
}


- (id)objectForKey:(NSString *)aKey forAppIdentifier:(NSString *)anIdentifier inDomain:(MDUserDefaultsDomain)aDomain {
	
	if (anIdentifier == nil) anIdentifier = (NSString *)kCFPreferencesAnyApplication;
	
	id anObject = nil;
	
	if (aDomain == MDUserDefaultsLocalDomain) {
		CFPreferencesSynchronize((CFStringRef)anIdentifier, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
	} else if (aDomain == MDUserDefaultsUserDomain) {
		CFPreferencesSynchronize((CFStringRef)anIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	}
	
	if (aDomain == MDUserDefaultsLocalDomain) {
		anObject = [(id)CFPreferencesCopyValue((CFStringRef)aKey, (CFStringRef)anIdentifier, kCFPreferencesAnyUser, kCFPreferencesCurrentHost) autorelease];
		
	} else if (aDomain == MDUserDefaultsUserDomain) {
		anObject = [(id)CFPreferencesCopyValue((CFStringRef)aKey, (CFStringRef)anIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) autorelease];
	}
	return anObject;
}



- (void)removeObjectForKey:(NSString *)aKey forAppIdentifier:(NSString *)anIdentifier inDomain:(MDUserDefaultsDomain)aDomain {
	
	if (anIdentifier == nil) anIdentifier = (NSString *)kCFPreferencesAnyApplication;
	
	if (aDomain == MDUserDefaultsLocalDomain) {
		
		CFPreferencesSetValue((CFStringRef)aKey, NULL, (CFStringRef)anIdentifier, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
		CFPreferencesSynchronize((CFStringRef)anIdentifier, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
		
	} else if (aDomain == MDUserDefaultsUserDomain) {
		
		CFPreferencesSetValue((CFStringRef)aKey, NULL, (CFStringRef)anIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		CFPreferencesSynchronize((CFStringRef)anIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		
	} else if (aDomain == MDUserDefaultsLocalAndUserDomain) {
		
		CFPreferencesSetValue((CFStringRef)aKey, NULL, (CFStringRef)anIdentifier, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
		CFPreferencesSynchronize((CFStringRef)anIdentifier, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
		
		CFPreferencesSetValue((CFStringRef)aKey, NULL, (CFStringRef)anIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		CFPreferencesSynchronize((CFStringRef)anIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	}
}


@end


