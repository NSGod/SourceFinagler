//
//  TKAppKitAdditions.h
//  
//
//  Created by Mark Douma on 6/4/2010.
//  Copyright (c) 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TKFoundationAdditions.h"


@interface NSAlert (TKAdditions)
+ (NSAlert *)alertWithMessageText:(NSString *)messageText informativeText:(NSString *)informativeText firstButton:(NSString *)firstButtonTitle secondButton:(NSString *)secondButtonTitle thirdButton:(NSString *)thirdButtonTitle;
@end

@interface NSBundle (TKAppKitAdditions)
+ (void)runFailedNibLoadAlert:(NSString *)nibName;
@end

@interface NSMenu (TKAdditions)
- (BOOL)containsItem:(NSMenuItem *)aMenuItem;
- (void)setItemArray:(NSArray *)anArray;
//- (void)removeAllItems;
@end


@interface NSOpenPanel (TKAdditions)
+ (NSOpenPanel *)openPanelWithTitle:(NSString *)title
							message:(NSString *)message
				  actionButtonTitle:(NSString *)actionButtonTitle
			allowsMultipleSelection:(BOOL)allowsMultipleSelection
			   canChooseDirectories:(BOOL)canChooseDirectories
						   delegate:(id <NSOpenSavePanelDelegate>)delegate;


@end


@interface NSPopUpButton (TKAdditions)
- (void)setItemArray:(NSArray *)value;
@end


@interface NSWindow (TKAdditions)
- (CGFloat)toolbarHeight;
- (void)resizeToSize:(NSSize)newSize;
- (void)switchView:(NSView *)aView newTitle:(NSString *)aString;
- (void)switchView:(NSView *)aView;
@end


@interface NSWorkspace (TKAdditions)
- (BOOL)revealInFinder:(NSArray *)filePaths;
- (NSImage *)iconForApplicationForURL:(NSURL *)aURL;
@end


