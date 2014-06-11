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

@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain) NSString *fileName;
@property (nonatomic, retain) NSImage *fileIcon;
@property (nonatomic, retain) NSString *gameName;
@property (nonatomic, retain) NSImage *gameIcon;
@property (nonatomic, retain) NSString *problem;

@end

