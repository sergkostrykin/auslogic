//
//  AppDelegate.m
//  auslogic-1
//
//  Created by Sergiy Kostrykin on 8/4/15.
//  Copyright (c) 2015 Sergiy Kostrykin. All rights reserved.
//


#import "AppDelegate.h"
#import "AppDelegate+MOC.h"
#import "DataFetcher.h"
#import "Person+Create.h"
#import "DatabaseAvailability.h"

#define PERSON_URL @"http://wader.com.ua/person/"

@interface AppDelegate() <NSURLSessionDownloadDelegate>
@property (copy, nonatomic) void (^downloadBackgroundURLSessionCompletionHandler)();
@property (strong, nonatomic) NSURLSession *downloadSession;
@property (strong, nonatomic) NSTimer *foregroundFetchTimer;
@property (strong, nonatomic) NSManagedObjectContext *personDatabaseContext;
@end

#define DATA_FETCH @"Just Uploaded Fetch"
#define FOREGROUND_DATA_FETCH_INTERVAL (20*60)
#define BACKGROUND_DATA_FETCH_TIMEOUT (10)

@implementation AppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.personDatabaseContext = [self createMainQueueManagedObjectContext];
    [self startFetch];
    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
        if (self.personDatabaseContext) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        sessionConfig.allowsCellularAccess = NO;
        sessionConfig.timeoutIntervalForRequest = BACKGROUND_DATA_FETCH_TIMEOUT; // want to be a good background citizen!
        NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:PERSON_URL]];
        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                                        completionHandler:^(NSURL *localFile, NSURLResponse *response, NSError *error) {
                                                            if (error) {
                                                                NSLog(@"Background fetch failed: %@", error.localizedDescription);
                                                                completionHandler(UIBackgroundFetchResultNoData);
                                                            } else {
                                                                [self loadDataFromLocalURL:localFile
                                                                                       intoContext:self.personDatabaseContext
                                                                               andThenExecuteBlock:^{
                                                                                   completionHandler(UIBackgroundFetchResultNewData);
                                                                               }
                                                                 ];
                                                            }
                                                        }];
        [task resume];
    } else {
        completionHandler(UIBackgroundFetchResultNoData); // no app-switcher update if no database!
    }
}


#pragma mark - Database Context

- (void)setPersonDatabaseContext:(NSManagedObjectContext *)personDatabaseContext
{
    
    _personDatabaseContext = personDatabaseContext;
    [self.foregroundFetchTimer invalidate];
    self.foregroundFetchTimer = nil;
    if (self.personDatabaseContext)
    {
        self.foregroundFetchTimer = [NSTimer scheduledTimerWithTimeInterval:FOREGROUND_DATA_FETCH_INTERVAL
                                                                           target:self
                                                                         selector:@selector(startFetch:)
                                                                         userInfo:nil
                                                                          repeats:YES];
    }
    NSDictionary *userInfo = self.personDatabaseContext ? @{ DatabaseAvailabilityContext : self.personDatabaseContext } : nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:DatabaseAvailabilityNotification
                                                        object:self
                                                      userInfo:userInfo];
}

#pragma mark - Fetching

- (void)startFetch
{
    [self.downloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        if (![downloadTasks count]) {
            NSURLSessionDownloadTask *task = [self.downloadSession downloadTaskWithURL:[NSURL URLWithString:PERSON_URL]];
            task.taskDescription = DATA_FETCH;
            [task resume];
        } else {
            for (NSURLSessionDownloadTask *task in downloadTasks) [task resume];
        }
    }];
}

- (void)startFetch:(NSTimer *)timer {
    [self startFetch];
}


- (NSURLSession *)downloadSession {
    
    if (!_downloadSession) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSURLSessionConfiguration *urlSessionConfig = [NSURLSessionConfiguration backgroundSessionConfiguration:DATA_FETCH];
            _downloadSession = [NSURLSession sessionWithConfiguration:urlSessionConfig
                                                                   delegate:self
                                                              delegateQueue:nil];
        });
    }
    return _downloadSession;
}


- (NSArray *)personsAtURL:(NSURL *)url
{
    NSDictionary *personPropertyList;
    NSData *personJSONData = [NSData dataWithContentsOfURL:url];  // will block if url is not local!
    
    if (personJSONData) {
        personPropertyList = [NSJSONSerialization JSONObjectWithData:personJSONData
                                                             options:0
                                                               error:NULL];
    }
    return [personPropertyList valueForKeyPath:PERSON_DATA];
}


- (void)loadDataFromLocalURL:(NSURL *)localFile
                         intoContext:(NSManagedObjectContext *)context
                 andThenExecuteBlock:(void(^)())whenDone
{
    if (context) {
        NSArray *persons = [self personsAtURL:localFile];
        [context performBlock:^{
            [Person loadDataFromArray:persons intoManagedObjectContext:context];
            [context save:NULL];
        if (whenDone) whenDone();
        }];
    } else {
        if (whenDone) whenDone();
    }
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)localFile
{
    if ([downloadTask.taskDescription isEqualToString:DATA_FETCH]) {
       [self loadDataFromLocalURL:localFile
                               intoContext:self.personDatabaseContext
                       andThenExecuteBlock:^{
                           [self downloadTasksMightBeComplete];
                       }
         ];
    }
}


- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
}

- (void)downloadTasksMightBeComplete
{
    if (self.downloadBackgroundURLSessionCompletionHandler) {
        [self.downloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            // we're doing this check for other downloads just to be theoretically "correct"
            //  but we don't actually need it (since we only ever fire off one download task at a time)
            // in addition, note that getTasksWithCompletionHandler: is ASYNCHRONOUS
            //  so we must check again when the block executes if the handler is still not nil
            //  (another thread might have sent it already in a multiple-tasks-at-once implementation)
            if (![downloadTasks count]) {  // any more Flickr downloads left?
                // nope, then invoke flickrDownloadBackgroundURLSessionCompletionHandler (if it's still not nil)
                void (^completionHandler)() = self.downloadBackgroundURLSessionCompletionHandler;
                self.downloadBackgroundURLSessionCompletionHandler = nil;
                if (completionHandler) {
                    completionHandler();
                }
            } // else other downloads going, so let them call this method when they finish
        }];
    }
}

@end
