//
//  ViewController.h
//  ExpenseTracker
//
//  Created by XOO_Raven on 6/26/25.
//

#import <UIKit/UIKit.h>
#import "Transaction.h"

@protocol AddTransactionDelegate <NSObject>
- (void) didSaveTransactions: (Transaction *) transactions;
@end;



@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *transactionTableView;
@property (strong, nonatomic) NSMutableArray *transactionsArray;

- (IBAction)addTransaction:(UIButton *)sender;

@end



