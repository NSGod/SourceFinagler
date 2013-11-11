//
//  MDAppController.h
//  Source Finagler
//
//  Created by Mark Douma on 5/12/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MDAboutWindowController, MDViewOptionsController, MDInspectorController, MDQuickLookController;
@class MDPrefsController;
@class MDSteamAppsRelocatorController, MDOtherAppsHelperController;
@class SUUpdater;

enum {
	MDSteamAppsRelocatorView			= 1,
	MDOtherAppsHelperView				= 2
};


extern NSString * const MDCurrentViewKey;

extern NSString * const MDLastVersionRunKey;

extern NSString * const MDLastSpotlightImporterVersionKey;
extern NSString * const MDLastSourceAddonFinaglerVersionKey;
extern NSString * const MDSpotlightImporterBundleIdentifierKey;


extern NSString * const MDSteamAppsRelocatorIdentifierKey;
extern NSString * const MDOtherAppsHelperIdentifierKey;
extern NSString * const MDConfigCopyIdentifierKey;


enum {
	MDLaunchTimeActionNone				= 0,
	MDLaunchTimeActionOpenMainWindow	= 1,
	MDLaunchTimeActionOpenNewDocument	= 2
};
typedef NSUInteger MDLaunchTimeActionType;

extern NSString * const MDLaunchTimeActionKey;


extern NSString * const MDQuitAfterAllWindowsClosedKey;
extern NSString * const MDLastWindowDidCloseNotification;

extern NSString * const MDFinderBundleIdentifierKey;


/*************		websites & email addresses	*************/

extern NSString * const MDWebpage;
extern NSString * const MDEmailStaticURLString;
extern NSString * const MDEmailDynamicURLString;
extern NSString * const MDEmailAddress;
extern NSString * const MDiChatURLString;


extern BOOL			MDShouldShowViewOptions;
extern BOOL			MDShouldShowInspector;
extern BOOL			MDShouldShowQuickLook;

extern BOOL			MDShouldShowPathBar;

extern BOOL			MDPlaySoundEffects;

extern BOOL			MDPerformingBatchOperation;


extern SInt32 MDSystemVersion;


@interface MDAppController : NSObject <NSApplicationDelegate, NSOpenSavePanelDelegate, NSToolbarDelegate, NSSoundDelegate> {
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
	
	MDAboutWindowController				*aboutWindowController;
	MDInspectorController				*inspectorController;
	MDViewOptionsController				*viewOptionsController;
	MDQuickLookController				*quickLookController;
	
	MDPrefsController					*prefsController;
		
	IBOutlet SUUpdater					*sparkleUpdater;
	
	NSUndoManager						*globalUndoManager;
	
	
	MDSteamAppsRelocatorController		*steamAppsRelocatorController;
	MDOtherAppsHelperController			*otherAppsHelperController;

	NSInteger currentView;
	
	
}

- (IBAction)switchView:(id)sender;

- (IBAction)toggleShowInspector:(id)sender;
- (IBAction)toggleShowViewOptions:(id)sender;
- (IBAction)toggleShowQuickLook:(id)sender;


- (IBAction)showAboutWindow:(id)sender;
- (IBAction)showPrefsWindow:(id)sender;

- (IBAction)showMainWindow:(id)sender;

//- (IBAction)orderFrontHelpPanel:(id)sender;


- (IBAction)email:(id)sender;
- (IBAction)chat:(id)sender;
- (IBAction)webpage:(id)sender;

- (IBAction)resetAllWarningDialogs:(id)sender;

- (NSUndoManager *)globalUndoManager;

@end


