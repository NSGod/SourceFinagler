//
//  TKAppController.h
//  Source Finagler
//
//  Created by Mark Douma on 5/12/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TKAboutWindowController;
@class TKPrefsController;
@class TKImageInspectorController;

@class MDViewOptionsController;
@class MDInspectorController;
@class MDQuickLookController;


enum {
	TKLaunchTimeActionNone				= 0,
	TKLaunchTimeActionOpenMainWindow	= 1,
	TKLaunchTimeActionOpenNewDocument	= 2
};
typedef NSUInteger TKLaunchTimeActionType;

extern NSString * const TKLaunchTimeActionKey;

extern NSString * const TKLastWindowDidCloseNotification;


extern BOOL			MDShouldShowViewOptions;
extern BOOL			MDShouldShowInspector;
extern BOOL			MDShouldShowQuickLook;

extern BOOL			TKShouldShowImageInspector;

extern BOOL			MDShouldShowPathBar;

extern BOOL			MDPlaySoundEffects;

extern SInt32		TKSystemVersion;


@interface TKAppController : NSObject <NSApplicationDelegate, NSOpenSavePanelDelegate, NSToolbarDelegate, NSSoundDelegate> {
    IBOutlet NSWindow					*window;
	
	IBOutlet NSMenuItem					*toggleInspectorMenuItem;
	IBOutlet NSMenuItem					*toggleQuickLookMenuItem;
	
	IBOutlet NSMenu						*viewMenu;
	IBOutlet NSMenuItem					*viewModeAsListMenuItem;
	IBOutlet NSMenuItem					*viewModeAsColumnsMenuItem;
	
	IBOutlet NSMenuItem					*viewTogglePathBarMenuItem;
	
	IBOutlet NSMenuItem					*viewToggleToolbarShownMenuItem;
	IBOutlet NSMenuItem					*viewCustomizeToolbarMenuItem;
	
	IBOutlet NSMenuItem					*viewOptionsMenuItem;
	
	IBOutlet NSMenuItem					*debugMenuItem;
	
	IBOutlet NSMenuItem					*emailMenuItem;
	IBOutlet NSMenuItem					*chatMenuItem;
	IBOutlet NSMenuItem					*webpageMenuItem;
	
	TKAboutWindowController				*aboutWindowController;
	MDInspectorController				*inspectorController;
	MDViewOptionsController				*viewOptionsController;
	MDQuickLookController				*quickLookController;
	
	TKPrefsController					*prefsController;
	
	
	NSUndoManager						*globalUndoManager;
	
	
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


