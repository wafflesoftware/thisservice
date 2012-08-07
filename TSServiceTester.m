//
//  TSServiceTester.m
//  ThisService
//
//  Created by Jesper on 2012-07-05.
//  Copyright 2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//
//

#import "TSServiceTester.h"

#import "TSService.h"

@implementation TSServiceTester

@synthesize skeleton=_skeleton, registeredSkeletonName=_registeredSkeletonName,
            pasteboard=_pasteboard, connection=_connection,
            serviceTask=_serviceTask;

- (id)initWithServiceLaunchPath:(NSString *)launchPath service:(TSService *)service testServiceURL:(NSURL *)serviceURL {
    self = [super init];
    if (self) {
        _launchPath = [launchPath retain];
        _service = [service retain];
        _serviceURL = [serviceURL retain];
    }
    return self;
}

- (void)setDelegate:(id<TSServiceTesterDelegate>)delegate {
    _delegate = delegate;
}

- (void)cancel {
    if (self.connection) {
        @try {
        if (self.skeleton) {
            [self.skeleton testingDone];
        }
        [self.connection invalidate];
        } @finally {
            self.connection = nil;
        }
    }
    
    if (self.serviceTask) {
        if ([self.serviceTask isRunning]) {
            [self performSelector:@selector(killTask:) withObject:self.serviceTask afterDelay:50];
        }
    }
}

- (void)killTask:(NSTask *)task {
    [task terminate];
}

- (TSService *)service {
    return _service;
}

- (void)removeServiceBundle {
    [[NSFileManager defaultManager] removeItemAtURL:_serviceURL error:NULL];
}

- (BOOL)startConnection {
    NSString *connectionName = [NSString stringWithFormat:@"thisservice-app-%@", [[NSProcessInfo processInfo] globallyUniqueString]];
    
    NSConnection *theConnection = [NSConnection serviceConnectionWithName:connectionName rootObject:self];
    if (!theConnection) return NO;
    
    NSLog(@"registered producer as %@", connectionName);
    
    self.connection = theConnection;
    
    NSArray *arguments = [NSArray arrayWithObject:[@"-THISSERVICE_TESTING_SERVICE__" stringByAppendingString:connectionName]];
    
    self.serviceTask = [NSTask launchedTaskWithLaunchPath:_launchPath arguments:arguments];
    pid_t pid = self.serviceTask.processIdentifier;
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _taskExitSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_PROC,
                                                      pid, DISPATCH_PROC_EXIT, queue);
    if (_taskExitSource) {
        __block TSServiceTester *bself = self;
        dispatch_source_set_event_handler(_taskExitSource, ^{
            NSLog(@"process %d exited; remove service bundle %@", pid, bself->_serviceURL);
            [bself removeServiceBundle];
            dispatch_source_cancel(bself->_taskExitSource);
            dispatch_release(bself->_taskExitSource);
            bself->_taskExitSource = nil;
        });
        dispatch_resume(_taskExitSource);
    }
    
    [_delegate testerLaunchedService:self];
    
    return YES;
}

- (void)dealloc {
    if (_taskExitSource) {
        dispatch_source_cancel(_taskExitSource);
        dispatch_release(_taskExitSource);
    }
    [_launchPath release];
    [_service release];
    [_serviceURL release];
    
    [_serviceTask release];
    [_connection release];
    [_registeredSkeletonName release];
    [_pasteboard release];
    [_skeleton release];
    
    [super dealloc];
}

- (oneway void)registerNewSkeletonNamed:(NSString *)skeletonName {
    self.registeredSkeletonName = skeletonName;
    
    NSConnection *connectionToSkeleton = [NSConnection connectionWithRegisteredName:skeletonName host:nil];
    id skeletonProxy = [connectionToSkeleton rootProxy];
    [skeletonProxy setProtocolForProxy:@protocol(TSServiceTestingSkeleton)];
    self.skeleton = skeletonProxy;
    
    [_delegate testerPairedWithService:self];
}

- (BOOL)startTesting {
    BOOL couldFreshen = [_service freshenScriptInFileWrapperWrittenAtURL:_serviceURL];
    if (!couldFreshen) return NO;
    
    if (!self.pasteboard) {
        self.pasteboard = [NSPasteboard pasteboardWithUniqueName];
    } else {
        [self.pasteboard clearContents];
    }
    
    [_delegate testerWillInvokeService:self withPasteboard:self.pasteboard];
    
    NSString *name = self.pasteboard.name;
    
    [self.skeleton invokeServiceWithPasteboard:name];
    
    return YES;
}

- (oneway void)testRunForSkeletonStarted:(NSString *)skeletonName {
    [_delegate testerBeganRunningService:self];
}

- (oneway void)testRunForSkeleton:(NSString *)skeletonName ended:(NSString *)error {
    if (error) {
        [_delegate tester:self failedWithError:error];
    } else {
        [_delegate testerFinishedRunningService:self withPasteboard:self.pasteboard];
    }
}

@end
