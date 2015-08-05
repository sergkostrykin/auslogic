//
//  Person+Create.h
//  auslogic-1
//
//  Created by Sergiy Kostrykin on 8/4/15.
//  Copyright (c) 2015 Sergiy Kostrykin. All rights reserved.
//

#import "Person.h"

@interface Person (Create)

+ (Person *)personWithPersonInfo:(NSDictionary *) personDictionary
                inManagedObjectContext:(NSManagedObjectContext *)context;

+ (void)loadDataFromArray:(NSArray *)persons // of person NSDictionary
         intoManagedObjectContext:(NSManagedObjectContext *)context;


@end
