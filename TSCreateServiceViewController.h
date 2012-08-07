//
//  TSCreateServiceViewController.h
//  ThisService
//
//  Created by Jesper on 2006-10-28.
//  Copyright 2006-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import <Cocoa/Cocoa.h>

@class WFFilePicker, SRRecorderControl, TSModeMatrix;
#import "TSViewController.h"
#import "TSCheckedListDataSource.h"
#import "TSServiceInputRulesWindowController.h"
#import "TSServiceAppFilterWindowController.h"
#import "TSServiceTestWindowController.h"

@class TSServiceInputRules, TSStubbornImageView, TSServiceAppFilter;

#import "TSService.h"

#import "TSStubbornImageView.h"

#import "TSExtraCollectionView.h"

@interface TSCreateServiceViewController : TSViewController <TSServiceInputRulesWindowControllerDelegate, TSStubbornImageViewDelegate, TSServiceAppFilterWindowControllerDelegate, TSServiceTestWindowControllerDelegate, NSCollectionViewDelegate> {
	
	IBOutlet WFFilePicker *filePicker;
	IBOutlet TSStubbornImageView *iconView;
	IBOutlet NSTextField *iconLabel;
	IBOutlet NSView *iconDropZone;
	
    IBOutlet NSTextField *appFilterStatusLabel;
	
//	TSServiceType serviceType;
    BOOL takesInput;
    BOOL producesOutput;
	NSString *serviceName;
	TSServiceScriptReferenceType referenceType;

    NSString *pathToUpcomingService;
    TSService *upcomingService;
    
    NSSize baseSize;
    CGFloat extraIncrement;
	
    NSString *pathToLatestService;
	NSDictionary *serviceBeingCreated;
	
	BOOL showsAdvancedOptions;
	float advancedOptionsHeight;
	BOOL animationBlocks;
	 
	TSServiceInputRulesWindowController *inputRulesWindowController;
	TSServiceInputRules *inputRules;
    
    TSServiceAppFilterWindowController *appFilterWindowController;
    TSServiceAppFilter *appFilter;
    
    TSServiceTestWindowController *testWindowController;
    
	NSInteger timeoutInSeconds;
	
    IBOutlet NSView *appFilterCollectionItemView;
    IBOutlet NSView *inputRulesCollectionItemView;
    IBOutlet NSView *serviceIconCollectionItemView;
    IBOutlet NSView *referenceServiceCollectionItemView;
    
    IBOutlet NSView *timeoutCollectionItemView;
    
    IBOutlet TSExtraCollectionView *extrasCollectionView;
    IBOutlet NSPopUpButton *extrasDropDown;
    IBOutlet NSScrollView *extrasScrollView;
}
- (IBAction)addAppFilterExtra:(id)sender;
- (IBAction)addInputRulesExtra:(id)sender;
- (IBAction)addServiceIconExtra:(id)sender;
- (IBAction)addReferenceServiceExtra:(id)sender;
- (IBAction)addTimeoutExtra:(id)sender;

@property (retain) NSString *pathToUpcomingService;
@property (retain) TSService *upcomingService;

@property NSInteger timeoutInSeconds;

@property BOOL takesInput;
@property BOOL producesOutput;

- (IBAction)chooseImage:(id)sender;

+ (NSString *)stringByCleansingString:(NSString *)string fromCharactersNotInSet:(NSCharacterSet *)set;
+ (NSString *)cleanseName:(NSString *)name;
+ (NSString *)sanitizeName:(NSString *)name;
+ (NSString *)camelCize:(NSString *)name;

- (IBAction)produceService:(id)sender;

- (IBAction)help:(id)sender;

- (IBAction)specifyInputRules:(id)sender;
- (IBAction)specifyAppFilter:(id)sender;

@end