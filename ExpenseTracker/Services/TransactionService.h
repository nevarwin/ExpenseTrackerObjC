
#import <Foundation/Foundation.h>
#import "Budget+CoreDataClass.h"
#import "Category+CoreDataClass.h"
#import "Transaction+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface TransactionService : NSObject

+ (instancetype)sharedService;

- (NSArray<NSDictionary *> *)fetchBudgetsWithError:(NSError **)error;

- (NSArray<NSDictionary *> *)fetchCategoriesWithError:(NSError **)error 
                                             isIncome:(NSInteger)isIncome 
                                        transactionDate:(NSDate *)date 
                                            budgetID:(NSManagedObjectID *)budgetID
                             excludedTransactionID:(nullable NSManagedObjectID *)excludedTransactionID;

- (void)saveTransactionWithAmount:(NSDecimalNumber *)amount
                             desc:(NSString *)desc
                             date:(NSDate *)date
                           budget:(Budget *)budget
                         category:(Category *)category
                         isIncome:(BOOL)isIncome
               existingTransaction:(nullable Transaction *)existingTransaction
                       completion:(void (^)(BOOL success, NSError * _Nullable error, BOOL amountOverflow))completion;

@end

NS_ASSUME_NONNULL_END
