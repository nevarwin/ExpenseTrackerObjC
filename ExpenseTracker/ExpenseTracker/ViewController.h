//
//  ViewController.h
//  ExpenseTracker
//
//  Created by XOO_Raven on 6/26/25.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

- (IBAction)addTransaction:(UIButton *)sender;

@property (weak, nonatomic) IBOutlet UITableView *transactionTableView;

@property (strong, nonatomic) NSMutableArray *transactionsArray;

@end


@protocol AddTransactionDelegate <NSObject>
- (void) didSaveTransactions: (NSMutableArray *) transactions;
@end;

