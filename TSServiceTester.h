//
//  TSServiceTester.h
//  ThisService
//
//  Created by Jesper on 2012-07-05.
//  Copyright 2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//
//

#import <Cocoa/Cocoa.h>
#import "TSServiceTesting.h"

@class TSServiceTester;
@class TSService;

@protocol TSServiceTesterDelegate <NSObject>
- (void)testerLaunchedService:(TSServiceTester *)tester;
- (void)testerPairedWithService:(TSServiceTester *)tester;
- (void)tester:(TSServiceTester *)tester failedWithError:(NSString *)error;
- (void)testerBeganRunningService:(TSServiceTester *)tester;

- (void)testerWillInvokeService:(TSServiceTester *)tester withPasteboard:(NSPasteboard *)pasteboard;
- (void)testerFinishedRunningService:(TSServiceTester *)tester withPasteboard:(NSPasteboard *)pasteboard;
@end

@interface TSServiceTester : NSObject <TSServiceTestingProducer> {
    NSString *_launchPath;
    NSURL *_serviceURL;
    
    TSService *_service;
    
    id<TSServiceTestingSkeleton> _skeleton;
    NSPasteboard *_pasteboard;
    NSString *_registeredSkeletonName;
    NSConnection *_connection;
    NSTask *_serviceTask;
    
    dispatch_source_t _taskExitSource;
    
    id<TSServiceTesterDelegate> _delegate;
}
- (id)initWithServiceLaunchPath:(NSString *)launchPath service:(TSService *)service testServiceURL:(NSURL *)serviceURL;

@property (retain) id<TSServiceTestingSkeleton> skeleton;
@property (retain) NSPasteboard *pasteboard;
@property (retain) NSString *registeredSkeletonName;
@property (retain) NSConnection *connection;
@property (retain) NSTask *serviceTask;

@property (readonly, retain) TSService *service;

- (BOOL)startTesting;

- (void)setDelegate:(id<TSServiceTesterDelegate>)delegate;

- (BOOL)startConnection;

- (void)cancel;

@end
