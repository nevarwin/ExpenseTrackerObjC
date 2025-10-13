//
//  CategoryAlert.h
//  ExpenseTracker
//
//  Created by raven on 10/13/25.
//
#import <UIKit/UIKit.h>

#ifndef CategoryViewController_h
#define CategoryViewController_h

@interface CategoryViewController : UIViewController

// TableViews
@property (nonatomic, strong) UITableView *categoryInfoTableView;

// UI Controls
@property (nonatomic, strong) UITextField *categoryTextField;
@property (nonatomic, strong) UISwitch *installmentSwitch;
@property (nonatomic, strong) UIDatePicker *startDatePicker;
@property (nonatomic, strong) UITextField *monthsTextField;
@property (nonatomic, strong) UITextField *amountTextField;
@property (nonatomic, strong) UITextField *monthlyTextField;
@property (nonatomic, assign) BOOL installmentEnabled;

@end


#endif /* CategoryViewController_h */
