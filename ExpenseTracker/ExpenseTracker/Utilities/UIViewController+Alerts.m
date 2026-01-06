//
//  UIViewController+Alerts.m
//  ExpenseTracker
//
//  Created by raven on 10/1/25.
//

#import <Foundation/Foundation.h>
#import "UIViewController+Alerts.h"

@implementation UIViewController (Alerts)

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                               handler:nil];
    [alert addAction:ok];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
