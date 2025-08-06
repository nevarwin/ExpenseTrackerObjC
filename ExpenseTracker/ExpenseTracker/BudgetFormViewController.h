//
//  BudgetFormViewController.h
//  ExpenseTracker
//
//  Created by raven on 8/6/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BudgetFormViewController : UIViewController

@property (nonatomic, assign) BOOL isEditMode;
@property (nonatomic, weak) id delegate;

@property (strong, nonatomic) UIBarButtonItem *rightButton;
@property (strong, nonatomic) UIBarButtonItem *leftButton;

@end

NS_ASSUME_NONNULL_END
