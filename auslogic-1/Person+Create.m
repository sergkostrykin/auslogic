//
//  Person+Create.m
//  auslogic-1
//
//  Created by Sergiy Kostrykin on 8/4/15.
//  Copyright (c) 2015 Sergiy Kostrykin. All rights reserved.
//

#import "Person+Create.h"
#import "DataFetcher.h"

@implementation Person (Create)

+ (Person *)personWithPersonInfo:(NSDictionary *)personDictionary
                inManagedObjectContext:(NSManagedObjectContext *)context
{
    Person *person = nil;
     NSInteger personId = [personDictionary[PERSON_ID] integerValue];
    
    
    if (personId) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Person"];
        request.predicate = [NSPredicate predicateWithFormat:@"personId = %i", personId];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
            // handle error
        
    
        if (!matches || error || ([matches count] > 1)) {
        } else if ([matches count]) {
            person = [matches firstObject];
        } else         
        {
            person = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:context];
            person.personName = [personDictionary valueForKeyPath:PERSON_NAME];
            person.personCountry = [personDictionary valueForKeyPath:PERSON_COUNTRY];
            
        }
    }
    
    return person;
}

+ (void)loadDataFromArray:(NSArray *)persons intoManagedObjectContext:(NSManagedObjectContext *)context


{
    for (NSDictionary *person in persons) {
        [self personWithPersonInfo:person inManagedObjectContext:context];
    }
}



@end
