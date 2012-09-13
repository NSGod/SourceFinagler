//
//  MDInspectorController.m
//  Source Finagler
//
//  Created by Mark Douma on 1/28/2008.
//  Copyright © 2008 Mark Douma. All rights reserved.
//



#import "MDInspectorController.h"
#import "MDAppController.h"

#import "MDHLDocument.h"

#import "MDAppKitAdditions.h"

#import <HLKit/HLKit.h>


//#define MD_DEBUG 1
#define MD_DEBUG 0


@implementation MDInspectorController


- (id)init {
	if ((self = [super initWithWindowNibName:@"MDInspector"])) {
		
	} else {
		[NSBundle runFailedNibLoadAlert:@"MDInspector"];
	}
	return self;
}


- (void)dealloc {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}



- (void)awakeFromNib {
	[(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedItemsDidChange:) name:MDSelectedItemsDidChangeNotification object:nil];
}


- (void)selectedItemsDidChange:(NSNotification *)notification {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSArray *newSelectedItems = [[notification userInfo] objectForKey:MDSelectedItemsKey];
	MDHLDocument *newDocument = [[notification userInfo] objectForKey:MDSelectedItemsDocumentKey];
	
	if (newDocument && newSelectedItems) {
		
		if ([newSelectedItems count] == 0) {
			[[self window] setRepresentedFilename:[[newDocument fileURL] path]];
			[[self window] setTitle:[[newDocument displayName] stringByAppendingString:NSLocalizedString(@" Info", @"")]];
			
			[previewViewController setRepresentedObject:newDocument];
			
			[nameField setStringValue:[newDocument displayName]];
			[whereField setStringValue:[[newDocument fileURL] path]];
			
			NSImage *fileIcon = [[NSWorkspace sharedWorkspace] iconForFile:[[newDocument fileURL] path]];
			[iconImageView setImage:fileIcon];
			
			[headerSizeField setObjectValue:[newDocument fileSize]];
			[dateModifiedField setObjectValue:[newDocument fileModificationDate]];
			
			
			[kindField setStringValue:[newDocument kind]];
			[sizeField setObjectValue:[newDocument fileSize]];
			
			
		} else if ([newSelectedItems count] == 1) {
			
			HKItem *item = [newSelectedItems objectAtIndex:0];
			
			[[self window] setRepresentedFilename:@""];
			[[self window] setTitle:[[item name] stringByAppendingString:NSLocalizedString(@" Info", @"")]];
			
			[previewViewController setRepresentedObject:item];
			
			[kindField setStringValue:[item kind]];
			
			NSImage *image = [HKItem copiedImageForItem:item];

			[image setSize:NSMakeSize(32.0, 32.0)];
			[iconImageView setImage:image];
			
			[nameField setStringValue:[item name]];
//			NSString *path = [[[newDocument fileURL] path] stringByAppendingPathComponent:[[item path] stringByDeletingLastPathComponent]]
			[whereField setStringValue:[[[newDocument fileURL] path] stringByAppendingPathComponent:[[item path] stringByDeletingLastPathComponent]]];
			
			[headerSizeField setObjectValue:[item size]];
			[dateModifiedField setObjectValue:[newDocument fileModificationDate]];
			[sizeField setObjectValue:[item size]];
			
		} else if ([newSelectedItems count] > 1) {
			
			[[self window] setRepresentedFilename:@""];
			[[self window] setTitle:NSLocalizedString(@"Multiple Item Info", @"")];
			
			[previewViewController setRepresentedObject:nil];
			
			[whereField setStringValue:[[newDocument fileURL] path]];
						
			[nameField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%lu items", @""), (unsigned long)[newSelectedItems count]]];
			
			unsigned long long totalSize = 0;
			
			for (HKItem *item in newSelectedItems) {
				if ([item isLeaf]) {
					totalSize += [[item size] unsignedLongLongValue];
				}
			}
			
			[sizeField setObjectValue:[NSNumber numberWithUnsignedLongLong:totalSize]];
			[headerSizeField setObjectValue:[NSNumber numberWithUnsignedLongLong:totalSize]];
			
			[kindField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%lu documents", @""), (unsigned long)[newSelectedItems count]]];
			
			[iconImageView setImage:[NSImage imageNamed:@"multipleItems"]];
			
			[dateModifiedField setObjectValue:[newDocument fileModificationDate]];
			
		}
		
	} else {
		/* a document is being closed, so set stuff to an intermediary "--" */
		
		[[self window] setRepresentedFilename:@""];
		
		[[self window] setTitle:NSLocalizedString(@"Info", @"")];
		
		[previewViewController setRepresentedObject:nil];
		
		[iconImageView setImage:[NSImage imageNamed:@"genericDocument32"]];
		
		[nameField setStringValue:NSLocalizedString(@"--", @"")];
		[headerSizeField setStringValue:NSLocalizedString(@"--", @"")];
		[dateModifiedField setStringValue:NSLocalizedString(@"--", @"")];
		
		[kindField setStringValue:NSLocalizedString(@"--", @"")];
		[sizeField setStringValue:NSLocalizedString(@"--", @"")];
		[whereField setStringValue:NSLocalizedString(@"--", @"")];
		
		
	}
	
}


- (IBAction)showWindow:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	MDShouldShowInspector = YES;
	[[self window] orderFront:nil];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:MDShouldShowInspector] forKey:MDShouldShowInspectorKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:MDShouldShowInspectorDidChangeNotification object:self userInfo:nil];
}


- (void)windowWillClose:(NSNotification *)notification {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if ([notification object] == [self window]) {
		MDShouldShowInspector = NO;
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:MDShouldShowInspector] forKey:MDShouldShowInspectorKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:MDShouldShowInspectorDidChangeNotification object:self userInfo:nil];
	}
}



@end


