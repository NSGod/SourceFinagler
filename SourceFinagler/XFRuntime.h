//
//  XFRuntime.h
//  BlackFire
//
//	Based, in part, on "NSData_XfireAdditions",
//		and "NSMutableData_XfireAdditions" of MacFire,
//	
//	http://www.macfire.org/
//	
//	Copyright 2007-2008, the MacFire.org team.
//	Use of this software is governed by the license terms
//	indicated in the License.txt file (a BSD license).
//
//  Massive re-write by Mark Douma and Antwan van Houdt on 3/19/2010.
//	
//  Created by Mark Douma on 1/30/2010.
//  Copyright (c) 2010 Mark Douma LLC. All rights reserved.
//


#if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))

#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>

#elif (TARGET_OS_EMBEDDED || TARGET_OS_IPHONE)

#import <Foundation/Foundation.h>

#endif


/*	use this to define the types that, unlike NSInteger and NSUInteger, 
	should NOT vary depending on whether we're running on 32 or 64 bit
 
	While some of this might be a bit unnecessary, it helped me while going
	through Archon's Xfire code to modernize the value types, by using
	NSInteger and friends wherever possible.
*/


typedef char					XFInteger8;
typedef unsigned char			XFUInteger8;

typedef short					XFInteger16;
typedef unsigned short			XFUInteger16;

typedef int						XFInteger32;
typedef unsigned int			XFUInteger32;

typedef long long				XFInteger64;
typedef unsigned long long		XFUInteger64;

typedef XFUInteger32			XFIPAddress;
typedef XFUInteger16			XFPort;
typedef XFUInteger32			XFGameID;
typedef XFUInteger32			XFUserID;
typedef XFUInteger32			XFGroupID;

#define XF_UUID_LENGTH			16
#define XF_DID_LENGTH			21


extern NSString *NSStringFromXFIPAddress(XFIPAddress address);
extern XFIPAddress XFIPAddressFromNSString(NSString *address);
extern NSString *NSStringFromXFIPAddressAndPort(XFIPAddress address, XFPort port);
extern NSNumber *XFIntegerKey(XFUInteger8 integerKey);
extern NSString *NSStringFromUserID(XFUserID userID);

extern NSNumber *NSNumberFromXFIPAddress(XFIPAddress address);
extern NSNumber *NSNumberFromXFPort(XFPort port);

extern NSString *XFSaltString();
extern NSData	*XFMonikerFromSessionIDAndSalt(NSData *sessionID, NSString *salt);

extern NSString *XFStripQuakeColors(NSString *string);


@interface NSString (XFAdditions)

- (NSData *)md5Hash;
- (NSString *)md5HexHash;
- (NSData *)sha1Hash;
- (NSString *)sha1HexHash;

//+ (id)stringWithFSRef:(const FSRef *)anFSRef;
//- (BOOL)getFSRef:(FSRef *)anFSRef;

- (BOOL)boolValue;
- (NSString *)stringByAssuringUniqueFilename;

- (NSComparisonResult)caseInsensitiveNumericalCompare:(NSString *)string;
- (NSComparisonResult)localizedCaseInsensitiveNumericalCompare:(NSString *)string;

- (BOOL)containsString:(NSString *)aString;

//- (NSString *)stringByReplacing:(NSString *)value with:(NSString *)newValue;
- (NSString *)slashToColon;
- (NSString *)colonToSlash;

//- (NSString *)stringByTrimmingQuakeColors;
@end

@interface NSData (XFAdditions)
+ (NSData *)zeroedChatID;

- (NSData *)md5Hash;
- (NSString *)md5HexHash;
- (NSData *)sha1Hash;
- (NSString *)sha1HexHash;

- (XFUInteger32)crc32;

- (NSString *)stringRepresentation;
- (NSString *)enhancedDescription;
- (BOOL)isAllZeroes;

- (NSData *)dataByTruncatingZeroedData;

@end


@interface NSArray (XFAdditions)
- (NSString *)applescriptListForStringArray;
@end

@interface NSMutableArray (XFAdditions)
- (NSString *)applescriptListForStringArray;
- (void)insertObjectsFromArray:(NSArray *)array atIndex:(NSUInteger)index;
@end

@interface NSNotificationCenter (XFAdditions)

- (void)postNotificationOnMainThread:(NSNotification *)notification;
- (void)postNotificationOnMainThread:(NSNotification *)notification waitUntilDone:(BOOL)wait;

- (void)postNotificationOnMainThreadWithName:(NSString *)name object:(id)object;
- (void)postNotificationOnMainThreadWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo;
- (void)postNotificationOnMainThreadWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo waitUntilDone:(BOOL)wait;

@end

@interface NSObject (MutableDeepCopy)
- (id)mutableDeepCopy;
@end


