//
//  WFFilePicker.h
//
//  Created by Jesper on 2006-04-13.
//  Copyright 2006-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@class WFFilePickerIconView, WFFilePickerLabelView;

@interface WFFilePicker : NSView {
	NSButton *chooseButton;
	NSButton *emptyButton;
	WFFilePickerIconView *iconView;
	WFFilePickerLabelView *nameView;
	
	NSURL *representedURL;
	FSRef representedFSRef;
	
	NSImage *currentFileIcon;
	
	BOOL isDropping;
	
	BOOL enabled;
	
	BOOL showsEmptyButton;
	
//	BOOL allowsMultipleSelection;
	BOOL canChooseDirectories;
	BOOL canChooseFiles;
	BOOL resolvesAliases;
	NSArray *allowedFileTypes;
	
	id filePathObserver;
	NSString *filePathObserverKeyPath;
	NSValueTransformer *filePathVT;
	
	id enabledObserver;
	NSString *enabledObserverKeyPath;
	NSValueTransformer *enabledVT;
	
	IBOutlet id delegate;
	
}
- (void)setRepresentedURL:(NSURL *)u;
- (NSURL *)representedURL;

- (void)setFilePath:(NSString *)s;
- (NSString *)filePath;

- (void)setRepresentedFSRef:(FSRef)r;
- (FSRef)representedFSRef;

- (BOOL)isEmpty;
- (void)setEmpty;

- (BOOL)showsEmptyButton;
- (void)setShowsEmptyButton:(BOOL)set;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)en;
- (void)setEnabledWithoutKVO:(BOOL)en;

- (IBAction)beginChooseSheet:(id)sender;

- (id)delegate;
- (void)setDelegate:(id)del;

- (BOOL)resolvesAliases;
- (void)setResolvesAliases:(BOOL)flag;
- (BOOL)canChooseDirectories;
- (void)setCanChooseDirectories:(BOOL)flag;
- (BOOL)canChooseFiles;
- (void)setCanChooseFiles:(BOOL)flag;
- (NSArray *)allowedFileTypes;
- (void)setAllowedFileTypes:(NSArray *)types;
@end

@interface NSObject (WFFilePickerDelegateMethods)
- (NSOpenPanel *)filePicker:(WFFilePicker *)aFilePicker willShowOpenPanel:(NSOpenPanel *)openPanel;
- (void)filePicker:(WFFilePicker *)aFilePicker openPanelDismissedWithReturnCode:(int)returnCode;
- (BOOL)filePicker:(WFFilePicker *)aFilePicker validateURL:(NSURL *)url error:(NSError **)anError;
@end
