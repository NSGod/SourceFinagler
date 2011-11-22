//
//  MDNaming.h
//  Source Finagler
//
//  Created by Mark Douma on 12/17/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


//////////////////////////
////// APPKIT


enum {
    NSTextReadInapplicableDocumentTypeError = 65806,		// NSAttributedString parsing error
    NSTextWriteInapplicableDocumentTypeError = 66062,		// NSAttributedString generating error

    // Inclusive error range definitions, for checking future error codes
    NSTextReadWriteErrorMinimum = 65792,
    NSTextReadWriteErrorMaximum = 66303,
    
    // Service error codes
    NSServiceApplicationNotFoundError = 66560,			// The service provider could not be found.
    NSServiceApplicationLaunchFailedError = 66561,		// The service providing application could not be launched.  This will typically contain an underlying error with an LS error code (check MacErrors.h for their meanings).
    NSServiceRequestTimedOutError = 66562,			// The service providing application did not open its service listening port in time, or the app didn't respond to the request in time; see the Console log to figure out which (the errors are typically reported the same way to the user).
    NSServiceInvalidPasteboardDataError = 66563,		// The service providing app did not return a pasteboard with any of the promised types, or we couldn't write the data from the pasteboard to the object receiving the returned data.
    NSServiceMalformedServiceDictionaryError = 66564,		// The service dictionary did not contain the necessary keys.  Messages will typically be logged to the console giving more details.
    NSServiceMiscellaneousError = 66800,			// Other errors, representing programmatic mistakes in the service consuming application.  These show a generic error message to the user.
    
    // Inclusive service error range, for checking future error codes
    NSServiceErrorMinimum = 66560,
    NSServiceErrorMaximum = 66817
};


enum {
    NSWarningAlertStyle = 0,
    NSInformationalAlertStyle = 1,
    NSCriticalAlertStyle = 2
};
typedef NSUInteger NSAlertStyle;





enum {
    NSAnimationEaseInOut,       // default
    NSAnimationEaseIn,
    NSAnimationEaseOut,
    NSAnimationLinear
};
typedef NSUInteger NSAnimationCurve;

enum {
    NSAnimationBlocking,
    NSAnimationNonblocking,
    NSAnimationNonblockingThreaded
};
typedef NSUInteger NSAnimationBlockingMode;

typedef float NSAnimationProgress;



/* Pre-defined return values for runModalFor: and runModalSession:. The system also reserves all values below these. */
enum {
    NSRunStoppedResponse			= (-1000),
    NSRunAbortedResponse			= (-1001),
    NSRunContinuesResponse		= (-1002)
};

/* used with NSRunLoop's performSelector:target:argument:order:modes: */
enum {
    NSUpdateWindowsRunLoopOrdering		= 500000
};

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
/* Flags that comprise an application's presentationOptions */
enum {
    NSApplicationPresentationDefault                    = 0,
    NSApplicationPresentationAutoHideDock               = (1 <<  0),    // Dock appears when moused to
    NSApplicationPresentationHideDock                   = (1 <<  1),    // Dock is entirely unavailable

    NSApplicationPresentationAutoHideMenuBar            = (1 <<  2),    // Menu Bar appears when moused to
    NSApplicationPresentationHideMenuBar                = (1 <<  3),    // Menu Bar is entirely unavailable

    NSApplicationPresentationDisableAppleMenu           = (1 <<  4),    // all Apple menu items are disabled
    NSApplicationPresentationDisableProcessSwitching    = (1 <<  5),    // Cmd+Tab UI is disabled
    NSApplicationPresentationDisableForceQuit           = (1 <<  6),    // Cmd+Opt+Esc panel is disabled
    NSApplicationPresentationDisableSessionTermination  = (1 <<  7),    // PowerKey panel and Restart/Shut Down/Log Out disabled
    NSApplicationPresentationDisableHideApplication     = (1 <<  8),    // Application "Hide" menu item is disabled
    NSApplicationPresentationDisableMenuBarTransparency = (1 <<  9)     // Menu Bar's transparent appearance is disabled
};
#endif
typedef NSUInteger NSApplicationPresentationOptions;


enum {
    NSUnderlineStyleNone                = 0x00,
    NSUnderlineStyleSingle              = 0x01,
    NSUnderlineStyleThick               = 0x02,
    NSUnderlineStyleDouble              = 0x09
};

enum {
    NSUnderlinePatternSolid             = 0x0000,
    NSUnderlinePatternDot               = 0x0100,
    NSUnderlinePatternDash              = 0x0200,
    NSUnderlinePatternDashDot           = 0x0300,
    NSUnderlinePatternDashDotDot        = 0x0400
};

APPKIT_EXTERN NSUInteger NSUnderlineByWordMask; 

/* NSSpellingStateAttributeName is used and recognized only as a temporary attribute (see NSLayoutManager.h).  It indicates that spelling and/or grammar indicators should be shown for the specified characters.
*/
APPKIT_EXTERN NSString *NSSpellingStateAttributeName    AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER;  // int, default 0: no spelling or grammar indicator

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
/* Flag values supported for NSSpellingStateAttributeName as of Mac OS X version 10.5.  Prior to 10.5, any non-zero value caused the spelling indicator to be shown.
*/
enum {
    NSSpellingStateSpellingFlag = (1 << 0),
    NSSpellingStateGrammarFlag  = (1 << 1)
};
#endif /* MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 */


enum {
    NSButtLineCapStyle = 0,
    NSRoundLineCapStyle = 1,
    NSSquareLineCapStyle = 2
};
typedef NSUInteger NSLineCapStyle;

enum {
    NSMiterLineJoinStyle = 0,
    NSRoundLineJoinStyle = 1,
    NSBevelLineJoinStyle = 2
};
typedef NSUInteger NSLineJoinStyle;

enum {
    NSNonZeroWindingRule = 0,
    NSEvenOddWindingRule = 1
};
typedef NSUInteger NSWindingRule;

enum {
    NSMoveToBezierPathElement,
    NSLineToBezierPathElement,
    NSCurveToBezierPathElement,
    NSClosePathBezierPathElement
};
typedef NSUInteger NSBezierPathElement;


enum {
    NSTIFFCompressionNone		= 1,
    NSTIFFCompressionCCITTFAX3		= 3,		/* 1 bps only */
    NSTIFFCompressionCCITTFAX4		= 4,		/* 1 bps only */
    NSTIFFCompressionLZW		= 5,
    NSTIFFCompressionJPEG		= 6,		/* No longer supported for input or output */
    NSTIFFCompressionNEXT		= 32766,	/* Input only */
    NSTIFFCompressionPackBits		= 32773,
    NSTIFFCompressionOldJPEG		= 32865		/* No longer supported for input or output */
};
typedef NSUInteger NSTIFFCompression;

enum {
    NSTIFFFileType,
    NSBMPFileType,
    NSGIFFileType,
    NSJPEGFileType,
    NSPNGFileType,
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
    NSJPEG2000FileType
#endif
};
typedef NSUInteger NSBitmapImageFileType;

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_2
enum {
    NSImageRepLoadStatusUnknownType     = -1, // not enough data to determine image format. please feed me more data
    NSImageRepLoadStatusReadingHeader   = -2, // image format known, reading header. not yet valid. more data needed
    NSImageRepLoadStatusWillNeedAllData = -3, // can't read incrementally. will wait for complete data to become avail.
    NSImageRepLoadStatusInvalidData     = -4, // image decompression encountered error.
    NSImageRepLoadStatusUnexpectedEOF   = -5, // ran out of data before full image was decompressed.
    NSImageRepLoadStatusCompleted       = -6  // all is well, the full pixelsHigh image is valid.
};
typedef NSInteger NSImageRepLoadStatus;
#endif

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
enum {
    NSAlphaFirstBitmapFormat            = 1 << 0,       // 0 means is alpha last (RGBA, CMYKA, etc.)
    NSAlphaNonpremultipliedBitmapFormat = 1 << 1,       // 0 means is premultiplied
    NSFloatingPointSamplesBitmapFormat  = 1 << 2	// 0 is integer
};
typedef NSUInteger NSBitmapFormat;
#endif


enum {
    NSNoTitle				= 0,
    NSAboveTop				= 1,
    NSAtTop				= 2,
    NSBelowTop				= 3,
    NSAboveBottom			= 4,
    NSAtBottom				= 5,
    NSBelowBottom			= 6
};
typedef NSUInteger NSTitlePosition;

enum {
    NSBoxPrimary	= 0,	// group subviews with a standard look. default
    NSBoxSecondary	= 1,    // same as primary since 10.3
    NSBoxSeparator	= 2,    // vertical or horizontal separtor line.  Not used with subviews.
    NSBoxOldStyle	= 3,    // 10.2 and earlier style boxes
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
    NSBoxCustom		= 4     // draw based entirely on user parameters, not human interface guidelines
#endif
};
typedef NSUInteger NSBoxType;


enum {
/* Column sizes are fixed and set by developer.     
 */
    NSBrowserNoColumnResizing = 0,
    
/* No user resizing. Columns grow as window grows.  
 */
    NSBrowserAutoColumnResizing = 1,
    
/* Columns fixed as window grows.  User can resize. 
 */
    NSBrowserUserColumnResizing = 2,
};

#endif

typedef NSUInteger NSBrowserColumnResizingType;

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5

/* In drag and drop, used to specify the drop operation from inside the delegate method browser:validateDrop:proposedRow:column:dropOperation. See the delegate method description for more information.
 */
enum { 
    NSBrowserDropOn, 
    NSBrowserDropAbove,
};

#endif

typedef NSUInteger NSBrowserDropOperation;


enum {
    NSMomentaryLightButton		= 0,	// was NSMomentaryPushButton
    NSPushOnPushOffButton		= 1,
    NSToggleButton			= 2,
    NSSwitchButton			= 3,
    NSRadioButton			= 4,
    NSMomentaryChangeButton		= 5,
    NSOnOffButton			= 6,
    NSMomentaryPushInButton		= 7,	// was NSMomentaryLight

    /* These constants were accidentally reversed so that NSMomentaryPushButton lit and
       NSMomentaryLight pushed. These names are now deprecated */
    
    NSMomentaryPushButton		= 0,
    NSMomentaryLight			= 7
    
};
typedef NSUInteger NSButtonType;

enum {

    NSRoundedBezelStyle          = 1,
    NSRegularSquareBezelStyle    = 2,
    NSThickSquareBezelStyle      = 3,
    NSThickerSquareBezelStyle    = 4,
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_3
    NSDisclosureBezelStyle       = 5,
#endif
    NSShadowlessSquareBezelStyle = 6,
    NSCircularBezelStyle         = 7,
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_3
    NSTexturedSquareBezelStyle   = 8,
    NSHelpButtonBezelStyle       = 9,
#endif
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
    NSSmallSquareBezelStyle       = 10,
    NSTexturedRoundedBezelStyle   = 11,
    NSRoundRectBezelStyle         = 12,
    NSRecessedBezelStyle          = 13,
    NSRoundedDisclosureBezelStyle = 14,
#endif

    // this will be obsolete before GM

    NSSmallIconButtonBezelStyle  = 2
    
};
typedef NSUInteger NSBezelStyle;


enum {
    NSGradientNone          = 0,
    NSGradientConcaveWeak   = 1,
    NSGradientConcaveStrong = 2,
    NSGradientConvexWeak    = 3,
    NSGradientConvexStrong  = 4
};
typedef NSUInteger NSGradientType;



enum {
    NSAnyType				= 0,
    NSIntType				= 1,
    NSPositiveIntType			= 2,
    NSFloatType				= 3,
    NSPositiveFloatType			= 4,
    NSDoubleType			= 6,
    NSPositiveDoubleType		= 7
};

enum {
    NSNullCellType			= 0,
    NSTextCellType			= 1,
    NSImageCellType			= 2
};
typedef NSUInteger NSCellType;

enum {
    NSCellDisabled			= 0,
    NSCellState				= 1,
    NSPushInCell			= 2,
    NSCellEditable			= 3,
    NSChangeGrayCell			= 4,
    NSCellHighlighted			= 5,
    NSCellLightsByContents		= 6,
    NSCellLightsByGray			= 7,
    NSChangeBackgroundCell		= 8,
    NSCellLightsByBackground		= 9,
    NSCellIsBordered			= 10,
    NSCellHasOverlappingImage		= 11,
    NSCellHasImageHorizontal		= 12,
    NSCellHasImageOnLeftOrBottom	= 13,
    NSCellChangesContents		= 14,
    NSCellIsInsetButton			= 15,
    NSCellAllowsMixedState		= 16
};
typedef NSUInteger NSCellAttribute;

enum {
    NSNoImage				= 0,
    NSImageOnly				= 1,
    NSImageLeft				= 2,
    NSImageRight			= 3,
    NSImageBelow			= 4,
    NSImageAbove			= 5,
    NSImageOverlaps			= 6
};
typedef NSUInteger NSCellImagePosition;

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
enum {
    NSImageScaleProportionallyDown = 0, // Scale image down if it is too large for destination. Preserve aspect ratio.
    NSImageScaleAxesIndependently,      // Scale each dimension to exactly fit destination. Do not preserve aspect ratio.
    NSImageScaleNone,                   // Do not scale.
    NSImageScaleProportionallyUpOrDown  // Scale image to maximum possible dimensions while (1) staying within destination area (2) preserving aspect ratio
};
#endif
typedef NSUInteger NSImageScaling;

enum {
    NSMixedState = -1,
    NSOffState   =  0,
    NSOnState    =  1    
};
typedef NSInteger NSCellStateValue;

/* ButtonCell highlightsBy and showsStateBy mask */

enum {
    NSNoCellMask			= 0,
    NSContentsCellMask			= 1,
    NSPushInCellMask			= 2,
    NSChangeGrayCellMask		= 4,
    NSChangeBackgroundCellMask		= 8
};

enum {
    NSDefaultControlTint  = 0,	// system 'default'
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_3
    NSBlueControlTint     = 1,
    NSGraphiteControlTint = 6,
#endif
    NSClearControlTint    = 7
};
typedef NSUInteger NSControlTint;

enum {
    NSRegularControlSize,
    NSSmallControlSize
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_3
    , NSMiniControlSize
#endif
};
typedef NSUInteger NSControlSize;


enum {
    NSBackgroundStyleLight = 0,	// The background is a light color. Dark content contrasts well with this background.
    NSBackgroundStyleDark,	// The background is a dark color. Light content contrasts well with this background.
    NSBackgroundStyleRaised,	// The background is intended to appear higher than the content drawn on it. Content might need to be inset.
    NSBackgroundStyleLowered	// The background is intended to appear lower than the content drawn on it. Content might need to be embossed.
};
typedef NSInteger NSBackgroundStyle;


enum {
    NSCollectionViewDropOn = 0,
    NSCollectionViewDropBefore = 1,
};



typedef NSInteger NSColorPanelMode;

enum {
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
    /* If the color panel is not displaying a mode, the NSNoModeColorPanel will be returned */
    NSNoModeColorPanel                  = -1,
#endif
    NSGrayModeColorPanel		= 0,
    NSRGBModeColorPanel			= 1,
    NSCMYKModeColorPanel		= 2,
    NSHSBModeColorPanel			= 3,
    NSCustomPaletteModeColorPanel	= 4,
    NSColorListModeColorPanel		= 5,
    NSWheelModeColorPanel		= 6,
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_2
    NSCrayonModeColorPanel		= 7
#endif
};

enum {
    NSColorPanelGrayModeMask		= 0x00000001,
    NSColorPanelRGBModeMask		= 0x00000002,
    NSColorPanelCMYKModeMask		= 0x00000004,
    NSColorPanelHSBModeMask		= 0x00000008,
    NSColorPanelCustomPaletteModeMask	= 0x00000010,
    NSColorPanelColorListModeMask	= 0x00000020,
    NSColorPanelWheelModeMask		= 0x00000040,
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_2
    NSColorPanelCrayonModeMask		= 0x00000080,
#endif
    NSColorPanelAllModesMask		= 0x0000ffff
};
    
    
enum {
    NSUnknownColorSpaceModel = -1,
    NSGrayColorSpaceModel,
    NSRGBColorSpaceModel,
    NSCMYKColorSpaceModel,
    NSLABColorSpaceModel,
    NSDeviceNColorSpaceModel,
    NSIndexedColorSpaceModel,
    NSPatternColorSpaceModel
};
typedef NSInteger NSColorSpaceModel;



enum {
    NSTextFieldAndStepperDatePickerStyle    = 0,
    NSClockAndCalendarDatePickerStyle       = 1,
    NSTextFieldDatePickerStyle              = 2
};
typedef NSUInteger NSDatePickerStyle;

enum {
    NSSingleDateMode = 0,
    NSRangeDateMode = 1
};
typedef NSUInteger NSDatePickerMode;

typedef NSUInteger NSDatePickerElementFlags;
enum {
    /* Time Elements */
    NSHourMinuteDatePickerElementFlag       = 0x000c,
    NSHourMinuteSecondDatePickerElementFlag = 0x000e,
    NSTimeZoneDatePickerElementFlag	    = 0x0010,

    /* Date Elements */
    NSYearMonthDatePickerElementFlag	    = 0x00c0,
    NSYearMonthDayDatePickerElementFlag	    = 0x00e0,
    NSEraDatePickerElementFlag		    = 0x0100,
};




enum {

    NSChangeDone = 0,
    NSChangeUndone = 1,
    NSChangeCleared = 2,

    NSChangeRedone = 5,

    NSChangeReadOtherContents = 3,
    NSChangeAutosaved = 4

};
typedef NSUInteger NSDocumentChangeType;

enum {

    NSSaveOperation = 0,

    NSSaveAsOperation = 1,

    NSSaveToOperation = 2,

    NSAutosaveOperation = 3
    
};
typedef NSUInteger NSSaveOperationType;


typedef NSUInteger NSDragOperation;

enum {
    NSDragOperationNone		= 0,
    NSDragOperationCopy		= 1,
    NSDragOperationLink		= 2,
    NSDragOperationGeneric	= 4,
    NSDragOperationPrivate	= 8,
    NSDragOperationAll_Obsolete	= 15,
    NSDragOperationMove		= 16,
    NSDragOperationDelete	= 32,
    NSDragOperationEvery	= NSUIntegerMax
};







enum {
    NSDrawerClosedState			= 0,
    NSDrawerOpeningState 		= 1,
    NSDrawerOpenState 			= 2,
    NSDrawerClosingState 		= 3
};
typedef NSUInteger NSDrawerState;



enum {        /* various types of events */
    NSLeftMouseDown             = 1,            
    NSLeftMouseUp               = 2,
    NSRightMouseDown            = 3,
    NSRightMouseUp              = 4,
    NSMouseMoved                = 5,
    NSLeftMouseDragged          = 6,
    NSRightMouseDragged         = 7,
    NSMouseEntered              = 8,
    NSMouseExited               = 9,
    NSKeyDown                   = 10,
    NSKeyUp                     = 11,
    NSFlagsChanged              = 12,
    NSAppKitDefined             = 13,
    NSSystemDefined             = 14,
    NSApplicationDefined        = 15,
    NSPeriodic                  = 16,
    NSCursorUpdate              = 17,
    NSScrollWheel               = 22,
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
    NSTabletPoint               = 23,
    NSTabletProximity           = 24,
#endif
    NSOtherMouseDown            = 25,
    NSOtherMouseUp              = 26,
    NSOtherMouseDragged         = 27,
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
    /* The following event types are available on some hardware on 10.5.2 and later */
    NSEventTypeGesture          = 29,
    NSEventTypeMagnify          = 30,
    NSEventTypeSwipe            = 31,
    NSEventTypeRotate           = 18,
    NSEventTypeBeginGesture     = 19,
    NSEventTypeEndGesture       = 20
#endif
};
typedef NSUInteger NSEventType;

// For APIs introduced in Mac OS X 10.6 and later, this type is used with NS*Mask constants to indicate the events of interest.
typedef unsigned long long NSEventMask;

enum {                    /* masks for the types of events */
    NSLeftMouseDownMask         = 1 << NSLeftMouseDown,
    NSLeftMouseUpMask           = 1 << NSLeftMouseUp,
    NSRightMouseDownMask        = 1 << NSRightMouseDown,
    NSRightMouseUpMask          = 1 << NSRightMouseUp,
    NSMouseMovedMask            = 1 << NSMouseMoved,
    NSLeftMouseDraggedMask      = 1 << NSLeftMouseDragged,
    NSRightMouseDraggedMask     = 1 << NSRightMouseDragged,
    NSMouseEnteredMask          = 1 << NSMouseEntered,
    NSMouseExitedMask           = 1 << NSMouseExited,
    NSKeyDownMask               = 1 << NSKeyDown,
    NSKeyUpMask                 = 1 << NSKeyUp,
    NSFlagsChangedMask          = 1 << NSFlagsChanged,
    NSAppKitDefinedMask         = 1 << NSAppKitDefined,
    NSSystemDefinedMask         = 1 << NSSystemDefined,
    NSApplicationDefinedMask    = 1 << NSApplicationDefined,
    NSPeriodicMask              = 1 << NSPeriodic,
    NSCursorUpdateMask          = 1 << NSCursorUpdate,
    NSScrollWheelMask           = 1 << NSScrollWheel,
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
    NSTabletPointMask           = 1 << NSTabletPoint,
    NSTabletProximityMask       = 1 << NSTabletProximity,
#endif
    NSOtherMouseDownMask        = 1 << NSOtherMouseDown,
    NSOtherMouseUpMask          = 1 << NSOtherMouseUp,
    NSOtherMouseDraggedMask     = 1 << NSOtherMouseDragged,
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
    /* The following event masks are available on some hardware on 10.5.2 and later */
    NSEventMaskGesture          = 1 << NSEventTypeGesture,
    NSEventMaskMagnify          = 1 << NSEventTypeMagnify,
    NSEventMaskSwipe            = 1U << NSEventTypeSwipe,
    NSEventMaskRotate           = 1 << NSEventTypeRotate,
    NSEventMaskBeginGesture     = 1 << NSEventTypeBeginGesture,
    NSEventMaskEndGesture       = 1 << NSEventTypeEndGesture,
#endif
    NSAnyEventMask              = NSUIntegerMax
};

NS_INLINE NSUInteger NSEventMaskFromType(NSEventType type) { return (1 << type); }

/* Device-independent bits found in event modifier flags */
enum {
    NSAlphaShiftKeyMask         = 1 << 16,
    NSShiftKeyMask              = 1 << 17,
    NSControlKeyMask            = 1 << 18,
    NSAlternateKeyMask          = 1 << 19,
    NSCommandKeyMask            = 1 << 20,
    NSNumericPadKeyMask         = 1 << 21,
    NSHelpKeyMask               = 1 << 22,
    NSFunctionKeyMask           = 1 << 23,
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
    NSDeviceIndependentModifierFlagsMask    = 0xffff0000UL
#endif
};

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
/* pointer types for NSTabletProximity events or mouse events with subtype NSTabletProximityEventSubtype*/
enum {        
    NSUnknownPointingDevice     = NX_TABLET_POINTER_UNKNOWN,
    NSPenPointingDevice         = NX_TABLET_POINTER_PEN,
    NSCursorPointingDevice      = NX_TABLET_POINTER_CURSOR,
    NSEraserPointingDevice      = NX_TABLET_POINTER_ERASER
};
typedef NSUInteger NSPointingDeviceType;

/* button masks for NSTabletPoint events or mouse events with subtype NSTabletPointEventSubtype */
enum {
    NSPenTipMask                = NX_TABLET_BUTTON_PENTIPMASK,
    NSPenLowerSideMask          = NX_TABLET_BUTTON_PENLOWERSIDEMASK,
    NSPenUpperSideMask          = NX_TABLET_BUTTON_PENUPPERSIDEMASK
};
#endif
























//////////////////////////
////// FOUNDATION




//  NSNotificationQueue
enum {
    NSPostWhenIdle = 1,
    NSPostASAP = 2,
    NSPostNow = 3
};
typedef NSUInteger NSPostingStyle;

enum {
    NSNotificationNoCoalescing = 0,
    NSNotificationCoalescingOnName = 1,
    NSNotificationCoalescingOnSender = 2
};
typedef NSUInteger NSNotificationCoalescing;




// NSComparisonPredicate
enum {
    NSCaseInsensitivePredicateOption = 0x01,
    NSDiacriticInsensitivePredicateOption = 0x02,
};

// Describes how the operator is modified: can be direct, ALL, or ANY
enum {
    NSDirectPredicateModifier = 0, // Do a direct comparison
    NSAllPredicateModifier, // ALL toMany.x = y
    NSAnyPredicateModifier // ANY toMany.x = y
};
typedef NSUInteger NSComparisonPredicateModifier;


// Type basic set of operators defined. Most are obvious; NSCustomSelectorPredicateOperatorType allows a developer to create an operator which uses the custom selector specified in the constructor to do the evaluation.
enum {
    NSLessThanPredicateOperatorType = 0, // compare: returns NSOrderedAscending
    NSLessThanOrEqualToPredicateOperatorType, // compare: returns NSOrderedAscending || NSOrderedSame
    NSGreaterThanPredicateOperatorType, // compare: returns NSOrderedDescending
    NSGreaterThanOrEqualToPredicateOperatorType, // compare: returns NSOrderedDescending || NSOrderedSame
    NSEqualToPredicateOperatorType, // isEqual: returns true
    NSNotEqualToPredicateOperatorType, // isEqual: returns false
    NSMatchesPredicateOperatorType,
    NSLikePredicateOperatorType,
    NSBeginsWithPredicateOperatorType,
    NSEndsWithPredicateOperatorType,
    NSInPredicateOperatorType, // rhs contains lhs returns true
    NSCustomSelectorPredicateOperatorType
#if MAC_OS_X_VERSION_10_5 <= MAC_OS_X_VERSION_MAX_ALLOWED
    ,
    NSContainsPredicateOperatorType = 99, // lhs contains rhs returns true
    NSBetweenPredicateOperatorType
#endif /* MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 */
};
typedef NSUInteger NSPredicateOperatorType;


// NSPointerFunctions

enum {
    // Memory options are mutually exclusive
    
    // default is strong
    NSPointerFunctionsStrongMemory = (0UL << 0),       // use strong write-barrier to backing store; use GC memory on copyIn
    NSPointerFunctionsZeroingWeakMemory = (1UL << 0),  // use weak read and write barriers; use GC memory on copyIn 
    NSPointerFunctionsOpaqueMemory = (2UL << 0),
    NSPointerFunctionsMallocMemory = (3UL << 0),       // free() will be called on removal, calloc on copyIn
    NSPointerFunctionsMachVirtualMemory = (4UL << 0),
    
    // Personalities are mutually exclusive
    // default is object.  As a special case, 'strong' memory used for Objects will do retain/release under non-GC
    NSPointerFunctionsObjectPersonality = (0UL << 8),         // use -hash and -isEqual, object description
    NSPointerFunctionsOpaquePersonality = (1UL << 8),         // use shifted pointer hash and direct equality
    NSPointerFunctionsObjectPointerPersonality = (2UL << 8),  // use shifted pointer hash and direct equality, object description
    NSPointerFunctionsCStringPersonality = (3UL << 8),        // use a string hash and strcmp, description assumes UTF-8 contents; recommended for UTF-8 (or ASCII, which is a subset) only cstrings
    NSPointerFunctionsStructPersonality = (4UL << 8),         // use a memory hash and memcmp (using size function you must set)
    NSPointerFunctionsIntegerPersonality = (5UL << 8),        // use unshifted value as hash & equality

    NSPointerFunctionsCopyIn = (1UL << 16),      // the memory acquire function will be asked to allocate and copy items on input
};

typedef NSUInteger NSPointerFunctionsOptions;































