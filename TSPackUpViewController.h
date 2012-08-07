//
//  TSPackUpViewController.h
//  ThisService
//
//  Created by Jesper on 2007-04-22.
//  Copyright 2007-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import <Cocoa/Cocoa.h>

@class WFFilePicker, TSModeMatrix;

#import "TSViewController.h"

@interface TSPackUpViewController : TSViewController
{
    
    IBOutlet NSView *hasServicesView;
    IBOutlet NSView *noServicesView;
    IBOutlet NSTextField *onlySearchesInLabel;
    
    IBOutlet WFFilePicker *instructionsChoice;
    IBOutlet NSButton *packUpButton;
    IBOutlet NSPopUpButton *serviceChoice;
	IBOutlet TSModeMatrix *modeMatrix;
	
    IBOutlet NSTextField *loadingLabel;
    IBOutlet NSProgressIndicator *loadingIndicator;
	BOOL isRenaming;
	NSString *_rename;
	
	int instructionMode;
	BOOL _isPreflightingInstructionModeChange;
	
	BOOL hasConstructedMenuBefore;
    
    NSInvocationOperation *constructServicesMenuOperation;
    NSOperationQueue *operationQueue;
}
- (IBAction)changeService:(id)sender;
- (IBAction)doPackUp:(id)sender;
- (IBAction)showInstructionTemplate:(id)sender;

- (IBAction)help:(id)sender;

- (IBAction)showPackUp:(id)sender;

- (void)packUp:(NSURL *)path;

- (void)setRenaming:(BOOL)ren;
- (BOOL)renaming;

- (void)setRename:(NSString *)newRename;
- (NSString *)rename;
@end
