//
//  MDAppController.h
//  Source Finagler
//
//  Created by Mark Douma on 5/12/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MDAboutWindowController;
@class MDPrefsController;
@class TKImageInspectorController;

@class SUUpdater;

@class MDViewOptionsController;
@class MDInspectorController;
@class MDQuickLookController;


enum {
	MDLaunchTimeActionNone				= 0,
	MDLaunchTimeActionOpenMainWindow	= 1,
	MDLaunchTimeActionOpenNewDocument	= 2
};
typedef NSUInteger MDLaunchTimeActionType;

extern NSString * const MDLaunchTimeActionKey;



extern BOOL			TKShouldShowImageInspector;


@interface MDAppController : NSObject <NSApplicationDelegate, NSOpenSavePanelDelegate, NSToolbarDelegate, NSSoundDelegate, NSMenuDelegate> {
    IBOutlet NSWindow					*window;
	
	IBOutlet NSMenuItem					*viewModeAsColumnsMenuItem;
	
	IBOutlet NSMenuItem					*debugMenuItem;
	
	IBOutlet NSMenuItem					*emailMenuItem;
	IBOutlet NSMenuItem					*chatMenuItem;
	IBOutlet NSMenuItem					*webpageMenuItem;
	
	MDAboutWindowController				*aboutWindowController;
	MDInspectorController				*inspectorController;
	MDViewOptionsController				*viewOptionsController;
	MDQuickLookController				*quickLookController;
	
	MDPrefsController					*prefsController;
		
	IBOutlet SUUpdater					*sparkleUpdater;
	
	
	NSMutableArray						*viewControllers;
	
	NSUInteger							currentViewIndex;
	
	
	TKImageInspectorController			*imageInspectorController;
	
	
}

- (IBAction)switchView:(id)sender;

- (IBAction)toggleShowInspector:(id)sender;
- (IBAction)toggleShowViewOptions:(id)sender;
- (IBAction)toggleShowQuickLook:(id)sender;

- (IBAction)toggleShowImageInspector:(id)sender;


- (IBAction)showAboutWindow:(id)sender;
- (IBAction)showPrefsWindow:(id)sender;

- (IBAction)showMainWindow:(id)sender;



- (IBAction)email:(id)sender;
- (IBAction)chat:(id)sender;
- (IBAction)webpage:(id)sender;

- (IBAction)resetAllWarningDialogs:(id)sender;


@end


