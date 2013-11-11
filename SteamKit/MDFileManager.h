//
//  MDFileManager.h
//  Font Finagler
//
//  Created by Mark Douma on 11/20/2006.
//  Copyright © 2006 Mark Douma. All rights reserved.
//  


#import <Foundation/Foundation.h>

enum {
	MDFileLabelNone				= 0,
	MDFileLabelGray				= 1,
	MDFileLabelGreen			= 2,
	MDFileLabelPurple			= 3,
	MDFileLabelBlue				= 4,
	MDFileLabelYellow			= 5,
	MDFileLabelRed				= 6,
	MDFileLabelOrange			= 7,
	MDFileLabelUnsupported		= NSNotFound
};


@interface MDFileManager : NSObject {
	NSFileManager	*fileManager;

}
+ (MDFileManager *)defaultManager;

// returns all HFS+ info as well as resource fork sizes
- (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)outError;
- (BOOL)setAttributes:(NSDictionary *)attributes ofItemAtPath:(NSString *)path error:(NSError **)error;

// returns resource fork sizes only
- (NSDictionary *)fileAttributesAtPath:(NSString *)path traverseLink:(BOOL)yorn;

- (BOOL)isDeletableFileAtPath:(NSString *)path;


@end



extern NSString * const MDFileLabelNumber;
extern NSString * const MDFileHasCustomIcon;
extern NSString * const MDFileIsStationery;
extern NSString * const MDFileNameLocked;
extern NSString * const MDFileIsPackage;
extern NSString * const MDFileIsInvisible;
extern NSString * const MDFileIsAliasFile;


@interface NSDictionary (MDFileAttributes)

- (NSUInteger)fileLabelColor;			/* files & folders	*/
- (BOOL)fileHasCustomIcon;				/* files & folders	*/
- (BOOL)fileIsStationery;				/* files only		*/
- (BOOL)fileNameLocked;					/* files & folders	(value isn't used or respected by OS X) */
- (BOOL)fileIsPackage;					/* folders only  (NOTE: maps to kHasBundle, which for files, means a 'BNDL' resource. As such, this is pretty much obsolete for files Mac in OS X) */
- (BOOL)fileIsInvisible;				/* files & folders */
- (BOOL)fileIsAlias;					/* files only		*/

@end


