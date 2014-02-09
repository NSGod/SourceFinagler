//
//  MDInspectorView.h
//  MDInspectorView
//
//  Created by Mark Douma on 8/14/2007.
//  Copyright © 2008 Mark Douma . All rights reserved.
//  

//	This class is based, in part, on code in SNDisclosableView:	http://www.snoize.com

/*
 Copyright (c) 2002, Kurt Revis.  All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of Snoize nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */




#import <Cocoa/Cocoa.h>


@protocol MDInspectorViewDelegate <NSObject>
@optional

/*  Notifications  */
- (void)inspectorViewWillShow:(NSNotification *)notification;
- (void)inspectorViewDidShow:(NSNotification *)notification;

- (void)inspectorViewWillHide:(NSNotification *)notification;
- (void)inspectorViewDidHide:(NSNotification *)notification;

@end

extern NSString * const MDInspectorViewWillShowNotification;
extern NSString * const MDInspectorViewDidShowNotification;

extern NSString * const MDInspectorViewWillHideNotification;
extern NSString * const MDInspectorViewDidHideNotification;



@interface MDInspectorView : NSView <NSCoding> {
	
	IBOutlet NSButton						*titleButton;
	IBOutlet NSButton						*disclosureButton;
	
	IBOutlet id <MDInspectorViewDelegate>	delegate;	// non-retained reference
	
	NSString								*autosaveName;
	
	NSArray									*hiddenSubviews;
	
    NSView									*nonretainedOriginalNextKeyView;
    NSView									*nonretainedLastChildKeyView;
	
	CGFloat									originalHeight;
	CGFloat									hiddenHeight;
	
	NSSize									sizeBeforeHidden;
	
	BOOL									isInitiallyShown;
	
	BOOL									isShown;
	
	BOOL									havePendingWindowHeightChange;
}

- (IBAction)toggleShown:(id)sender;

- (BOOL)isShown;
- (void)setShown:(BOOL)value;


- (NSButton *)titleButton;
- (void)setTitleButton:(NSButton *)value;

- (NSButton *)disclosureButton;
- (void)setDisclosureButton:(NSButton *)value;

- (NSString *)autosaveName;
- (void)setAutosaveName:(NSString *)value;

- (BOOL)isInitiallyShown;
- (void)setInitiallyShown:(BOOL)value;

- (id <MDInspectorViewDelegate>)delegate;
- (void)setDelegate:(id <MDInspectorViewDelegate>)aDelegate;


//- (NSString *)identifier						DEPRECATED_ATTRIBUTE;
//- (void)setIdentifier:(NSString *)anIdentifier	DEPRECATED_ATTRIBUTE;

- (void)changeWindowHeightBy:(CGFloat)value;

@end



