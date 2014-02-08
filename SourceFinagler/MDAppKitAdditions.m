//
//  MDAppKitAdditions.m
//  
//
//  Created by Mark Douma on 6/4/2010.
//  Copyright (c) 2010 Mark Douma LLC. All rights reserved.
//

#import "MDAppKitAdditions.h"

#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1050
#	import <CoreServices/CoreServices.h>
#else
#	import <ApplicationServices/ApplicationServices.h>
#endif


#define MD_DEBUG 0


@implementation NSAlert (MDAppKitAdditions)


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
	NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(id)kCFBundleNameKey];
	if (appName == nil) {
		appName = NSLocalizedString(@"This application", @"");
	}
	NSInteger choice = NSRunCriticalAlertPanel([NSString stringWithFormat:NSLocalizedString(@"%@ encountered an error while trying to load the \"%@\" user interface file.", @""), appName, nibName], NSLocalizedString(@"Please reinstall the application.", @""), NSLocalizedString(@"Quit", @""), nil, nil);
	if (choice == NSAlertDefaultReturn) [NSApp terminate:nil];	
}

@end


@implementation NSMenu (MDAppKitAdditions)


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
#if MD_DEBUG
				NSLog(@"[%@ %@] itemAtIndex %lu is hidden!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)i);
#endif
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


@implementation NSOpenPanel (MDAppKitAdditions)

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





@implementation NSPopUpButton (MDAppKitAdditions)

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



@implementation NSView (MDAppKitAdditions)

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

@implementation NSWindow (MDAppKitAdditions)

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
	CGFloat newHeight = newSize.height + [self toolbarHeight];
	CGFloat newWidth = newSize.width;
	
	NSRect aFrame = [[self class] contentRectForFrameRect:[self frame] styleMask:[self styleMask]];
	
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
		[self setTitle:aString];
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



@implementation NSWorkspace (MDAppKitAdditions)


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
	
	BOOL success = YES;
	
	/* If we are given a list of multiple files to reveal, and any of those
	 files is within the same parent folder, then we do the smart thing and 
	 create a single Finder window where the selection will be of multiple files.
	 This is far better than spamming the user with new windows for each individual file. */
	
	NSMutableDictionary *groupedFilePaths = [NSMutableDictionary dictionary];
	
	for (NSString *filePath in filePaths) {
		NSString *parentDirectory = [filePath stringByDeletingLastPathComponent];
		
		if ([groupedFilePaths objectForKey:parentDirectory] == nil) {
			NSMutableArray *files = [NSMutableArray arrayWithObject:filePath];
			[groupedFilePaths setObject:files forKey:parentDirectory];
			
		} else {
			[[groupedFilePaths objectForKey:parentDirectory] addObject:filePath];
		}
	}
	
	NSArray *folderPaths = [groupedFilePaths allKeys];
	
	for (NSString *folderPath in folderPaths) {
		NSArray *files = [groupedFilePaths objectForKey:folderPath];
		
		NSString *applescriptListString = NSStringForAppleScriptListFromPaths(files);
		
		NSDictionary *errorMessage = nil;
		NSAppleEventDescriptor *result = nil;
		
		NSAppleScript *script = [[[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:@"set targetFolder to (POSIX path of ((\"%@\" as POSIX file) as alias))\nset fileList to %@\n\ntell application \"Finder\"\n	activate\n	set finderWindows to every Finder window\n	repeat with i from 1 to (count of finderWindows)\n		set finderWindow to item i of finderWindows\n		try\n			set targetPath to (POSIX path of ((target of finderWindow) as alias))\n			if targetPath = targetFolder then\n				select every item of fileList\n				return\n			end if\n		end try\n	end repeat\n	set newWindow to make new Finder window to (targetFolder as POSIX file)\n	select every item of fileList\nend tell", folderPath, applescriptListString]] autorelease];
		
		if (script) {
			result = [script executeAndReturnError:&errorMessage];
			
			if (errorMessage) {
				NSLog(@"%@", errorMessage);
				success = NO;
			}
		} else {
			success = NO;
		}
	}
	return success;
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

		
@end



