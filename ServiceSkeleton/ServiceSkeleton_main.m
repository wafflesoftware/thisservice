//
//  ServiceSkeleton_main.m
//  ThisService
//
//  Created by Jesper on 2006-10-28.
//  Copyright 2006-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import <Foundation/Foundation.h>
#import "ServiceSkeletonMagic.h"

int main (int argc, char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    ServiceSkeletonMagic *serviceProvider = [[ServiceSkeletonMagic alloc] init];
    
    BOOL printScriptURLAndQuit = NO;
    BOOL justRegister = NO;
    NSString *testingServiceConnectionName = nil;
    BOOL isTestingService = NO;
    
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    NSString *testingServicePrefix = @"-THISSERVICE_TESTING_SERVICE__";
    for (NSString *argument in arguments) {
        if ([argument isEqualToString:@"-THISSERVICE_PRINT_SCRIPT_URL_AND_QUIT"]) {
            printScriptURLAndQuit = YES;
        }
        if ([argument isEqualToString:@"-THISSERVICE_REGISTER_SERVICE"]) {
            justRegister = YES;
        }
        if ([argument hasPrefix:testingServicePrefix]) {
            testingServiceConnectionName = [argument substringFromIndex:testingServicePrefix.length];
            if (testingServiceConnectionName.length == 0) {
                testingServiceConnectionName = nil;
            } else {
                isTestingService = YES;
            }
        }
    }
    

	// This supports the discovery of the script's location, used in reference-style services.
	if (printScriptURLAndQuit) {
//		NSLog(@"-THISSERVICE_PRINT_SCRIPT_URL_AND_QUIT");
		NSURL *scriptURL = [serviceProvider urlToScript];
		printf("%s\n", [[scriptURL absoluteString] UTF8String]);
		goto shutdowndirectlyjustexiting; // http://xkcd.com/292/
	}
	
	NSString *portName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ServiceSkeletonPortName"];
	
	NSString *friendlyName = [NSString stringWithFormat:@"%@Service", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ServiceSkeletonSuitableExecutableName"]];
	//NSLog(@"program name: %s", argv[0]);
	[[NSProcessInfo processInfo] setProcessName:friendlyName];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    BOOL logging = [ud boolForKey:@"DebugLogging"];
    [ServiceSkeletonMagic setLogging:logging];
    
    if (!isTestingService) {
        SLog(@"Starting service: %@ (%@)", [[NSProcessInfo processInfo] processName], portName);
        
        NSRegisterServicesProvider(serviceProvider, portName);
        NSUpdateDynamicServices();
        
        SLog(@"Registered %@ for services!", friendlyName);
    } else {
        SLog(@"Testing service %@", friendlyName);
    }
	
	if (justRegister) {
		SLog(@"Exiting since we're just registering the service.");
		goto shutdowndirectly; // OMG SPAGHETTI CODE!1
	}
    
    NSRunLoop *currentLoop = [NSRunLoop currentRunLoop]; // ensure created
    
    
	if (isTestingService) {
        [serviceProvider performSelectorOnMainThread:@selector(setUpServiceTesting:) withObject:testingServiceConnectionName waitUntilDone:NO];
	} else {
        [serviceProvider bumpBailingTimer];
    }
	
    @try {
        while ([ServiceSkeletonMagic shouldKeepRunning] && [currentLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:3]]) {
//            NSLog(@"#RL# run loop tick; shouldKeepRunning is %d", [ServiceSkeletonMagic shouldKeepRunning]);
            ;
        }
    } @catch (NSException *localException) {
        SLog(@"%@", localException);
    }
	
shutdowndirectly:
	SLog(@"Exiting service %@...", friendlyName);
shutdowndirectlyjustexiting:
    [serviceProvider release];
    [pool release];
	
    exit(0);       // ensure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}
