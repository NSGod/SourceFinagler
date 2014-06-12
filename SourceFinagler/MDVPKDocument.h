//
//  MDVPKDocument.h
//  Source Finagler
//
//  Created by Mark Douma on 9/10/2010.
//  Copyright © 2010-2011 Mark Douma LLC. All rights reserved.
//

#import "MDHLDocument.h"


@class MDVPKViewController;


@interface MDVPKDocument : MDHLDocument {
	MDVPKViewController		*viewController;
	
	NSToolTipTag			statusImageViewTag3;
	
}

@property (nonatomic, retain) MDVPKViewController *viewController;


- (IBAction)openDirectoryFile:(id)sender;


@end

