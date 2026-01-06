//
//  ViewController.h
//  ExpenseTracker
//
//  Created by raven on 6/26/25.
//

#import <UIKit/UIKit.h>
#import "Transaction+CoreDataClass.h"

@interface ViewController : UIViewController

@property (nonatomic, strong) UIView *headerContainer;
@property (nonatomic, strong) UIView *yearHeaderView;
@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) UILabel *monthLabel;
@property (nonatomic, strong) UILabel *yearLabel;
@property (nonatomic, strong) UIButton *addButton;

@property (strong, nonatomic) UITableView *transactionTableView;
@property (strong, nonatomic) NSMutableArray *transactionsArray;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (strong, nonatomic) UISegmentedControl *typeSegmentControl;
@property (strong, nonatomic) UISegmentedControl *weekSegmentControl;
@property (nonatomic, assign) NSInteger typeSegmentIndex;
@property (nonatomic, assign) NSInteger weekSegmentIndex;

@property (nonatomic, strong) UITextField *monthTextField;
@property (nonatomic, strong) UITextField *yearTextField;

@property (nonatomic, strong) NSDateComponents *currentDateComponents;

@property (nonatomic, strong) NSString *dateRange;

@end



