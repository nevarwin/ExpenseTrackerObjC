//
//  ViewController.h
//  ExpenseTracker
//
//  Created by XOO_Raven on 6/26/25.
//

#import <UIKit/UIKit.h>
#import "Transaction.h"

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *transactionTableView;
@property (strong, nonatomic) NSMutableArray *transactionsArray;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) UISegmentedControl *dateSegmentControl;
@property (nonatomic, assign) NSInteger currentSegmentIndex;
@property (strong, nonatomic) UISegmentedControl *typeSegmentControl;
@property (weak, nonatomic) IBOutlet UIView *headerView;

- (IBAction)addTransaction:(UIButton *)sender;

@end



