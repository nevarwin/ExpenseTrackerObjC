//
//  CategoryAlert.h
//  ExpenseTracker
//
//  Created by raven on 10/13/25.
//
#import <UIKit/UIKit.h>

#ifndef CategoryAlert_h
#define CategoryAlert_h

@interface CategoryAlert : UIViewController

// TableViews
@property (nonatomic, strong) UITableView *categoryInfoTableView;
@property (nonatomic, strong) UITableView *installmentInfoTableView;

// UI Controls
@property (nonatomic, strong) UITextField *categoryTextField;
@property (nonatomic, strong) UISwitch *installmentSwitch;
@property (nonatomic, strong) UIDatePicker *startDatePicker;
@property (nonatomic, strong) UITextField *monthsTextField;
@property (nonatomic, strong) UILabel *monthlyLabel;
@property (nonatomic, strong) UILabel *totalLabel;
@end


#endif /* CategoryAlert_h */
