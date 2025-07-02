//
//  ViewController.h
//  ExpenseTracker
//
//  Created by XOO_Raven on 6/26/25.
//

#import <UIKit/UIKit.h>
#import "Transaction.h"

@protocol TransactionDelegate <NSObject>
- (void) didSaveTransaction: (Transaction *) transactions;
- (void) didUpdateTransaction: (Transaction *) transaction id:(NSString *) id;
@end;



@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *transactionTableView;
@property (strong, nonatomic) NSMutableArray *transactionsArray;

- (IBAction)addTransaction:(UIButton *)sender;

@end



