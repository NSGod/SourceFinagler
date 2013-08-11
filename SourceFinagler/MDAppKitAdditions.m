//
//  MDAppKitAdditions.m
//  
//
//  Created by Mark Douma on 6/4/2010.
//  Copyright (c) 2010 Mark Douma LLC. All rights reserved.
//

#import "MDAppKitAdditions.h"

#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
#include <ApplicationServices/ApplicationServices.h>
#elif MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_5
#include <CoreServices/CoreServices.h>
#endif


#define MD_DEBUG 0


NSString *NSStringFromDefaultsKeyPath(NSString *defaultsKey) {
	return [NSString stringWithFormat:@"defaults.%@", defaultsKey];
}

@implementation NSAlert (MDAdditions)


+ (NSAlert *)alertWithMessageText:(NSString *)messageText informativeText:(NSString *)informativeText firstButton:(NSString *)firstButtonTitle secondButton:(NSString *)secondButtonTitle thirdButton:(NSString *)thirdButtonTitle {
	
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setMessageText:messageText];
	[alert setInformativeText:informativeText];
	if (firstButtonTitle) {
		[alert addButtonWithTitle:firstButtonTitle];
	}
	if (secondButtonTitle) {
		[alert addButtonWithTitle:secondButtonTitle];
	}
	if (thirdButtonTitle) {
		[alert addButtonWithTitle:thirdButtonTitle];
	}
	return alert;
}

@end

@implementation NSBundle (MDAppKitAdditions)

+ (void)runFailedNibLoadAlert:(NSString *)nibName {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSBeep();
	NSString *appName = nil;
	appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
	if (appName == nil) {
		appName = NSLocalizedString(@"This application", @"");
	}
	NSInteger choice = NSRunCriticalAlertPanel([NSString stringWithFormat:NSLocalizedString(@"%@ encountered an error while trying to load the \"%@\" user interface file.", @""), appName, nibName], NSLocalizedString(@"Please reinstall the application.", @""), NSLocalizedString(@"Quit", @""), nil, nil);
	if (choice == NSAlertDefaultReturn) [NSApp terminate:nil];	
}

@end




@implementation NSColor (MDAdditions)

- (NSString *)hexValue {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSString *hexValue = nil;
	NSColor *convertedColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	
	if (convertedColor) {
		CGFloat red;
		CGFloat green;
		CGFloat blue;
		
		[convertedColor getRed:&red green:&green blue:&blue alpha:NULL];
		
		NSInteger redInt = red * 255.99999f;
		NSInteger greenInt = green * 255.99999f;
		NSInteger blueInt = blue * 255.99999f;
		
		hexValue = [NSString stringWithFormat:@"#%02x%02x%02x", (unsigned int)redInt, (unsigned int)greenInt, (unsigned int)blueInt];
		
	}
	
	return hexValue;
}

@end


@implementation NSFont (MDAdditions)

- (NSString *)cssRepresentation {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSString *cssRepresentation = @"";
	
	NSString *familyName = [self familyName];
	
	if (familyName) {
		NSFontSymbolicTraits symbolicTraits = [[self fontDescriptor] symbolicTraits];
		
//		NSLog(@"[NSFont cssRepresentation] symbolicTraits == %u", symbolicTraits);
		BOOL isSansSerif = (symbolicTraits & NSFontSansSerifClass);
		BOOL isBold = (symbolicTraits & NSFontBoldTrait);
		BOOL isItalic = (symbolicTraits & NSFontItalicTrait);
		
		if (isSansSerif) {
			cssRepresentation = [cssRepresentation stringByAppendingString:[NSString stringWithFormat:@"\nfont-family: \"%@\", sans-serif;", familyName]];
			
		} else {
			cssRepresentation = [cssRepresentation stringByAppendingString:[NSString stringWithFormat:@"\nfont-family: \"%@\", serif;", familyName]];
			
		}
		
		if (isBold) {
			cssRepresentation = [cssRepresentation stringByAppendingString:@"\nfont-weight: bold;"];
		}
		
		if (isItalic) {
			cssRepresentation = [cssRepresentation stringByAppendingString:@"\nfont-style: italic;"];
		}
		
	}
	return cssRepresentation;
}

@end




@implementation NSMenu (MDAdditions)


- (BOOL)containsItem:(NSMenuItem *)aMenuItem {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return (!([self indexOfItem:aMenuItem] == -1));
}

- (void)setItemArray:(NSArray *)newArray {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[self removeAllItems];
	NSUInteger newCount = [newArray count];
	NSUInteger i;
	
	for (i = 0; i < newCount; i++) {
		[self insertItem:[newArray objectAtIndex:i] atIndex:i];
		
		if ([[self itemAtIndex:i] respondsToSelector:@selector(isHidden)] &&
			[[self itemAtIndex:i] respondsToSelector:@selector(setHidden:)]) {
			
			if ([[self itemAtIndex:i] isHidden]) {
				NSLog(@"[%@ %@] itemAtIndex %lu is hidden!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)i);
				[[self itemAtIndex:i] setHidden:NO];
			}
		}
	}
}


- (void)removeAllItems {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *currentArray = [self itemArray];
	NSUInteger currentCount = [currentArray count];
	NSUInteger i;
	
	for (i = 0; i < currentCount; i++) {
		[self removeItemAtIndex:0];
	}
}


@end


@implementation NSOpenPanel (MDAdditions)

+ (NSOpenPanel *)openPanelWithTitle:(NSString *)title
							message:(NSString *)message
				  actionButtonTitle:(NSString *)actionButtonTitle
			allowsMultipleSelection:(BOOL)allowsMultipleSelection
			   canChooseDirectories:(BOOL)canChooseDirectories
						   delegate:(id <NSOpenSavePanelDelegate>)delegate {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	if (title) [openPanel setTitle:title];
	if (message) [openPanel setMessage:message];
	if (actionButtonTitle) [openPanel setPrompt:actionButtonTitle];
	[openPanel setAllowsMultipleSelection:allowsMultipleSelection];
	[openPanel setCanChooseDirectories:canChooseDirectories];
	if (delegate) [openPanel setDelegate:delegate];
	return openPanel;
}

@end





@implementation NSPopUpButton (MDAdditions)

- (void)setItemArray:(NSArray *)value {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	BOOL isPulldown = [self pullsDown];
	
	NSMenu *theMenu = [self menu];
	
	[theMenu setItemArray:value];
	
	if (isPulldown && [[theMenu itemAtIndex:0] respondsToSelector:@selector(setHidden:)]) {
		[[theMenu itemAtIndex:0] setHidden:YES];
	}
}

@end


@implementation NSToolbarItem (MDAdditions)
+ (id)toolbarItemWithItemIdentifier:(NSString *)anIdentifier tag:(NSInteger)aTag image:(NSImage *)anImage label:(NSString *)aLabel paletteLabel:(NSString *)aPaletteLabel target:(id)anObject action:(SEL)anAction {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSToolbarItem *toolbarItem = [[[[self class] alloc] initWithItemIdentifier:anIdentifier] autorelease];
	[toolbarItem setTag:aTag];
	[toolbarItem setImage:anImage];
	[toolbarItem setLabel:aLabel];
	[toolbarItem setPaletteLabel:aPaletteLabel];
	[toolbarItem setTarget:anObject];
	[toolbarItem setAction:anAction];
	return toolbarItem;
}
@end


@implementation NSUserDefaults (MDAdditions)


- (void)setFont:(NSFont *)aFont forKey:(NSString *)aKey {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSData *data = nil;
	data = [NSKeyedArchiver archivedDataWithRootObject:aFont];
	if (data) {
		[self setObject:data forKey:aKey];
	}
}

- (NSFont *)fontForKey:(NSString *)aKey {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSData *data = nil;
	NSFont *font = nil;
	
	data = [self objectForKey:aKey];
	font = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	if (![font isKindOfClass:[NSFont class]]) {
		font = nil;
	}
	return font;
}

- (void)setColor:(NSColor *)aColor forKey:(NSString *)aKey {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSData *data = nil;
	data = [NSKeyedArchiver archivedDataWithRootObject:aColor];
	if (data) {
		[self setObject:data forKey:aKey];
	}
}

- (NSColor *)colorForKey:(NSString *)aKey {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSData *data = nil;
	NSColor *color = nil;
	
	data = [self objectForKey:aKey];
	color = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	
	if (![color isKindOfClass:[NSColor class]]) {
		color = nil;
	}
	return color;
}


@end


@implementation NSView (MDAdditions)

- (void)setFrameFromString:(NSString *)aString {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSRect boundsRect;
	NSArray *boundsArray = [aString componentsSeparatedByString:@" "];
	
	if ([boundsArray count] != 4) {
		NSLog(@"[%@ %@] count of bounds array != 4, aborting...", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	} else {
		boundsRect.origin.x = 0.0;
		boundsRect.origin.y = 0.0;
		boundsRect.size.width = [[boundsArray objectAtIndex:2] floatValue];
		boundsRect.size.height = [[boundsArray objectAtIndex:3] floatValue];
		
		[self setFrame:boundsRect];
	}
	
}


- (NSString *)stringWithSavedFrame {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSRect frameRect = [self frame];
	
	NSString *dimensionString = [NSString stringWithFormat:@"%ld %ld %ld %ld", (long)frameRect.origin.x, (long)frameRect.origin.y, (long)frameRect.size.width, (long)frameRect.size.height];
	
	return dimensionString;
}

@end


static NSView *blankView() {
	static NSView *view = nil;
	if (!view) {
		view = [[NSView alloc] init];
	}
	return view;
} 

@implementation NSWindow (MDAdditions)

- (CGFloat)toolbarHeight {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSToolbar *toolbar = [self toolbar];
	CGFloat toolbarHeight = 0.0;
	NSRect windowFrame;
	
	if (toolbar && [toolbar isVisible]) {
		windowFrame = [[self class] contentRectForFrameRect:[self frame] styleMask:[self styleMask]];
		toolbarHeight = NSHeight(windowFrame) - NSHeight([[self contentView] frame]);
	}
	return toolbarHeight;
}


- (void)resizeToSize:(NSSize)newSize {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSRect aFrame;
	
	CGFloat newHeight = newSize.height + [self toolbarHeight];
	CGFloat newWidth = newSize.width;
	
	aFrame = [[self class] contentRectForFrameRect:[self frame] styleMask:[self styleMask]];
	
	aFrame.origin.y += aFrame.size.height;
	aFrame.origin.y -= newHeight;
	aFrame.size.height = newHeight;
	aFrame.size.width = newWidth;
	
	aFrame = [[self class] frameRectForContentRect:aFrame styleMask:[self styleMask]];
	
	[self setFrame:aFrame display:YES animate:YES];
}


- (void)switchView:(NSView *)aView newTitle:(NSString *)aString {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([self contentView] != aView) {
		[self setContentView:blankView()];
		[self setTitle:NSLocalizedString(aString, @"")];
		[self resizeToSize:[aView frame].size];
		[self setContentView:aView];
		//[self setShowsResizeIndicator:NO];
	}
}

- (void)switchView:(NSView *)aView {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([self contentView] != aView) {
		[self setContentView:blankView()];
		[self resizeToSize:[aView frame].size];
		[self setContentView:aView];
		//[self setShowsResizeIndicator:NO];
	}
}


@end



@implementation NSWorkspace (MDAdditions)


// TODO: For 10.5+, rewrite to use Scripting Bridge rather than NSAppleScript
- (BOOL)revealInFinder:(NSArray *)filePaths {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (MDGetSystemVersion() >= MDSnowLeopard) {
		NSMutableArray *URLs = [NSMutableArray array];
		for (NSString *path in filePaths) {
			NSURL *URL = [NSURL fileURLWithPath:path];
			if (URL) [URLs addObject:URL];
		}
		[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:URLs];
		return YES;
	}
	return NO;
	
//	BOOL success = YES;
//	
//	/* If we are given a list of multiple files to reveal, and any of those
//	 files is within the same parent folder, then we do the smart thing and 
//	 create a single Finder window where the selection will be of multiple files.
//	 This is far better than spamming the user with new windows for each individual file. */
//	
//	NSMutableDictionary *groupedFilePaths = [NSMutableDictionary dictionary];
//	
//	for (NSString *filePath in filePaths) {
//		NSString *parentDirectory = [filePath stringByDeletingLastPathComponent];
//		
//		if ([groupedFilePaths objectForKey:parentDirectory] == nil) {
//			NSMutableArray *files = [NSMutableArray arrayWithObject:filePath];
//			[groupedFilePaths setObject:files forKey:parentDirectory];
//			
//		} else {
//			[[groupedFilePaths objectForKey:parentDirectory] addObject:filePath];
//		}
//	}
//	
//	NSArray *folderPaths = [groupedFilePaths allKeys];
//	
//	for (NSString *folderPath in folderPaths) {
//		NSArray *files = [groupedFilePaths objectForKey:folderPath];
//		
//		NSString *applescriptListString = NSStringForAppleScriptListFromPaths(files);
//		
//		NSDictionary *errorMessage = nil;
//		NSAppleEventDescriptor *result = nil;
//		
//		NSAppleScript *script = [[[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:@"set targetFolder to (POSIX path of ((\"%@\" as POSIX file) as alias))\nset fileList to %@\n\ntell application \"Finder\"\n	activate\n	set finderWindows to every Finder window\n	repeat with i from 1 to (count of finderWindows)\n		set finderWindow to item i of finderWindows\n		try\n			set targetPath to (POSIX path of ((target of finderWindow) as alias))\n			if targetPath = targetFolder then\n				select every item of fileList\n				return\n			end if\n		end try\n	end repeat\n	set newWindow to make new Finder window to (targetFolder as POSIX file)\n	select every item of fileList\nend tell", folderPath, applescriptListString]] autorelease];
//		
//		if (script) {
//			result = [script executeAndReturnError:&errorMessage];
//			
//			if (errorMessage) {
//				NSLog(@"%@", errorMessage);
//				success = NO;
//			}
//		} else {
//			success = NO;
//		}
//	}
//	return success;
}



- (NSImage *)iconForApplicationForURL:(NSURL *)aURL {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSImage *image = nil;
	if (aURL) {
		FSRef appRef;
		NSString *appPath = nil;
		OSStatus status = noErr;
		
		status = LSGetApplicationForURL((CFURLRef)aURL, kLSRolesAll, &appRef, NULL);
		if (status == noErr) {
			appPath = [NSString stringWithFSRef:&appRef];
			if (appPath) {
				image = [self iconForFile:appPath];
			}
		}
		
	}
	return image;
}

- (NSString *)absolutePathForAppBundleWithIdentifier:(NSString *)aBundleIdentifier name:(NSString *)aNameWithDotApp creator:(NSString *)creator {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSString *absolutePath = nil;
	if (aBundleIdentifier || aNameWithDotApp || creator) {
		FSRef fileRef;
		OSType creatorCode = kLSUnknownCreator;
		if (creator) {
			OSType creatorType = NSHFSTypeCodeFromFileType(creator);
			if (creatorType != 0) {
				creatorCode = creatorType;
			}
		}
		OSStatus status = noErr;
		status = LSFindApplicationForInfo(creatorCode, (aBundleIdentifier ? (CFStringRef)aBundleIdentifier : NULL), (aNameWithDotApp ? (CFStringRef)aNameWithDotApp : NULL), &fileRef, NULL);
		
		if (status == noErr) {
			absolutePath = [NSString stringWithFSRef:&fileRef];
		}
	}
	return absolutePath;
}


- (BOOL)launchApplicationAtPath:(NSString *)path arguments:(NSArray *)argv error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	BOOL success = YES;
	if (outError) *outError = nil;
	
	if (path) {
		FSRef itemRef;
		if ([path getFSRef:&itemRef error:outError]) {
			LSApplicationParameters appParameters = {0, kLSLaunchDefaults, &itemRef, NULL, NULL, (argv ? (CFArrayRef)argv : NULL), NULL };
			OSStatus status = noErr;
			status = LSOpenApplication(&appParameters, NULL);
			
			if (status != noErr) {
				success = NO;
				NSLog(@"[%@ %@] LSOpenApplication() returned %d for %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (int)status, path);
				if (outError) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
			}
		}
	}
	return success;
}

@end



