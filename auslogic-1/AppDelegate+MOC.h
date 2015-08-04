//
//  AppDelegate+MOC.h

#import "AppDelegate.h"

@interface AppDelegate (MOC)

- (NSManagedObjectContext *)createMainQueueManagedObjectContext;

@end
