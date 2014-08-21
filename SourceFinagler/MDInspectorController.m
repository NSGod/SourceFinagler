//
//  MDInspectorController.m
//  Source Finagler
//
//  Created by Mark Douma on 1/28/2008.
//  Copyright © 2008 Mark Douma. All rights reserved.
//



#import "MDInspectorController.h"
#import "MDHLDocument.h"
#import "MDAppKitAdditions.h"
#import <HLKit/HLKit.h>
#import "MDDateFormatter.h"
#import "MDFileSizeFormatter.h"



#define MD_DEBUG 0


@interface MDInspectorController (MDPrivate)
- (void)updateUIWithDocument:(MDHLDocument *)document;
@end



@implementation MDInspectorController


- (id)init {
	if ((self = [super initWithWindowNibName:@"MDInspector"])) {
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedItemsDidChange:) name:MDHLDocumentSelectedItemsDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentWillClose:) name:MDHLDocumentWillCloseNotification object:nil];
		
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
	[headerSizeField setFormatter:[[[MDFileSizeFormatter alloc] initWithUnitsType:MDFileSizeFormatterAutomaticUnitsType
																			style:MDFileSizeFormatterPhysicalStyle] autorelease]];
	[sizeField setFormatter:[[[MDFileSizeFormatter alloc] initWithUnitsType:MDFileSizeFormatterAutomaticUnitsType
																	  style:MDFileSizeFormatterFullStyle] autorelease]];
	
	[dateModifiedField setFormatter:[[[MDDateFormatter alloc] initWithStyle:MDDateFormatterMediumStyle
																 isRelative:YES] autorelease]];
	
	[(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];
	
	[self updateUIWithDocument:nil];
}


- (void)updateUIWithDocument:(MDHLDocument *)document {
#if MD_DEBUG
//    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (document == nil) {
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
		
	} else {
		
		NSArray *newSelectedItems = document.selectedItems;
		
		if ([newSelectedItems count] == 0) {
			[[self window] setRepresentedFilename:[[document fileURL] path]];
			[[self window] setTitle:[[document displayName] stringByAppendingString:NSLocalizedString(@" Info", @"")]];
			
			[previewViewController setRepresentedObject:document];
			
			[nameField setStringValue:[document displayName]];
			[whereField setStringValue:[[document fileURL] path]];
			
			NSImage *fileIcon = [[NSWorkspace sharedWorkspace] iconForFile:[[document fileURL] path]];
			[iconImageView setImage:fileIcon];
			
			[headerSizeField setObjectValue:[document fileSize]];
			[dateModifiedField setObjectValue:[document fileModificationDate]];
			
			
			[kindField setStringValue:[document kind]];
			[sizeField setObjectValue:[document fileSize]];
			
			
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
			[whereField setStringValue:[[[document fileURL] path] stringByAppendingPathComponent:[[item path] stringByDeletingLastPathComponent]]];
			
			[headerSizeField setObjectValue:[item size]];
			[dateModifiedField setObjectValue:[document fileModificationDate]];
			[sizeField setObjectValue:[item size]];
			
		} else if ([newSelectedItems count] > 1) {
			
			[[self window] setRepresentedFilename:@""];
			[[self window] setTitle:NSLocalizedString(@"Multiple Item Info", @"")];
			
			[previewViewController setRepresentedObject:nil];
			
			[whereField setStringValue:[[document fileURL] path]];
						
			[nameField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%lu items", @""), (unsigned long)[newSelectedItems count]]];
			
			unsigned long long totalSize = 0;
			
			for (HKItem *item in newSelectedItems) {
				totalSize += [[item size] unsignedLongLongValue];
			}
			
			[sizeField setObjectValue:[NSNumber numberWithUnsignedLongLong:totalSize]];
			[headerSizeField setObjectValue:[NSNumber numberWithUnsignedLongLong:totalSize]];
			
			[kindField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%lu documents", @""), (unsigned long)[newSelectedItems count]]];
			
			[iconImageView setImage:[NSImage imageNamed:@"multipleItems"]];
			
			[dateModifiedField setObjectValue:[document fileModificationDate]];
			
		}
	}
}


- (void)selectedItemsDidChange:(NSNotification *)notification {
#if MD_DEBUG
	NSLog(@"[%@ %@] notification == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), notification);
#endif
	
	[self updateUIWithDocument:[notification object]];
}


- (void)documentWillClose:(NSNotification *)notification {
#if MD_DEBUG
//    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	NSLog(@"[%@ %@] notification == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), notification);
#endif
	
	MDHLDocument *closingDocument = [notification object];
	
	/* If a document is closing, and it's the document we're currently showing data for,
	 find the next appropriate document to show data for. This is intended for instances where 
	 an MDHLDocument is closed in the background while another non-document window is currently
	 the main window -- in which case there may be no other MDHLDocument that will become 
	 the main window (which is how we get notifications that the user has switched documents). */
	
	/* It's possible that orderedDocuments might be in the wrong order, so we'll remove
	 the closing document from the array, and then use the first of the remaining documents
	 that is found. */
	
	NSMutableArray *orderedDocuments = [[[MDHLDocument orderedDocuments] mutableCopy] autorelease];
	[orderedDocuments removeObject:closingDocument];
	
	if (orderedDocuments.count) {
		[self updateUIWithDocument:[orderedDocuments objectAtIndex:0]];
		
	} else {
		// no documents left
		[self updateUIWithDocument:nil];
	}
	
}



- (IBAction)showWindow:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[[self window] orderFront:nil];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[MDHLDocument shouldShowInspector]] forKey:MDHLDocumentShouldShowInspectorKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:MDHLDocumentShouldShowInspectorDidChangeNotification object:self userInfo:nil];
}


- (void)windowWillClose:(NSNotification *)notification {
	
	if ([notification object] == [self window]) {
#if MD_DEBUG
		NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		[MDHLDocument setShouldShowInspector:NO];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[MDHLDocument shouldShowInspector]] forKey:MDHLDocumentShouldShowInspectorKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:MDHLDocumentShouldShowInspectorDidChangeNotification object:self userInfo:nil];
	}
}



@end


