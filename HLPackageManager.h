//
//  HLPackageManager.h
//  Source Finagler
//
//  Created by Mark Douma on 10/27/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface HLPackageManager : NSObject {
	id				delegate;
}

- (void)setDelegate:(id)delegate;
- (id)delegate;

/* contentsOfDirectoryAtPath:error: returns an NSArray of NSStrings representing the filenames of the items in the directory. If this method returns 'nil', an NSError will be returned by reference in the 'error' parameter. If the directory contains no items, this method will return the empty array.
 
    This method replaces directoryContentsAtPath:
 */
- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)outError;


/* subpathsOfDirectoryAtPath:error: returns an NSArray of NSStrings represeting the filenames of the items in the specified directory and all its subdirectories recursively. If this method returns 'nil', an NSError will be returned by reference in the 'error' parameter. If the directory contains no items, this method will return the empty array.
 
    This method replaces subpathsAtPath:
 */
- (NSArray *)subpathsOfDirectoryAtPath:(NSString *)path error:(NSError **)outError;


/* attributesOfItemAtPath:error: returns an NSDictionary of key/value pairs containing the attributes of the item (file, directory, symlink, etc.) at the path in question. If this method returns 'nil', an NSError will be returned by reference in the 'error' parameter. This method does not traverse a terminal symlink.
 
    This method replaces fileAttributesAtPath:traverseLink:.
 */
- (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)outError;


/* These methods replace their non-error returning counterparts below. See the NSFileManagerFileOperationAdditions category below for methods that are dispatched to the NSFileManager instance's delegate.
 */
- (BOOL)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)outError;
- (BOOL)moveItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)outError;
- (BOOL)linkItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)outError;
- (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)outError;


/* The following methods are of limited utility. Attempting to predicate behavior based on the current state of the filesystem or a particular file on the filesystem is encouraging odd behavior in the face of filesystem race conditions. It's far better to attempt an operation (like loading a file or creating a directory) and handle the error gracefully than it is to try to figure out ahead of time whether the operation will succeed.
 */
- (BOOL)fileExistsAtPath:(NSString *)path;
- (BOOL)fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isDirectory;
- (BOOL)isReadableFileAtPath:(NSString *)path;
- (BOOL)isWritableFileAtPath:(NSString *)path;
- (BOOL)isExecutableFileAtPath:(NSString *)path;
- (BOOL)isDeletableFileAtPath:(NSString *)path;


@end


//@interface NSDictionary (NSFileAttributes)
//
//- (unsigned long long)fileSize;
//- (NSDate *)fileModificationDate;
//- (NSString *)fileType;
//- (NSUInteger)filePosixPermissions;
//- (NSString *)fileOwnerAccountName;
//- (NSString *)fileGroupOwnerAccountName;
//- (NSInteger)fileSystemNumber;
//- (NSUInteger)fileSystemFileNumber;
//- (BOOL)fileExtensionHidden;
//- (OSType)fileHFSCreatorCode;
//- (OSType)fileHFSTypeCode;
//#if MAC_OS_X_VERSION_10_2 <= MAC_OS_X_VERSION_MAX_ALLOWED
//- (BOOL)fileIsImmutable;
//- (BOOL)fileIsAppendOnly;
//- (NSDate *)fileCreationDate;
//- (NSNumber *)fileOwnerAccountID;
//- (NSNumber *)fileGroupOwnerAccountID;
//#endif
//
//@end






