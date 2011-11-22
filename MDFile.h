//
//  MDFile.h
//  Source Finagler
//
//  Created by Mark Douma on 9/1/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDItem.h"



@interface MDFile : MDItem {

@private
	void *_privateData;
	void *_fH;
	void *_iS;
}

- (BOOL)beginWritingToFile:(NSString *)aPath assureUniqueFilename:(BOOL)assureUniqueFilename resultingPath:(NSString **)resultingPath error:(NSError **)outError;
- (BOOL)continueWritingPartialBytesOfLength:(NSUInteger *)partialBytesLength error:(NSError **)outError;
- (BOOL)finishWritingWithError:(NSError **)outError;

- (BOOL)cancelWritingAndRemovePartialFileWithError:(NSError **)outError;



- (NSData *)data;

@end

