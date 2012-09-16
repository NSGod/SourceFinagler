//
//  HKFile.h
//  HLKit
//
//  Created by Mark Douma on 9/1/2010.
//  Copyright (c) 2009-2012 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKItem.h>


@interface HKFile : HKItem {

@private
	void *_privateData;
	void *_fH;
	void *_iS;
}

// convenience
- (BOOL)writeToFile:(NSString *)aPath assureUniqueFilename:(BOOL)assureUniqueFilename resultingPath:(NSString **)resultingPath error:(NSError **)outError;


- (BOOL)beginWritingToFile:(NSString *)aPath assureUniqueFilename:(BOOL)assureUniqueFilename resultingPath:(NSString **)resultingPath error:(NSError **)outError;
- (BOOL)continueWritingPartialBytesOfLength:(NSUInteger *)partialBytesLength error:(NSError **)outError;
- (BOOL)finishWritingWithError:(NSError **)outError;

- (BOOL)cancelWritingAndRemovePartialFileWithError:(NSError **)outError;



- (NSData *)data;

@end

