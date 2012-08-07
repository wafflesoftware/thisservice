//
//  TSServiceTesting.h
//  ThisService
//
//  Created by Jesper on 2012-07-05.
//  Copyright 2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//
//

#import <Foundation/Foundation.h>

@protocol TSServiceTestingSkeleton <NSObject> // skeleton called by ThisService
- (oneway void)invokeServiceWithPasteboard:(NSString *)pasteboardName;
- (oneway void)testingDone;
@end

@protocol TSServiceTestingProducer <NSObject> // TS called by the skeleton
// the name of the connection of the skeleton vending a id<TSServiceTestingSkeleton> object
- (oneway void)registerNewSkeletonNamed:(NSString *)skeletonName;
- (oneway void)testRunForSkeletonStarted:(NSString *)skeletonName;
- (oneway void)testRunForSkeleton:(NSString *)skeletonName ended:(NSString *)error; // error being nil indicates success
@end


/*
  1. The ThisService application (TS) creates the service.
  2. TS creates an object like id<TSServiceTestingProducer> and vends it.
  3. TS runs the service skeleton in the newly created service, passing in the name of its connection as a flag.
  4. The service invents a unique name and names its NSConnection.
  5. The service creates an object like id<TSServiceTestingProducer> and vends it.
  6. The service connects to the TS object and registers the new skeleton using the unique name.
  7. When testing is requested:
     a. TS sets up a unique pasteboard (inherently cross-process) using system functionality.
     b. If necessary, TS populates the pasteboard with the input data.
     c. TS invokes the service passing the name of the pasteboard.
     d. Glue code in the service skeleton runs the service as usual with the pasteboard, noting to TS that it has started running.
     e. On error, the service reports the error; on success, the service reports the success. This is the same call.
  8. When the test sheet is dismissed for any reason, testingDone is called and both ends are torn down.
 */
