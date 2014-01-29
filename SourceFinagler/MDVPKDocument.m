//
//  MDVPKDocument.m
//  Source Finagler
//
//  Created by Mark Douma on 9/10/2010.
//  Copyright © 2010-2011 Mark Douma LLC. All rights reserved.
//

#import "MDVPKDocument.h"
#import "MDVPKViewController.h"
#import "MDInspectorView.h"
#import <HLKit/HLKit.h>
#import "MDAppKitAdditions.h"
#import "MDStatusImageView.h"
#import <SteamKit/SteamKit.h>
#import <CoreServices/CoreServices.h>
#import "MDBottomBar.h"



#define MD_DEBUG 0



@implementation MDVPKDocument

@synthesize viewController;


- (void)dealloc {
	[viewController release];
	[super dealloc];
}


/* We need to override setup and teardown in cases where the VPK document is multipart archive and can't be viewed */

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	HKVPKFile *vpkFile = (HKVPKFile *)self.file;
	
	if (vpkFile.vpkArchiveType == HKVPKMultipartArchiveType) {
		
		[outlineViewMenuHelpMenuItem retain];
		[outlineViewMenuShowInspectorMenuItem retain];
		[outlineViewMenuShowViewOptionsMenuItem retain];
		
		if (MDGetSystemVersion() >= MDSnowLeopard) {
			[browserMenuShowInspectorMenuItem retain];
			[browserMenuShowViewOptionsMenuItem retain];
		}
		
		NSMenu *actionButtonMenu = [actionButton menu];
		
		if (actionButtonMenu) {
			if ([actionButtonMenu numberOfItems]) {
				actionButtonActionImageItem = [[[actionButton menu] itemAtIndex:0] retain];
			}
		}
		
		[actionButtonShowInspectorMenuItem retain];
		[actionButtonShowViewOptionsMenuItem retain];
		
		[searchInspectorView setShown:NO];
		
		[pathControlInspectorView setShown:NO];
		
		if (file) {
			statusImageViewTag1 = [statusImageView1 addToolTipRect:[statusImageView1 visibleRect] owner:self userData:nil];
			statusImageViewTag2 = [statusImageView2 addToolTipRect:[statusImageView2 visibleRect] owner:self userData:nil];
		}
		
		
		if (viewController == nil) {
			viewController = [[MDVPKViewController alloc] init];
			viewController.document = self;
		}
		
		// force view to load
		NSRect contentRect = viewController.view.frame;
		
		// add in the bottom bar height
		contentRect.size.height += NSHeight(bottomBar.bounds);
		
		[hlWindow setContentSize:contentRect.size];
		
		[mainBox setContentView:viewController.view];
		
		// set min size
		[hlWindow setMinSize:[hlWindow contentRectForFrameRect:hlWindow.frame].size];
		
		
		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[[self fileURL] path]];
		[icon setSize:NSMakeSize(128.0, 128.0)];
		[self setImage:icon];
		[self setVersion:[file version]];
		
		
		for (NSUInteger i = 0; i < viewSwitcherControl.segmentCount; i++) {
			[viewSwitcherControl setEnabled:NO forSegment:i];
		}
		
		[searchField setEnabled:NO];
		
		if ([[[NSUserDefaults standardUserDefaults] objectForKey:MDVPKAlwaysOpenArchiveDirectoryFileKey] boolValue]) {
			
			if (vpkFile.archiveDirectoryFilePath) {
				[self performSelector:@selector(openDirectoryFile:) withObject:nil afterDelay:0.0];
			}
		}
		
	} else {
		[super windowControllerDidLoadNib:aController];
		
		if (vpkFile.vpkArchiveType == HKVPKSourceAddonFileArchiveType) {
			
			[statusImageView3 setHidden:NO];
			statusImageViewTag3 = [statusImageView3 addToolTipRect:[statusImageView3 visibleRect] owner:self userData:nil];
			
			NSError *error = nil;
			
			VSSourceAddon *sourceAddon = [VSSourceAddon sourceAddonWithContentsOfURL:[NSURL fileURLWithPath:vpkFile.filePath] error:&error];
			
			[installSourceAddonButton setHidden:sourceAddon.isInstalled];
		}
	}
}


- (void)windowWillClose:(NSNotification *)notification {
	
	if ([notification object] == hlWindow) {
#if MD_DEBUG
		NSLog(@" \"%@\" [%@ %@] our window", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		
		HKVPKFile *vpkFile = (HKVPKFile *)self.file;
		
		if (vpkFile.vpkArchiveType == HKVPKMultipartArchiveType) {
			
			[[NSNotificationCenter defaultCenter] postNotificationName:MDSelectedItemsDidChangeNotification
																object:self
															  userInfo:nil];
			
			[[NSNotificationCenter defaultCenter] removeObserver:self];
			
		} else {
			[super windowWillClose:notification];
			
		}
	}	
}


- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)userData {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSUInteger modifierFlags = [[NSApp currentEvent] modifierFlags];
	
	if (modifierFlags & NSCommandKeyMask) {
		
#if MD_DEBUG
		NSLog(@" \"%@\" [%@ %@] NSCommandKeyMask", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		if (tag == statusImageViewTag3) {
			return NSLocalizedString(@"Indicates that this Source Valve Package file is a Source Addon file", @"");
		}
	} else {
		if (tag == statusImageViewTag3) {
			return NSLocalizedString(@"This is a Source Addon file", @"");
		}
	}
	return [super view:view stringForToolTip:tag point:point userData:userData];
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	
	HKVPKFile *vpkFile = (HKVPKFile *)self.file;
	
	if (vpkFile.vpkArchiveType == HKVPKMultipartArchiveType) {
		
		SEL action = menuItem.action;
		
		if (action == @selector(switchViewMode:)) {
			[menuItem setState:NSOffState];
			return NO;
		}
	}
	return [super validateMenuItem:menuItem];
}



- (IBAction)openDirectoryFile:(id)sender {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	HKVPKFile *vpkFile = (HKVPKFile *)self.file;
	
	[[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:[NSURL fileURLWithPath:vpkFile.archiveDirectoryFilePath]]
					withAppBundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]
									options:NSWorkspaceLaunchDefault
			 additionalEventParamDescriptor:nil
						  launchIdentifiers:NULL];
	
	[self close];
}


- (IBAction)installSourceAddon:(id)sender {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"Source Addon Finagler" ofType:@"app"];
	
	if (path == nil) {
		NSLog(@"[%@ %@] *** ERROR: could not find Source Addon Finagler inside the app bundle!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		NSBeep();
		return;
	}
	
	NSURL *sourceAddonFinaglerURL = [NSURL fileURLWithPath:path];
	
	LSLaunchURLSpec spec = {
		.appURL = (CFURLRef)sourceAddonFinaglerURL,
		.itemURLs = (CFArrayRef)[NSArray arrayWithObject:[NSURL fileURLWithPath:self.file.filePath]],
		.passThruParams = NULL,
		.launchFlags = kLSLaunchDefaults,
		.asyncRefCon = NULL,
	};
	
	OSStatus status = LSOpenFromURLSpec(&spec, NULL);
	
	if (status) {
		NSLog(@"[%@ %@] *** ERROR: LSOpenFromURLSpec() returned status == %ld", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (long)status);
		NSBeep();
		return;
	}
	
	[self close];
}


	
@end

