//
//  EventRecord.h
//  Livo
//
//  Created by Deniz Acay on 02/10/15.
//  Copyright (c) 2015 Livo Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface EventRecord : NSManagedObject

@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSData * parameters;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSNumber * synchronized;

@end
