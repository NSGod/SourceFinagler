//
//  XFRuntime.m
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

#import "XFRuntime.h"
//#import <Xfire/XFPacket.h>

#import <ApplicationServices/ApplicationServices.h>

#include <arpa/inet.h>
#include <openssl/sha.h>
#include <openssl/md5.h>


NSString *NSStringFromXFIPAddress(XFIPAddress address) {
	address = NSSwapHostIntToLittle(address);
	unsigned char t1, t2, t3, t4;
	
	t1 = (address >> 24) & 0xFF;
	t2 = (address >> 16) & 0xFF;
	t3 = (address >>  8) & 0xFF;
	t4 = (address      ) & 0xFF;
	
	return [NSString stringWithFormat:@"%hu.%hu.%hu.%hu", (unsigned short)t1, (unsigned short)t2, (unsigned short)t3, (unsigned short)t4];
}

//NSString *NSStringFromXFIPAddress(XFIPAddress address) {
//	unsigned char t1, t2, t3, t4;
//	
//	t1 = (address >> 24) & 0xFF;
//	t2 = (address >> 16) & 0xFF;
//	t3 = (address >>  8) & 0xFF;
//	t4 = (address      ) & 0xFF;
//	
//	return [NSString stringWithFormat:@"%hu.%hu.%hu.%hu", (unsigned short)t1, (unsigned short)t2, (unsigned short)t3, (unsigned short)t4];
//}

//NSString *NSStringFromXFIPAddress(XFIPAddress address) {
//	NSString *string = nil;
//	char addressBuffer[INET_ADDRSTRLEN];
//	address = NSSwapHostIntToBig(address);
//	if (inet_ntop(AF_INET, &address, addressBuffer, sizeof(addressBuffer)) != NULL) {
//		string = [NSString stringWithUTF8String:(const char *)addressBuffer];
//	}
//	return string;
//}

NSString *NSStringFromXFIPAddressAndPort(XFIPAddress address, XFPort port) {
	NSString *string = nil;
	NSString *ipAddressString = NSStringFromXFIPAddress(address);
	if (ipAddressString) {
		string = [NSString stringWithFormat:@"%@:%hu", ipAddressString, port];
	}
	return string;
}


XFIPAddress XFIPAddressFromNSString(NSString *address) {
	XFIPAddress ipAddress = 0;
	if (address && [address length]) {
		NSArray *components = [address componentsSeparatedByString:@"."];
		if ([components count] == 4) {
			ipAddress = (([[components objectAtIndex:0] intValue] << 24) |
						 ([[components objectAtIndex:1] intValue] << 16) |
						 ([[components objectAtIndex:2] intValue] <<  8) |
						 ([[components objectAtIndex:3] intValue]));
		} else {
			NSLog(@"components count != 4!!");
		}
	}
	return ipAddress;
}


//XFIPAddress XFIPAddressFromNSString(NSString *address) {
//	XFIPAddress ipAddress = 0;
//	ipAddress = (XFIPAddress)inet_addr([address UTF8String]);
//	ipAddress = NSSwapBigIntToHost(ipAddress);
//	return ipAddress;
//}


NSNumber *XFIntegerKey(XFUInteger8 integerKey) {
	return [NSNumber numberWithUnsignedChar:(unsigned char)integerKey];
}


NSString *NSStringFromUserID(XFUserID userID) {
	return [NSString stringWithFormat:@"%u", userID];
}


NSNumber *NSNumberFromXFIPAddress(XFIPAddress address) {
	return [NSNumber numberWithUnsignedInt:address];
}

NSNumber *NSNumberFromXFPort(XFPort port) {
	return [NSNumber numberWithUnsignedShort:port];
}


NSString *XFSaltString() {
	NSString *salt = nil;
	NSString *randomString = [NSString stringWithFormat:@"%d", rand()];
	salt = [randomString sha1HexHash];
	return salt;
}


NSData	*XFMonikerFromSessionIDAndSalt(NSData *sessionID, NSString *salt) {
	NSData *moniker = nil;
	NSString *stringRep = [[sessionID stringRepresentation] stringByAppendingString:salt];
	moniker = [stringRep sha1Hash];
	return moniker;
}


NSString *XFStripQuakeColors(NSString *string) {
	if ([string containsString:@"^"]) {
		NSMutableString *newString = [NSMutableString stringWithString:string];
		[newString replaceOccurrencesOfString:@"^^0" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString:@"^^1" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString:@"^^2" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString:@"^^3" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString:@"^^4" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString:@"^^5" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString:@"^^6" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString:@"^^7" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString:@"^^8" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString:@"^^9" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString:@"^0" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString:@"^1" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString:@"^2" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString:@"^3" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString:@"^4" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString:@"^5" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString:@"^6" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString:@"^7" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString:@"^8" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
		[newString replaceOccurrencesOfString:@"^9" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
		return [[newString copy] autorelease];
	}
	return string;
}

@implementation NSString (XFAdditions)


- (NSData *)md5Hash {
	return [[self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO] md5Hash];
}


- (NSString *)md5HexHash {
	return [[self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO] md5HexHash];
}


- (NSData *)sha1Hash {
	return [[self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO] sha1Hash];
}



- (NSString *)sha1HexHash {
	return [[self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO] sha1HexHash];
}


+ (id)stringWithFSRef:(const FSRef *)anFSRef {
	UInt8 thePath[PATH_MAX + 1];
	
	OSStatus status = FSRefMakePath(anFSRef, thePath, PATH_MAX);
	
	if (status == noErr) {
		return [NSString stringWithUTF8String:(const char *)thePath];
	} else {
		return nil;
	}
}


- (BOOL)getFSRef:(FSRef *)anFSRef {
	return (FSPathMakeRef((const UInt8 *)[self UTF8String], anFSRef, NULL) == noErr);
}

- (BOOL)boolValue {
	BOOL value = NO;
	if (self) {
		if ([self isEqualToString:@"YES"] || [self isEqualToString:@"yes"]) {
			value = YES;
		} else if ([self isEqualToString:@"NO"] || [self isEqualToString:@"no"]) {
			value = NO;
		}
	} else {
		value = NO;
	}
	return value;
}


/* I need to make sure that this method doesn't exceed the max 255 character filename limit	(NAME_MAX) */

- (NSString *)stringByAssuringUniqueFilename {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL isDir;
	
	if ([fileManager fileExistsAtPath:self isDirectory:&isDir]) {
		NSString *basePath = [self stringByDeletingLastPathComponent];
		NSString *filename = [self lastPathComponent];
		NSString *filenameExtension = [filename pathExtension];
		NSString *basename = [filename stringByDeletingPathExtension];
		
		NSArray *components = [basename componentsSeparatedByString:@"-"];
		
		if ([components count] > 1) {
			// baseName contains at least one "-", determine if it's already a "duplicate". If it is, repeat the process of adding 1 to the value until the resulting filename would be unique. If it isn't, fall through to where we just tack on our own at the end of the filename
			NSString *basenameSuffix = [components lastObject];
			NSInteger suffixNumber = [basenameSuffix intValue];
			if (suffixNumber > 0) {
				NSUInteger basenameSuffixLength = [basenameSuffix length];
			
				NSString *basenameSubstring = [basename substringWithRange:NSMakeRange(0, [basename length] - (basenameSuffixLength + 1))];
				while (1) {
					suffixNumber += 1;
					
					NSString *targetPath;
					
					if ([filenameExtension isEqualToString:@""]) {
						targetPath = [basePath stringByAppendingPathComponent:[basenameSubstring stringByAppendingString:[NSString stringWithFormat:@"-%ld", (long)suffixNumber]]];
					} else {
						targetPath = [basePath stringByAppendingPathComponent:[[basenameSubstring stringByAppendingString:[NSString stringWithFormat:@"-%ld", (long)suffixNumber]] stringByAppendingPathExtension:filenameExtension]];
					}
					
					if (![fileManager fileExistsAtPath:targetPath isDirectory:&isDir]) {
						return targetPath;
					}
				}
			}
		}
		
		// filename doesn't contain an (applicable) "-", so we just tack our own onto the end
		
		NSInteger suffixNumber = 0;
		
		while (1) {
			suffixNumber += 1;
			NSString *targetPath;
			if ([filenameExtension isEqualToString:@""]) {
				targetPath = [basePath stringByAppendingPathComponent:[basename stringByAppendingString:[NSString stringWithFormat:@"-%ld", (long)suffixNumber]]];
			} else {
				targetPath = [basePath stringByAppendingPathComponent:[[basename stringByAppendingString:[NSString stringWithFormat:@"-%ld", (long)suffixNumber]] stringByAppendingPathExtension:filenameExtension]];				
			}
			if (![fileManager fileExistsAtPath:targetPath isDirectory:&isDir]) {
				return targetPath;
			}
		}
	}
	return self;
}


- (NSComparisonResult)caseInsensitiveNumericalCompare:(NSString *)string {
	return [self compare:string options:NSLiteralSearch | NSCaseInsensitiveSearch | NSNumericSearch];
}

- (NSComparisonResult)localizedCaseInsensitiveNumericalCompare:(NSString *)string {
	return [self compare:string options:NSLiteralSearch | NSCaseInsensitiveSearch | NSNumericSearch range:NSMakeRange(0, [string length]) locale:[NSLocale currentLocale]];
}


- (BOOL)containsString:(NSString *)aString {
	return (!NSEqualRanges([self rangeOfString:aString], NSMakeRange(NSNotFound, 0)));
}

//- (NSString *)stringByReplacingOccurrencesOfString:(NSString *)value withString:(NSString *)newValue {
//    NSMutableString *newString = [NSMutableString stringWithString:self];
//    [newString replaceOccurrencesOfString:value withString:newValue options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
//    return newString;
//}


- (NSString *)slashToColon {
	return [self stringByReplacingOccurrencesOfString:@"/" withString:@":"];
}


- (NSString *)colonToSlash {
	return [self stringByReplacingOccurrencesOfString:@":" withString:@"/"];
}

@end




@implementation NSData (XFAdditions)


+ (NSData *)zeroedChatID {
	NSMutableData *zeroData = [NSMutableData data];
	[zeroData setLength:XF_DID_LENGTH];
	return [[zeroData copy] autorelease];
}


- (NSString *)md5HexHash {
	unsigned char digest[MD5_DIGEST_LENGTH];
	char hashString[(2 * MD5_DIGEST_LENGTH) + 1];
	
	MD5([self bytes], [self length], digest);
	
	NSInteger i = 0;
	
	for (i = 0; i < MD5_DIGEST_LENGTH; i++) {
		sprintf(hashString + i * 2, "%02x", digest[i]);
	}
	hashString[i * 2] = 0;
	return [NSString stringWithUTF8String:(const char *)hashString];
//	return [NSString stringWithCString:hashString length:2 * MD5_DIGEST_LENGTH ];
}



- (NSData *)md5Hash {
	unsigned char digest[MD5_DIGEST_LENGTH];
	
	MD5([self bytes], [self length], digest);
	
	return [NSData dataWithBytes:&digest length:MD5_DIGEST_LENGTH];
}



- (NSString *)sha1HexHash {
	unsigned char digest[SHA_DIGEST_LENGTH];
	char hashString[(2 * SHA_DIGEST_LENGTH) + 1];
	
	SHA1([self bytes], [self length], digest);
	
	NSInteger currentIndex = 0;
	
	for (currentIndex = 0; currentIndex < SHA_DIGEST_LENGTH; currentIndex++) {
		
		sprintf(hashString+currentIndex*2, "%02x", digest[currentIndex]);
	}
	hashString[currentIndex * 2] = 0;
	
	return [NSString stringWithUTF8String:(const char *)hashString];
//	return [NSString stringWithCString:hashString length:2*SHA_DIGEST_LENGTH ];
}


- (NSData *)sha1Hash {
	unsigned char digest[SHA_DIGEST_LENGTH];
	
	SHA1([self bytes], [self length], digest);
	
	return [NSData dataWithBytes:&digest length:SHA_DIGEST_LENGTH];
}

// --------------------------------CRC32-------------------------------
static const XFUInteger32 crc32table[] = {
	0x00000000, 0x77073096, 0xee0e612c, 0x990951ba, 0x076dc419, 0x706af48f, 0xe963a535, 0x9e6495a3,
	0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988, 0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91,
	0x1db71064, 0x6ab020f2, 0xf3b97148, 0x84be41de, 0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
	0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec, 0x14015c4f, 0x63066cd9, 0xfa0f3d63, 0x8d080df5,
	0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172, 0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,
	0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940, 0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
	0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116, 0x21b4f4b5, 0x56b3c423, 0xcfba9599, 0xb8bda50f,
	0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924, 0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d,
	0x76dc4190, 0x01db7106, 0x98d220bc, 0xefd5102a, 0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
	0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818, 0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01,
	0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e, 0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457,
	0x65b0d9c6, 0x12b7e950, 0x8bbeb8ea, 0xfcb9887c, 0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
	0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2, 0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb,
	0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0, 0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9,
	0x5005713c, 0x270241aa, 0xbe0b1010, 0xc90c2086, 0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
	0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4, 0x59b33d17, 0x2eb40d81, 0xb7bd5c3b, 0xc0ba6cad,
	0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a, 0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683,
	0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8, 0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
	0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe, 0xf762575d, 0x806567cb, 0x196c3671, 0x6e6b06e7,
	0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc, 0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5,
	0xd6d6a3e8, 0xa1d1937e, 0x38d8c2c4, 0x4fdff252, 0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
	0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60, 0xdf60efc3, 0xa867df55, 0x316e8eef, 0x4669be79,
	0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236, 0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f,
	0xc5ba3bbe, 0xb2bd0b28, 0x2bb45a92, 0x5cb36a04, 0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
	0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a, 0x9c0906a9, 0xeb0e363f, 0x72076785, 0x05005713,
	0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38, 0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21,
	0x86d3d2d4, 0xf1d4e242, 0x68ddb3f8, 0x1fda836e, 0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
	0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c, 0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45,
	0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2, 0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db,
	0xaed16a4a, 0xd9d65adc, 0x40df0b66, 0x37d83bf0, 0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
	0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6, 0xbad03605, 0xcdd70693, 0x54de5729, 0x23d967bf,
	0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94, 0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d
};

//static const XFUInteger32 crc32table[256] = {
//	0x00000000, 0x77073096, 0xEE0E612C, 0x990951BA,
//	0x076DC419, 0x706AF48F, 0xE963A535, 0x9E6495A3,
//	0x0EDB8832, 0x79DCB8A4, 0xE0D5E91E, 0x97D2D988,
//	0x09B64C2B, 0x7EB17CBD, 0xE7B82D07, 0x90BF1D91,
//	0x1DB71064, 0x6AB020F2, 0xF3B97148, 0x84BE41DE,
//	0x1ADAD47D, 0x6DDDE4EB, 0xF4D4B551, 0x83D385C7,
//	0x136C9856, 0x646BA8C0, 0xFD62F97A, 0x8A65C9EC,
//	0x14015C4F, 0x63066CD9, 0xFA0F3D63, 0x8D080DF5,
//	0x3B6E20C8, 0x4C69105E, 0xD56041E4, 0xA2677172,
//	0x3C03E4D1, 0x4B04D447, 0xD20D85FD, 0xA50AB56B,
//	0x35B5A8FA, 0x42B2986C, 0xDBBBC9D6, 0xACBCF940,
//	0x32D86CE3, 0x45DF5C75, 0xDCD60DCF, 0xABD13D59,
//	0x26D930AC, 0x51DE003A, 0xC8D75180, 0xBFD06116,
//	0x21B4F4B5, 0x56B3C423, 0xCFBA9599, 0xB8BDA50F,
//	0x2802B89E, 0x5F058808, 0xC60CD9B2, 0xB10BE924,
//	0x2F6F7C87, 0x58684C11, 0xC1611DAB, 0xB6662D3D,
//	
//	0x76DC4190, 0x01DB7106, 0x98D220BC, 0xEFD5102A,
//	0x71B18589, 0x06B6B51F, 0x9FBFE4A5, 0xE8B8D433,
//	0x7807C9A2, 0x0F00F934, 0x9609A88E, 0xE10E9818,
//	0x7F6A0DBB, 0x086D3D2D, 0x91646C97, 0xE6635C01,
//	0x6B6B51F4, 0x1C6C6162, 0x856530D8, 0xF262004E,
//	0x6C0695ED, 0x1B01A57B, 0x8208F4C1, 0xF50FC457,
//	0x65B0D9C6, 0x12B7E950, 0x8BBEB8EA, 0xFCB9887C,
//	0x62DD1DDF, 0x15DA2D49, 0x8CD37CF3, 0xFBD44C65,
//	0x4DB26158, 0x3AB551CE, 0xA3BC0074, 0xD4BB30E2,
//	0x4ADFA541, 0x3DD895D7, 0xA4D1C46D, 0xD3D6F4FB,
//	0x4369E96A, 0x346ED9FC, 0xAD678846, 0xDA60B8D0,
//	0x44042D73, 0x33031DE5, 0xAA0A4C5F, 0xDD0D7CC9,
//	0x5005713C, 0x270241AA, 0xBE0B1010, 0xC90C2086,
//	0x5768B525, 0x206F85B3, 0xB966D409, 0xCE61E49F,
//	0x5EDEF90E, 0x29D9C998, 0xB0D09822, 0xC7D7A8B4,
//	0x59B33D17, 0x2EB40D81, 0xB7BD5C3B, 0xC0BA6CAD,
//	
//	0xEDB88320, 0x9ABFB3B6, 0x03B6E20C, 0x74B1D29A,
//	0xEAD54739, 0x9DD277AF, 0x04DB2615, 0x73DC1683,
//	0xE3630B12, 0x94643B84, 0x0D6D6A3E, 0x7A6A5AA8,
//	0xE40ECF0B, 0x9309FF9D, 0x0A00AE27, 0x7D079EB1,
//	0xF00F9344, 0x8708A3D2, 0x1E01F268, 0x6906C2FE,
//	0xF762575D, 0x806567CB, 0x196C3671, 0x6E6B06E7,
//	0xFED41B76, 0x89D32BE0, 0x10DA7A5A, 0x67DD4ACC,
//	0xF9B9DF6F, 0x8EBEEFF9, 0x17B7BE43, 0x60B08ED5,
//	0xD6D6A3E8, 0xA1D1937E, 0x38D8C2C4, 0x4FDFF252,
//	0xD1BB67F1, 0xA6BC5767, 0x3FB506DD, 0x48B2364B,
//	0xD80D2BDA, 0xAF0A1B4C, 0x36034AF6, 0x41047A60,
//	0xDF60EFC3, 0xA867DF55, 0x316E8EEF, 0x4669BE79,
//	0xCB61B38C, 0xBC66831A, 0x256FD2A0, 0x5268E236,
//	0xCC0C7795, 0xBB0B4703, 0x220216B9, 0x5505262F,
//	0xC5BA3BBE, 0xB2BD0B28, 0x2BB45A92, 0x5CB36A04,
//	0xC2D7FFA7, 0xB5D0CF31, 0x2CD99E8B, 0x5BDEAE1D,
//	
//	0x9B64C2B0, 0xEC63F226, 0x756AA39C, 0x026D930A,
//	0x9C0906A9, 0xEB0E363F, 0x72076785, 0x05005713,
//	0x95BF4A82, 0xE2B87A14, 0x7BB12BAE, 0x0CB61B38,
//	0x92D28E9B, 0xE5D5BE0D, 0x7CDCEFB7, 0x0BDBDF21,
//	0x86D3D2D4, 0xF1D4E242, 0x68DDB3F8, 0x1FDA836E,
//	0x81BE16CD, 0xF6B9265B, 0x6FB077E1, 0x18B74777,
//	0x88085AE6, 0xFF0F6A70, 0x66063BCA, 0x11010B5C,
//	0x8F659EFF, 0xF862AE69, 0x616BFFD3, 0x166CCF45,
//	0xA00AE278, 0xD70DD2EE, 0x4E048354, 0x3903B3C2,
//	0xA7672661, 0xD06016F7, 0x4969474D, 0x3E6E77DB,
//	0xAED16A4A, 0xD9D65ADC, 0x40DF0B66, 0x37D83BF0,
//	0xA9BCAE53, 0xDEBB9EC5, 0x47B2CF7F, 0x30B5FFE9,
//	0xBDBDF21C, 0xCABAC28A, 0x53B39330, 0x24B4A3A6,
//	0xBAD03605, 0xCDD70693, 0x54DE5729, 0x23D967BF,
//	0xB3667A2E, 0xC4614AB8, 0x5D681B02, 0x2A6F2B94,
//	0xB40BBE37, 0xC30C8EA1, 0x5A05DF1B, 0x2D02EF8D,
//};


//- (XFUInteger32)crc32 {
//	XFUInteger32	crcval;
//	NSUInteger		x, y;
//	const void		*bytes;
//	NSUInteger		max;
//	
//	bytes = [self bytes];
//	max = [self length];
//	
//	crcval = 0xffffffff;
//	
//	for (x = 0, y = max; x < y; x++) {
//		crcval = ((crcval >> 8) & 0x00ffffff) ^ crc32table[(crcval ^ (*((unsigned char *)bytes + x))) & 0xff];
//	}
//	
//	return crcval ^ 0xffffffff;
//}


- (XFUInteger32)crc32 {
	XFUInteger32 crc32 = 0;
	
	if ([self length]) {
		NSUInteger p_len = [self length];
		const void *p_data = [self bytes];
		
		crc32 = 0xffffffff;
		
		XFUInteger32 i;
		
		for (i = 0; i < p_len; i++) {
			crc32 = (crc32 >> 8) ^ crc32table[((unsigned char *)p_data)[i] ^ (crc32 & 0x000000ff)];
		}
		
		return ~crc32;
	}
	return crc32;
}



- (NSString *)stringRepresentation {
	const char *bytes = [self bytes];
	NSUInteger length = [self length];
	NSUInteger index;
	
	NSMutableString *stringRepresentation = [NSMutableString string];
	
	for (index = 0; index < length; index++) {
		[stringRepresentation appendFormat:@"%02x", (unsigned char)bytes[index]];
	}
	return [[stringRepresentation copy] autorelease];
}

// prints raw hex + ascii
- (NSString *)enhancedDescription {

	NSMutableString *string = [NSMutableString string];   // full string result
	NSMutableString *hrStr = [NSMutableString string]; // "human readable" string

	NSInteger i, len;
	const unsigned char *b;
	len = [self length];
	b = [self bytes];

	if (len == 0) {
		return @"<empty>";
	}
	[string appendString:@"\n   "];

	NSInteger linelen = 16;
	for (i = 0; i < len; i++) {
		[string appendFormat:@" %02x", b[i]];
		if (isprint(b[i])) {
			[hrStr appendFormat:@"%c", b[i]];
		} else {
			[hrStr appendString:@"."];
		}
		if ((i % linelen) == (linelen - 1)) { // new line every linelen bytes
			[string appendFormat:@"    %@\n", hrStr];
			hrStr = [NSMutableString string];

			if (i < (len - 1)) {
				[string appendString:@"   "];
			}
		}
	}

	// make sure to print out the remaining hrStr part, aligned of course
	if ((len % linelen) != 0) {
		int bytesRemain = linelen - (len % linelen); // un-printed bytes
		for (i = 0; i < bytesRemain; i++) {
			[string appendString:@"   "];
		}
		[string appendFormat:@"    %@\n", hrStr];
	}
	return string;
}



- (BOOL)isAllZeroes {
	NSMutableData *zeroData = [NSMutableData data];
	[zeroData setLength:[self length]];
	return [self isEqualToData:zeroData];
}

- (NSData *)dataByTruncatingZeroedData {
	NSMutableData *data = [NSMutableData data];
	NSUInteger length = [self length];
	NSUInteger i = 0;
	for (i = 0; i < length; i++) {
		XFUInteger8 byte = 0;
		[self getBytes:&byte range:NSMakeRange(i, sizeof(XFUInteger8))];
		if (byte) {
			[data appendBytes:&byte length:sizeof(XFUInteger8)];
		} else {
			break;
		}
	}
	return [NSData dataWithData:data];
}

@end



@implementation NSArray (XFAdditions)

- (NSString *)applescriptListForStringArray {
	
	NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];
	
	NSString *listString = @"{";
	
	NSString *filePath;
	
	NSInteger currentIndex;
	NSInteger totalCount = [self count];
	
	for (currentIndex = 0; currentIndex < totalCount; currentIndex++) {
		filePath = [self objectAtIndex:currentIndex];
		listString = [listString stringByAppendingString:[NSString stringWithFormat:@"\"%@\" as POSIX file", filePath]];
		
		if (currentIndex < (totalCount - 1)) {
			listString = [listString stringByAppendingString:@", "];
		} else {

		}
	}
	
	listString = [[listString stringByAppendingString:@"}"] retain];
	
	[localPool release];
	
	return [listString autorelease];
	
}

@end

@implementation NSMutableArray (XFAdditions)

- (NSString *)applescriptListForStringArray {
	
	NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];
	
	NSString *listString = @"{";
	
	NSString *filePath;
	
	NSInteger currentIndex;
	NSInteger totalCount = [self count];
	
	for (currentIndex = 0; currentIndex < totalCount; currentIndex++) {
		filePath = [self objectAtIndex:currentIndex];
		listString = [listString stringByAppendingString:[NSString stringWithFormat:@"\"%@\" as POSIX file", filePath]];
		
		if (currentIndex < (totalCount - 1)) {
			listString = [listString stringByAppendingString:@", "];
		} else {

		}
	}
	
	listString = [[listString stringByAppendingString:@"}"] retain];
	
	[localPool release];
	
	return [listString autorelease];
	
}

- (void)insertObjectsFromArray:(NSArray *)array atIndex:(NSUInteger)index {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	[self insertObjects:array atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, [array count])]];
}


@end

@implementation NSNotificationCenter (XFAdditions)

+ (void)xf__postNotification:(NSNotification *)notification {
	[[self defaultCenter] postNotification:notification];
}


+ (void)xf__postNotificationWithDictionary:(NSDictionary *)notificationDictionary {
	NSString *name = [notificationDictionary objectForKey:@"name"];
	id object = [notificationDictionary objectForKey:@"object"];
	NSDictionary *userInfo = [notificationDictionary objectForKey:@"userInfo"];
	[[self defaultCenter] postNotificationName:name object:object userInfo:userInfo];
}


- (void)postNotificationOnMainThread:(NSNotification *)notification {
	if ([NSThread isMainThread]) {
		return [self postNotification:notification];
	}
	[self postNotificationOnMainThread:notification waitUntilDone:NO];
}

- (void)postNotificationOnMainThread:(NSNotification *)notification waitUntilDone:(BOOL)wait {
	if ([NSThread isMainThread]) {
		return [self postNotification:notification];
	}
	[[self class] performSelectorOnMainThread:@selector(xf__postNotificationWithDictionary:) withObject:notification waitUntilDone:wait];
}

- (void)postNotificationOnMainThreadWithName:(NSString *)name object:(id)object {
	if ([NSThread isMainThread]) {
		return [self postNotificationName:name object:object userInfo:nil];
	}
	[self postNotificationOnMainThreadWithName:name object:object userInfo:nil waitUntilDone:NO];
}

- (void)postNotificationOnMainThreadWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo {
	if ([NSThread isMainThread]) {
		return [self postNotificationName:name object:object userInfo:userInfo];
	}
	[self postNotificationOnMainThreadWithName:name object:object userInfo:userInfo waitUntilDone:NO];
}


- (void)postNotificationOnMainThreadWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo waitUntilDone:(BOOL)wait {
	if ([NSThread isMainThread]) {
		return [self postNotificationName:name object:object userInfo:userInfo];
	}
	NSMutableDictionary *info = [[NSMutableDictionary allocWithZone:nil] initWithCapacity:3];
	if (name) {
		[info setObject:name forKey:@"name"];
	}
	if (object) {
		[info setObject:object forKey:@"object"];
	}
	if (userInfo) {
		[info setObject:userInfo forKey:@"userInfo"];
	}
	[[self class] performSelectorOnMainThread:@selector(xf__postNotificationWithDictionary:) withObject:info waitUntilDone:wait];

	[info release];
}


@end


@implementation NSObject (MutableDeepCopy)

- (id)mutableDeepCopy {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
    if ([self respondsToSelector:@selector(mutableCopyWithZone:)]) {
        return [self mutableCopy];
	} else if ([self respondsToSelector:@selector(copyWithZone:)]) {
        return [self copy];
	} else {
        return [self retain];
	}
}

@end



@implementation NSDictionary (MutableDeepCopy)

- (id)mutableDeepCopy {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    NSMutableDictionary *newDictionary = [[NSMutableDictionary alloc] init];
	id key = nil;
	
	NSArray *allKeys = [self allKeys];
	
	for (key in allKeys) {
		id copiedObject = [[self objectForKey:key] mutableDeepCopy];
		
		id keyCopy = nil;
		
		if ([key conformsToProtocol:@protocol(NSCopying)]) {
			keyCopy = [key copy];
		} else {
			keyCopy = [key retain];
		}
		
		[newDictionary setObject:copiedObject forKey:keyCopy];
		[copiedObject release];
		[keyCopy release];
	}	
    return newDictionary;
}

@end



@implementation NSArray (MutableDeepCopy)

- (id)mutableDeepCopy {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    NSMutableArray *newArray = [[NSMutableArray alloc] init];
    NSEnumerator *enumerator = [self objectEnumerator];
	
    id object;
	
    while (object = [enumerator nextObject]) {
        id copiedObject = [object mutableDeepCopy];
        [newArray addObject:copiedObject];
        [copiedObject release];
    }
    return newArray;
}

@end



@implementation NSSet (MutableDeepCopy)

- (id)mutableDeepCopy {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    NSMutableSet *newSet = [[NSMutableSet alloc] init];
    NSEnumerator *enumerator = [self objectEnumerator];
	
    id object;
    while (object = [enumerator nextObject]) {
		id copiedObject = [object mutableDeepCopy];
		[newSet addObject:copiedObject];
		[copiedObject release];
    }
    return newSet;
}

@end


