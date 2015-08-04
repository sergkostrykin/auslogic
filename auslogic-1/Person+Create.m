//
//  Person+Create.m
//  auslogic-1
//
//  Created by Sergiy Kostrykin on 8/4/15.
//  Copyright (c) 2015 Sergiy Kostrykin. All rights reserved.
//

#import "Person+Create.h"

@implementation Person (Create)

+ (Person *)personWithPersonDictionary:(NSDictionary *)personDictionary
                inManagedObjectContext:(NSManagedObjectContext *)context
{
    Person *person = nil;
     NSInteger *personId = personDictionary[PERSON_ID];
    
    
    if (personId) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Person"];
        request.predicate = [NSPredicate predicateWithFormat:@"personId = %@", personId];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches || ([matches count] > 1)) {
            // handle error
        } else if (![matches count]) {
            person = [NSEntityDescription insertNewObjectForEntityForName:@"Person"
                                                         inManagedObjectContext:context];
            photographer.name = [personDictionary valueForKeyPath:PERSON_NAME];
        } else {
            person = [matches lastObject];
        }
    }
    
    return photographer;
}

@end