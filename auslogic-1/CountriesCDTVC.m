//
//  CountriesCDTVC.m
//  auslogic-1
//
//  Created by Sergiy Kostrykin on 8/6/15.
//  Copyright (c) 2015 Sergiy Kostrykin. All rights reserved.
//

#import "CountriesCDTVC.h"
#import "Person.h"
#import "DatabaseAvailability.h"

@implementation CountriesCDTVC

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserverForName:DatabaseAvailabilityNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      self.managedObjectContext = note.userInfo[DatabaseAvailabilityContext];
                                                  }];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSInteger randomID = arc4random() % 6;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Person"];
    request.predicate = [NSPredicate predicateWithFormat:@"personId = %d", randomID];
    NSError *error;
    NSArray *matches = [self.managedObjectContext executeFetchRequest:request error:&error];
    if ([matches count]) {
        Person *person = [matches firstObject];
        person.personName = @"AAA";
    }
    
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Person"];
    request.predicate = nil;
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"personCountry"
                                                                  ascending:YES
                                                                   selector:@selector(localizedStandardCompare:)]];
    
//    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"personId" ascending:YES]];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Country Cell"];
    
    Person *person = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = person.personName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", person.personCountry];
    return cell;
}

@end
