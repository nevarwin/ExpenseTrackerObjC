//
//  BudgetFormViewController.h
//  ExpenseTracker
//
//  Created by raven on 8/6/25.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface BudgetFormViewController : UIViewController

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UIDatePicker *timePicker;
@property (nonatomic, strong) NSString *budgetName;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) NSDictionary<NSString *, NSAttributeDescription *> *expenseAttributes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDecimalNumber *> *expenseValues;

@property (nonatomic, strong) NSDictionary<NSString *, NSAttributeDescription *> *incomeAttributes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDecimalNumber *> *incomeValues;

@property (nonatomic, weak) id delegate;

@property (strong, nonatomic) UIBarButtonItem *rightButton;

@end

NS_ASSUME_NONNULL_END
