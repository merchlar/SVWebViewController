//
//  SVWebViewController.h
//
//  Created by Sam Vermette on 08.11.10.
//  Copyright 2010 Sam Vermette. All rights reserved.
//
//  https://github.com/samvermette/SVWebViewController

#import <MessageUI/MessageUI.h>
#import "MBProgressHUD.h"
#import "SVModalWebViewController.h"

@interface SVWebViewController : UIViewController <UIWebViewDelegate>

- (id)initWithAddress:(NSString*)urlString;
- (id)initWithURL:(NSURL*)URL;

@property (nonatomic, readwrite) SVWebViewControllerAvailableActions availableActions;
@property (nonatomic, assign) BOOL hideToolbar;
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) MBProgressHUD * currentLoader;
@property (strong, nonatomic) IBOutlet UIView *noConnectionView;
@property BOOL isAlreadyLoad;
@property (weak, nonatomic) IBOutlet UIImageView *noReachabilityImageView;

@property (nonatomic, strong) UIWebView *mainWebView;


@end
