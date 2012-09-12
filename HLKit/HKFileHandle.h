//
//  HKFileHandle.h
//  HLKit
//
//  Created by Mark Douma on 1/19/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>



@interface HKFileHandle : NSObject {
	NSString				*path;
	FSRef					fileRef;
	FSIORefNum				forkRef;
	unsigned long long		offsetInFile;
	
}


+ (id)fileHandleForWritingAtPath:(NSString *)aPath;
- (id)initForWritingAtPath:(NSString *)aPath;

- (void)writeData:(NSData *)aData;

- (void)synchronizeFile;
- (void)closeFile;

- (unsigned long long)offsetInFile;
- (unsigned long long)seekToEndOfFile;
- (void)seekToFileOffset:(unsigned long long)anOffset;

- (void)truncateFileAtOffset:(unsigned long long)anOffset;

@property (readonly, retain) NSString *path;

@end



