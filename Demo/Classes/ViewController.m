//
//  RootViewController.m
//  SVWebViewController
//
//  Created by Sam Vermette on 21.02.11.
//  Copyright 2011 Sam Vermette. All rights reserved.
//

#import "ViewController.h"
#import "SVWebViewController.h"

@implementation ViewController


- (void)pushWebViewController {
    NSURL *URL = [NSURL URLWithString:NSLocalizedStringFromTable(@"Webview_URL",@"SVWebViewController", @"")];
	SVWebViewController *webViewController = [[SVWebViewController alloc] initWithURL:URL];
	
	// uncomment the following line to set bar tint color under iOS 7
	//self.navigationController.navigationBar.barTintColor = [UIColor redColor];
	
	[self.navigationController pushViewController:webViewController animated:YES];
}


- (void)presentWebViewController {
    NSURL *URL = [NSURL URLWithString:NSLocalizedStringFromTable(@"Webview_URL",@"SVWebViewController", @"")];
	SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithURL:URL];
	webViewController.modalPresentationStyle = UIModalPresentationPageSheet;
    webViewController.availableActions = SVWebViewControllerAvailableActionsOpenInSafari | SVWebViewControllerAvailableActionsOpenInChrome | SVWebViewControllerAvailableActionsCopyLink | SVWebViewControllerAvailableActionsMailLink;
	
	// uncomment the following line to set bar tint color under iOS 7
	//webViewController.barsTintColor = [UIColor redColor];
	[self presentViewController:webViewController animated:YES completion:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}


@end

