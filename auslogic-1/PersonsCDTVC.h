//
//  PersonsCDTVC.h
//  auslogic-1
//
//  Created by Sergiy Kostrykin on 8/5/15.
//  Copyright (c) 2015 Sergiy Kostrykin. All rights reserved.
//

#import "CoreDataTableViewController.h"

@interface PersonsCDTVC : CoreDataTableViewController
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end
