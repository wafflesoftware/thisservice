//
//  TSServiceTestWindowController.h
//  ThisService
//
//  Created by Jesper on 2012-07-05.
//  Copyright 2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//
//

#import <Cocoa/Cocoa.h>

@class TSServiceTestWindowController;

#import "TSServiceTester.h"

@class WFMachTime;

@protocol TSServiceTestWindowControllerDelegate <NSObject>
- (void)testingDone:(TSServiceTestWindowController *)testWindowController;
- (void)testing:(TSServiceTestWindowController *)testWindowController failedFatally:(NSError *)error;
- (void)testingCancelled:(TSServiceTestWindowController *)testWindowController;
@end


@interface TSServiceTestWindowController : NSWindowController <TSServiceTesterDelegate, NSTextViewDelegate> {
    TSServiceTester *_tester;
    id<TSServiceTestWindowControllerDelegate> _delegate;
    NSTextField *_statusLabel;
    NSProgressIndicator *_statusIndicator;
    NSTextField *_outputDirtyLabel;
    NSTextField *_testServiceHeadlineLabel;
    NSTextView *_inputTextView;
    NSTextView *_outputTextView;
    NSScrollView *_inputTextScrollView;
    NSScrollView *_outputTextScrollView;
    NSButton *_createServiceButton;
    NSButton *_doTestService;
    NSTextView *_logTextView;
    NSTextField *_durationLabel;
    NSBox *_noInputBox;
    NSBox *_noOutputBox;
    NSTextField *_inputLabel;
    NSTextField *_inputInstructionsLabel;
    NSTextField *_outputLabel;
    NSNumber *_previousRunTime;
    WFMachTime *_ongoingTimer;
    
    BOOL supportsInput;
    BOOL supportsOutput;
    
    BOOL _pairingCompleted;
    
    BOOL doomed;
    NSButton *_testServiceButton;
}
-(TSServiceTestWindowController *)initWithTester:(TSServiceTester *)tester;

@property (assign) id<TSServiceTestWindowControllerDelegate> delegate;

@property (assign) IBOutlet NSTextField *statusLabel;
@property (assign) IBOutlet NSProgressIndicator *statusIndicator;
@property (assign) IBOutlet NSTextField *outputDirtyLabel;
@property (assign) IBOutlet NSTextField *testServiceHeadlineLabel;
@property (assign) IBOutlet NSTextView *inputTextView;
@property (assign) IBOutlet NSTextView *outputTextView;
@property (assign) IBOutlet NSScrollView *inputTextScrollView;
@property (assign) IBOutlet NSScrollView *outputTextScrollView;
@property (assign) IBOutlet NSButton *createServiceButton;

- (IBAction)doTestService:(id)sender;
- (IBAction)help:(id)sender;

@property (assign) IBOutlet NSTextView *logTextView;
@property (assign) IBOutlet NSTextField *durationLabel;

@property (assign) IBOutlet NSBox *noInputBox;
@property (assign) IBOutlet NSBox *noOutputBox;
@property (assign) IBOutlet NSTextField *inputLabel;
@property (assign) IBOutlet NSTextField *inputInstructionsLabel;
@property (assign) IBOutlet NSTextField *outputLabel;

@property (retain) NSNumber *previousRunTime;
@property (retain) WFMachTime *ongoingTimer;

- (IBAction)cancel:(id)sender;
- (IBAction)createService:(id)sender;
@property (assign) IBOutlet NSButton *testServiceButton;

@property BOOL doomed; // failed during initialization
@end