//
//  BudgetDisplayViewController.h
//  ExpenseTracker
//
//  Created by raven on 8/26/25.
//

#import <UIKit/UIKit.h>
#import "Budget+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BudgetDisplayViewControllerDelegate <NSObject>
@optional
- (void)didUpdateData;
@end

@interface BudgetDisplayViewController : UIViewController

@property (nonatomic, assign) BOOL isEditMode;
@property (nonatomic, weak) id<BudgetDisplayViewControllerDelegate> delegate;

@property (nonatomic, strong) Budget *budget;
@property (nonatomic, strong) UITextField *headerLabelTextField;
@property (nonatomic, strong) UITableView *budgetDisplayTableView;
@property (nonatomic, strong) UIView *headerContainer;
@property (strong, nonatomic) UIBarButtonItem *rightButton;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) NSMutableArray* income;
@property (nonatomic, strong) NSMutableArray* expenses;

@property (nonatomic, strong) NSMutableArray* incomeAmounts;
@property (nonatomic, strong) NSMutableArray* expensesAmounts;

@property (nonatomic, strong) NSMutableArray* incomeUsedAmounts;
@property (nonatomic, strong) NSMutableArray* expensesUsedAmounts;

@property (nonatomic, strong) UIView *yearHeaderView;
@property (nonatomic, strong) UILabel *monthLabel;
@property (nonatomic, strong) UITextField *monthTextField;
@property (nonatomic, strong) UILabel *yearLabel;
@property (nonatomic, strong) UITextField *yearTextField;
@property (nonatomic, strong) NSDateComponents *currentDateComponents;

@property (nonatomic, strong) UITableView *budgetInfoTableView;
@property (nonatomic, strong) NSLayoutConstraint *budgetInfoTableViewHeightConstraint;

@property (nonatomic, strong) UILabel *rightLabel;
@end

NS_ASSUME_NONNULL_END
