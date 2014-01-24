//
//  MDVPKViewController.h
//  Source Finagler
//
//  Created by Mark Douma on 12/13/2013.
//  Copyright (c) 2013 Mark Douma. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MDVPKDocument;



extern NSString * const MDVPKAlwaysOpenArchiveDirectoryFileKey;



@interface MDVPKViewController : NSViewController {
	
	IBOutlet NSTextField		*messageTextField;
	
	MDVPKDocument				*document;		// non-retained
	
}

@property (nonatomic, assign) MDVPKDocument *document;


- (IBAction)openDirectoryFile:(id)sender;

@end
