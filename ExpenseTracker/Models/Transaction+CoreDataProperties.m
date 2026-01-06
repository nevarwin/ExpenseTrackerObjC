//
//  Transaction+CoreDataProperties.m
//  ExpenseTracker
//
//  Created by raven on 9/15/25.
//
//

#import "Transaction+CoreDataProperties.h"

@implementation Transaction (CoreDataProperties)

+ (NSFetchRequest<Transaction *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Transaction"];
}

@dynamic amount;
@dynamic desc;
@dynamic createdAt;
@dynamic date;
@dynamic isActive;
@dynamic updatedAt;
@dynamic budget;
@dynamic category;

@end
