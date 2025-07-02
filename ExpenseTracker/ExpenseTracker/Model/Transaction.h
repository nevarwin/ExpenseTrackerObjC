//
//  Transaction.h
//  ExpenseTracker
//
//  Created by XOO_Raven on 6/27/25.
//

#ifndef Transaction_h
#define Transaction_h
#import <CoreData/CoreData.h>

@interface Transaction  : NSManagedObject

@property (nullable, nonatomic, copy) NSString *transactionId;
@property (nonatomic) int32_t amount;
@property (nullable, nonatomic, copy) NSString *category;
@property (nullable, nonatomic, copy) NSDate *createdAt;

@end

#endif /* Transaction_h */

