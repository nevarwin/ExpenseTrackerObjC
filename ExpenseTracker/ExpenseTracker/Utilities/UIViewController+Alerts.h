//
//  UIViewController+Alerts.h
//  ExpenseTracker
//
//  Created by raven on 10/1/25.
//

#ifndef UIViewController_Alerts_h
#define UIViewController_Alerts_h

#import <UIKit/UIKit.h>

@interface UIViewController (Alerts)
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
@end

#endif /* UIViewController_Alerts_h */
