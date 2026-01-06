//
//  BudgetViewController.h
//  ExpenseTracker
//
//  Created by raven on 8/4/25.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface BudgetViewController : UIViewController

@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) UITableView *budgetTableView;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

NS_ASSUME_NONNULL_END
