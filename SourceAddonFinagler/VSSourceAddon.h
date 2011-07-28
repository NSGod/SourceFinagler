//
//  VSSourceAddon.h
//  Source Finagler
//
//  Created by Mark Douma on 11/15/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VSGame;

@interface VSSourceAddon : NSObject {
	NSString		*path;
	NSString		*fileName;
	NSImage			*fileIcon;
	NSString		*gameName;
	NSImage			*gameIcon;
	NSString		*problem;
}
+ (id)sourceAddonWithPath:(NSString *)aPath game:(VSGame *)aGame error:(NSError *)inError;
- (id)initWithPath:(NSString *)aPath game:(VSGame *)game error:(NSError *)inError;

@property (retain) NSString *path;
@property (retain) NSString *fileName;
@property (retain) NSImage *fileIcon;
@property (retain) NSString *gameName;
@property (retain) NSImage *gameIcon;
@property (retain) NSString *problem;

@end
