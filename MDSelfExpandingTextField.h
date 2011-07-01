//
//  MDSelfExpandingTextField.h
//  Source Finagler
//
//  Created by Mark Douma on 7/19/2009.
//  Copyright 2009 Mark Douma. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MDInspectorView.h"

//@class MDInspectorView;

@interface MDSelfExpandingTextField : NSTextField <MDInspectorViewDelegate> {
	IBOutlet MDInspectorView *inspectorView;
}

@end
