//
//  TKImageInspectorController.m
//  Source Finagler
//
//  Created by Mark Douma on 10/24/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import "TKImageInspectorController.h"
#import "MDAppKitAdditions.h"
#import "TKImageChannel.h"
#import "TKImageChannelCell.h"
#import "TKImageDocument.h"

#import "MDAppController.h"


#define TK_DEBUG 1


static TKImageInspectorController *sharedController = nil;


@implementation TKImageInspectorController

@synthesize dataSource;


+ (TKImageInspectorController *)sharedController {
	@synchronized(self) {
		if (sharedController == nil) {
			sharedController = [[super allocWithZone:NULL] init];
		}
	}
	return sharedController;
}

+ (id)allocWithZone:(NSZone *)zone {
	return [[self sharedController] retain];
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

- (id)retain {
	return self;
}

- (NSUInteger)retainCount {
	return NSUIntegerMax;	//denotes an object that cannot be released
}

- (oneway void)release {
	// do nothing
}

- (id)autorelease {
	return self;
}

- (id)init {
	if ((self = [super initWithWindowNibName:@"TKImageInspector"])) {
		// force load nib?
		[self window];
	} else {
		[NSBundle runFailedNibLoadAlert:@"TKImageInspector"];
	}		
	return self;
}


- (void)awakeFromNib {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResizeNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
}


- (void)windowDidBecomeMain:(NSNotification *)notification {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (appIsTerminating) return;

	
	NSWindow *window = [notification object];
	NSDocument *document = [[NSDocumentController sharedDocumentController] documentForWindow:window];
	
	if (document == nil) return;
	
	BOOL acceptsControl = NO;
	
	if ([document respondsToSelector:@selector(acceptsImageInspectorControl:)]) {
		acceptsControl = [document acceptsImageInspectorControl:self];
	}
	
	if (acceptsControl) {
		[document beginImageInspectorControl:self];
		[document performSelector:@selector(beginImageInspectorControl:) withObject:self afterDelay:0.0];
	}
}


- (void)windowDidResignMain:(NSNotification *)notification {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}




- (void)reloadData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
//	if (dataSource == nil) {
//		NSLog(@"[%@ %@] ERROR: No dataSource is set up!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//		return;
//	}
	
	[tableView reloadData];
}



- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (aTableView == tableView) {
		return [dataSource numberOfImageChannelsInImageInspector:self];
		
	}
	return 0;
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (aTableView == tableView) {
		TKImageChannel *imageChannel = [dataSource imageChannelAtIndex:rowIndex];
		
		return [imageChannel valueForKey:[tableColumn identifier]];
		
	}
	return nil;
}


- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (aTableView == tableView) {
		if ([[tableColumn identifier] isEqualToString:@"name"]) {
			TKImageChannel *imageChannel = [dataSource imageChannelAtIndex:rowIndex];
			[(TKImageChannelCell *)cell setImage:[imageChannel image]];
		}
	}
}


- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@] object == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), object);
#endif
	if (aTableView == tableView) {
		if ([[tableColumn identifier] isEqualToString:@"enabled"]) {
			TKImageChannel *imageChannel = [dataSource imageChannelAtIndex:rowIndex];
			[imageChannel setEnabled:[object boolValue]];
			
			if ([object boolValue]) {
				if ([dataSource respondsToSelector:@selector(imageInspectorController:didEnableImageChannel:)]) {
//					[dataSource performSelector:@selector( withObject:(id)object
					[dataSource imageInspectorController:self didEnableImageChannel:imageChannel];
				}
				
			} else {
				if ([dataSource respondsToSelector:@selector(imageInspectorController:didDisableImageChannel:)]) {
					[dataSource imageInspectorController:self didDisableImageChannel:imageChannel];
				}
				
			}
			
		}
		
	}
}


- (void)tableViewSelectionDidChange:(NSNotification *)notification {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
//	NSIndexSet *selectedIndexes = [tableView selectedRowIndexes];
	
//	NSArray *
}


- (IBAction)showWindow:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	TKShouldShowImageInspector = YES;
	[[self window] orderFront:nil];
	
	NSWindow *mainWindow = [NSApp mainWindow];
	NSDocument *document = [[NSDocumentController sharedDocumentController] documentForWindow:mainWindow];
	
	if (document == nil) return;
	
	BOOL acceptsControl = NO;
	
	if ([document respondsToSelector:@selector(acceptsImageInspectorControl:)]) {
		acceptsControl = [document acceptsImageInspectorControl:self];
	}
	
	if (acceptsControl) {
		[document beginImageInspectorControl:self];
		[document performSelector:@selector(beginImageInspectorControl:) withObject:self afterDelay:0.0];
	}
	
//	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:TKShouldShowImageInspector] forKey:TKShouldShowImageInspectorKey];
//	[[NSNotificationCenter defaultCenter] postNotificationName:TKShouldShowImageInspectorDidChangeNotification object:self userInfo:nil];
}


- (void)windowWillClose:(NSNotification *)notification {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (appIsTerminating) return;
	
	if ([notification object] == [self window]) {
		if (dataSource && [dataSource respondsToSelector:@selector(endImageInspectorControl:)]) {
			[(TKImageDocument *)dataSource endImageInspectorControl:self];
		}
		TKShouldShowImageInspector = NO;
//		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:TKShouldShowImageInspector] forKey:TKShouldShowImageInspectorKey];
//		[[NSNotificationCenter defaultCenter] postNotificationName:TKShouldShowImageInspectorDidChangeNotification object:self userInfo:nil];
	}
}


- (void)applicationWillTerminate:(NSNotification *)notification {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	appIsTerminating = YES;
}


@end







