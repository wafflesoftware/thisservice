//
//  TSServiceTestWindowController.m
//  ThisService
//
//  Created by Jesper on 2012-07-05.
//  Copyright 2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//
//

#import "TSServiceTestWindowController.h"

#import "TSService.h"

#import "WFMachTime.h"

@interface TSServiceTestWindowController ()

@end

@implementation TSServiceTestWindowController
@synthesize logTextView = _logTextView;
@synthesize durationLabel = _durationLabel;
@synthesize noInputBox = _noInputBox;
@synthesize noOutputBox = _noOutputBox;
@synthesize inputLabel = _inputLabel;
@synthesize inputInstructionsLabel = _inputInstructionsLabel;
@synthesize outputLabel = _outputLabel;
@synthesize statusLabel = _statusLabel;
@synthesize statusIndicator = _statusIndicator;
@synthesize outputDirtyLabel = _outputDirtyLabel;
@synthesize testServiceHeadlineLabel = _testServiceHeadlineLabel;
@synthesize inputTextView = _inputTextView;
@synthesize outputTextView = _outputTextView;
@synthesize inputTextScrollView = _inputTextScrollView;
@synthesize outputTextScrollView = _outputTextScrollView;
@synthesize createServiceButton = _createServiceButton;
@synthesize testServiceButton = _testServiceButton;
@synthesize doomed = doomed;
@synthesize delegate = _delegate;

@synthesize previousRunTime = _previousRunTime;
@synthesize ongoingTimer = _ongoingTimer;

-(TSServiceTestWindowController *)initWithTester:(TSServiceTester *)tester
{
    self = [super initWithWindowNibName:@"TSServiceTestWindowController"];
    if (self) {
        _tester = [tester retain];
        [_tester setDelegate:self];
    }
    
    return self;
}

- (void)testerLaunchedService:(TSServiceTester *)tester {
    self.statusLabel.stringValue = @"Connecting to service…";
}

- (void)updateCreateServiceButton:(BOOL)e {
    [self.createServiceButton setEnabled:_pairingCompleted && e];
}

-(void)testerPairedWithService:(TSServiceTester *)tester {
    self.statusLabel.stringValue = @"";
    [self.statusIndicator stopAnimation:nil];
    
    [self setTestingEnabled:YES];
    _pairingCompleted = YES;
    [self updateCreateServiceButton:YES];
}

- (void)textDidChange:(NSNotification *)notification {
    [self.outputDirtyLabel setHidden:(self.previousRunTime == nil)];
}

-(void)testerWillInvokeService:(TSServiceTester *)tester withPasteboard:(NSPasteboard *)pasteboard {
    if (supportsInput) {
        [pasteboard setString:self.inputTextView.string forType:NSStringPboardType];
    }
}

- (void)tester:(TSServiceTester *)tester failedWithError:(NSString *)error {
    [_tester cancel];
}

- (void)testerBeganRunningService:(TSServiceTester *)tester {
    [self performSelectorOnMainThread:@selector(serializedTesterBeganRunningService:) withObject:tester waitUntilDone:NO];
}

- (void)serializedTesterBeganRunningService:(TSServiceTester *)tester {
    self.statusLabel.stringValue = @"Running service…";
    [self setTestingEnabled:NO];
    [self.statusIndicator startAnimation:nil];
}

static NSDateFormatter *durationFormatter = nil;

- (void)serializedTesterFinishedRunningServiceWithPasteboard:(NSArray *)objects {
    TSServiceTester *tester = [objects objectAtIndex:0];
    NSPasteboard *pasteboard = [objects objectAtIndex:1];

    self.statusLabel.stringValue = @"";
    [self.statusIndicator stopAnimation:nil];
    if (supportsOutput) {
        NSString *outputString = [pasteboard stringForType:NSStringPboardType];
        if (!outputString) {
            outputString = @"– No string returned from AppleScript service! Use the \"return\" statement to produce output. –";
        }
        
        [self.outputTextView setString:outputString];
        [self.outputDirtyLabel setHidden:YES];
    }
    NSTimeInterval duration = [self.ongoingTimer intervalSinceStart];
    self.previousRunTime = [NSNumber numberWithDouble:duration];
    
    NSTimeInterval effectiveTimeout = [tester.service effectiveTimeout];
    NSString *durationReading = [durationFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:duration]];
    NSString *durationText = nil;
    NSColor *textColor = [NSColor disabledControlTextColor];
    if (duration >= effectiveTimeout) {
        NSString *timeoutReading = [durationFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:effectiveTimeout]];
        durationText = [NSString stringWithFormat:@"Service ran for longer than %@ timeout! %@.", timeoutReading, durationReading];
        textColor = [NSColor colorWithDeviceRed:0.8 green:0 blue:0 alpha:1];
    } else if (duration >= (effectiveTimeout * 0.9)) {
        NSString *timeoutReading = [durationFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:effectiveTimeout]];
        durationText = [NSString stringWithFormat:@"Service ran close to the %@ timeout! %@.", timeoutReading, durationReading];
        textColor = [NSColor colorWithDeviceRed:0.5 green:0.3 blue:0.3 alpha:1];
    } else {
        durationText = [NSString stringWithFormat:@"Service ran in %@.", durationReading];
    }
    
    self.durationLabel.textColor = textColor;
    self.durationLabel.stringValue = durationText;
    
    [self setTestingEnabled:YES];
    [self updateCreateServiceButton:YES];
}

- (void)testerFinishedRunningService:(TSServiceTester *)tester withPasteboard:(NSPasteboard *)pasteboard {
    [self performSelectorOnMainThread:@selector(serializedTesterFinishedRunningServiceWithPasteboard:) withObject:[NSArray arrayWithObjects:tester, pasteboard, nil] waitUntilDone:NO];
}

- (void)setTestingEnabled:(BOOL)enabled {
    [self.inputTextView setEditable:enabled];
    [self.testServiceButton setEnabled:enabled];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    if (!durationFormatter) {
        durationFormatter = [[NSDateFormatter alloc] init];
        [durationFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [durationFormatter setDateFormat:@"HH:mm:ss.SSS"];
        [durationFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    }

    if (![_tester startConnection]) {
        self.doomed = YES;
        [_delegate testing:self failedFatally:nil];
        return;
    }
    
    TSService *service = _tester.service;
    
    supportsInput = service.supportsInput;
    supportsOutput = service.supportsOutput;
    
    if (!supportsInput) {
        [self.inputLabel setHidden:YES];
        [self.inputTextScrollView setHidden:YES];
        [self.inputInstructionsLabel setHidden:YES];
    } else {
        [self.noInputBox setHidden:YES];
    }
    
    if (!supportsOutput) {
        [self.outputLabel setHidden:YES];
        [self.outputDirtyLabel setHidden:YES];
        [self.outputTextScrollView setHidden:YES];
    } else {
        [self.noOutputBox setHidden:YES];
    }
    
    [self setTestingEnabled:NO];
    
    self.durationLabel.stringValue = @"";
    
    self.testServiceHeadlineLabel.stringValue = [NSString stringWithFormat:@"Test %@", _tester.service.serviceName];
    
    [self.statusIndicator startAnimation:nil];
    self.statusLabel.stringValue = @"Launching service…";

}

- (IBAction)doTestService:(id)sender {
    [self.outputDirtyLabel setHidden:YES];
    
    self.ongoingTimer = [WFMachTime currentTime];
    [self updateCreateServiceButton:NO];
    
    BOOL retry = NO;
    do {
        if (![_tester startTesting]) {
            NSAlert *alert = [[NSAlert alertWithMessageText:@"The service script could not be updated." defaultButton:@"Try Again" alternateButton:@"Stop Testing" otherButton:nil informativeTextWithFormat:@"Before testing the service, ThisService updates the service script from its original location at %@. No such script exists at this location so the service can't be updated with the latest version.\n\nTo continue testing the service, restore the service script to this location and click Try Again.", [[_tester service] pathToScriptOutsideService]] retain];
            retry = NO;
            NSInteger returnCode = [alert runModal];
            [alert release];
            if (returnCode == NSAlertDefaultReturn) {
                retry = YES;
            } else {
                [self cancel:sender];
            }
        }
    } while (retry);
}

- (IBAction)help:(id)sender {
    	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"testhelp" inBook:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"]];
}

- (IBAction)cancel:(id)sender {
    [_tester cancel];
    [_delegate testingCancelled:self];
}

- (IBAction)createService:(id)sender {
    [_tester cancel];
    [_delegate testingDone:self];
}

- (void)dealloc
{
    [_previousRunTime release];
    [_ongoingTimer release];
    [_tester release];
    [super dealloc];
}

@end
