//
//  DataFetcher.h
//  auslogic-1
//
//  Created by Sergiy Kostrykin on 8/5/15.
//  Copyright (c) 2015 Sergiy Kostrykin. All rights reserved.
//

#import <Foundation/Foundation.h>

// key paths to photos or places at top-level of Flickr results
#define PERSON_DATA @"person"
//#define FLICKR_RESULTS_PLACES @"places.place"

// keys (paths) to values in a person dictionary
#define PERSON_ID @"id"
#define PERSON_NAME @"name"
#define PERSON_COUNTRY @"country"

@interface DataFetcher : NSObject

@end
