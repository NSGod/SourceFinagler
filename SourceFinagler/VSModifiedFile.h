//
//  VSModifiedFile.h
//  Source Finagler
//
//  Created by Mark Douma on 12/21/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VSModifiedFile : NSObject {
	NSString		*path;
	NSString		*name;
	NSImage			*image;
	NSString		*status;
}

- (id)initWithPath:(NSString *)aPath status:(NSString *)aStatus;

@property (retain) NSString *path;
@property (retain) NSString *name;
@property (retain) NSImage *image;
@property (retain) NSString *status;

@end
