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
@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) UIButton *addButton;

@property (strong, nonatomic) UITableView *transactionTableView;
@property (strong, nonatomic) NSMutableArray *transactionsArray;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (strong, nonatomic) UISegmentedControl *typeSegmentControl;
@property (nonatomic, assign) NSInteger typeSegmentIndex;


@end



