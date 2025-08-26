//
//  BudgetDisplayViewController.h
//  ExpenseTracker
//
//  Created by raven on 8/26/25.
//

#import <UIKit/UIKit.h>
#import "Budget+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface BudgetDisplayViewController : UIViewController

@property (nonatomic, strong) Budget *budget;
@end

NS_ASSUME_NONNULL_END
