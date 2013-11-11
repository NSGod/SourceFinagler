//
//  MDAppKitAdditions.h
//  
//
//  Created by Mark Douma on 6/4/2010.
//  Copyright (c) 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MDFoundationAdditions.h"

#ifdef __cplusplus
extern "C" {
#endif
	
extern NSString *NSStringFromDefaultsKeyPath(NSString *defaultsKey);

#ifdef __cplusplus
}
#endif

	
@interface NSAlert (MDAdditions)
+ (NSAlert *)alertWithMessageText:(NSString *)messageText informativeText:(NSString *)informativeText firstButton:(NSString *)firstButtonTitle secondButton:(NSString *)secondButtonTitle thirdButton:(NSString *)thirdButtonTitle;
@end

@interface NSBundle (MDAppKitAdditions)
+ (void)runFailedNibLoadAlert:(NSString *)nibName;
@end

@interface NSColor (MDAdditions)
- (NSString *)hexValue;
@end

@interface NSFont (MDAdditions)
- (NSString *)cssRepresentation;
@end

@interface NSMenu (MDAdditions)
- (BOOL)containsItem:(NSMenuItem *)aMenuItem;
- (void)setItemArray:(NSArray *)anArray;
- (void)removeAllItems;
@end

@interface NSOpenPanel (MDAdditions)
+ (NSOpenPanel *)openPanelWithTitle:(NSString *)title
							message:(NSString *)message
				  actionButtonTitle:(NSString *)actionButtonTitle
			allowsMultipleSelection:(BOOL)allowsMultipleSelection
			   canChooseDirectories:(BOOL)canChooseDirectories
						   delegate:(id <NSOpenSavePanelDelegate>)delegate;


@end

@interface NSPopUpButton (MDAdditions)
- (void)setItemArray:(NSArray *)value;
@end

@interface NSToolbarItem (MDAdditions)
+ (id)toolbarItemWithItemIdentifier:(NSString *)anIdentifier tag:(NSInteger)aTag image:(NSImage *)anImage label:(NSString *)aLabel paletteLabel:(NSString *)aPaletteLabel target:(id)anObject action:(SEL)anAction;
@end

@interface NSUserDefaults (MDAdditions)
- (void)setFont:(NSFont *)aFont forKey:(NSString *)aKey;
- (NSFont *)fontForKey:(NSString *)aKey;
- (void)setColor:(NSColor *)aColor forKey:(NSString *)aKey;
- (NSColor *)colorForKey:(NSString *)aKey;
@end

@interface NSView (MDAdditions) 
- (void)setFrameFromString:(NSString *)aString;
- (NSString *)stringWithSavedFrame;
@end

@interface NSWindow (MDAdditions)
- (CGFloat)toolbarHeight;
- (void)resizeToSize:(NSSize)newSize;
- (void)switchView:(NSView *)aView newTitle:(NSString *)aString;
- (void)switchView:(NSView *)aView;
@end

@interface NSWorkspace (MDAdditions)

- (BOOL)revealInFinder:(NSArray *)filePaths;

- (NSImage *)iconForApplicationForURL:(NSURL *)aURL;
- (NSString *)absolutePathForAppBundleWithIdentifier:(NSString *)aBundleIdentifier name:(NSString *)aNameWithDotApp creator:(NSString *)creator;
- (BOOL)launchApplicationAtPath:(NSString *)path arguments:(NSArray *)argv error:(NSError **)outError;

@end


