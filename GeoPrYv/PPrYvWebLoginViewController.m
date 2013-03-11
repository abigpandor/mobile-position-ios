//
//  PPrYvWebLoginViewController.m
//  AT PrYv
//
//  Created by Konstantin Dorodov on 3/8/13.
//  Copyright (c) 2013 Pryv. All rights reserved.
//

#import "PPrYvWebLoginViewController.h"
#import "AFNetworking.h"

#import "User+Extras.h"
#import "PPrYvCoreDataManager.h"
#import "PPrYvApiClient.h"
#import "Folder.h"

@interface PPrYvWebLoginViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingActivityIndicatorView;

@property (strong, nonatomic) NSTimer *pollTimer;

@property (assign, nonatomic) NSUInteger iteration;

@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *token;

@end


@implementation PPrYvWebLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.webView.delegate = self;
    
    [self requestLoginView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    // kill the timer if one existed
    [self.pollTimer invalidate];
}

#pragma mark - Private

// POST request to /access to obtain a login page URL and load the contents of the URL
//      (which is a login form) to a child webView
//      activate a timer loop 

- (void)requestLoginView
{
    // TODO extract the url to a more meaningful place
    NSURL *url = [NSURL URLWithString:@"https://reg.rec.la"];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    httpClient.parameterEncoding = AFJSONParameterEncoding;
    [httpClient setDefaultHeader:@"Accept" value:@"application/json"];
    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    NSDictionary *params = @{
                             // TODO extract the app id some where to constants
                             @"requestingAppId": @"pryv-mobile-position-ios",
                             @"returnURL": @"false",
                             
                             @"requestedPermissions": @[
                                     @{
                                         @"channelId" : @"position",
                                         @"level" : @"manage",
                                         @"defaultName" : @"Position",
                                       }
                             ]};

    [self.loadingActivityIndicatorView startAnimating];
    
    [httpClient postPath:@"/access" parameters:params success:^(AFHTTPRequestOperation *operation, id JSON) {
        assert(JSON);
        NSLog(@"Request Successful, response '%@'", JSON);
        
        assert([JSON isKindOfClass:[NSDictionary class]]);
        NSDictionary *jsonDictionary = (NSDictionary *)JSON;

        assert([JSON objectForKey:@"url"]);
        NSString *loginPageUrlString = jsonDictionary[@"url"];
        
        NSURL *loginPageURL = [NSURL URLWithString:loginPageUrlString];
        assert(loginPageURL);

        // TODO activate a poll loop with repeating timer
        NSString *pollUrlString = jsonDictionary[@"poll"];
        assert(pollUrlString);
        
        NSURL *pollURL = [NSURL URLWithString:pollUrlString];
        assert(pollURL);
        
        NSString *pollTimeIntervalString = jsonDictionary[@"poll_rate_ms"];
        assert(pollTimeIntervalString);
        
        NSTimeInterval pollTimeInterval = [pollTimeIntervalString doubleValue] / 1000;
        [self pollURL:pollURL withTimeInterval:pollTimeInterval];
        
        [self.webView loadRequest:[NSURLRequest requestWithURL:loginPageURL]];
    
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        [self.loadingActivityIndicatorView stopAnimating];
        
        // TODO create an alert to notify a user about the problem
        //  like the network not being present
        
        NSLog(@"[HTTPClient Error]: %@", error);
    }];
}

- (void)pollURL:(NSURL *)pollURL withTimeInterval:(NSTimeInterval)pollTimeInterval
{
    NSLog(@"create a poll request to %@ with interval: %f", pollURL, pollTimeInterval);
    
    NSURLRequest *pollRequest = [NSURLRequest requestWithURL:pollURL];
    AFJSONRequestOperation *pollRequestOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:pollRequest
    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        assert(JSON);
        NSLog(@"poll request success : %@", [request URL]);
        
        NSDictionary *jsonDictionary = (NSDictionary *)JSON;
        
        // check status
        NSString *statusString = jsonDictionary[@"status"];
        
        if ([@"NEED_SIGNIN" isEqualToString:statusString]) {
            
            NSString *pollUrlString = jsonDictionary[@"poll"];
            assert(pollUrlString);
            
            NSURL *pollURL = [NSURL URLWithString:pollUrlString];
            assert(pollURL);
            
            NSString *pollTimeIntervalString = jsonDictionary[@"poll_rate_ms"];
            assert(pollTimeIntervalString);
            
            NSTimeInterval pollTimeInterval = [pollTimeIntervalString doubleValue] / 1000;
            
            // recursive call
            
            // TODO weakself
            [self pollURL:pollURL withTimeInterval:pollTimeInterval];
        } else {
            NSLog(@"status changed to %@", statusString);
            
            // process the different statuses
            
            if ([@"ACCEPTED" isEqualToString:statusString]) {
                
                // if status ACCEPTED proceed with username and token
                NSString *username = jsonDictionary[@"username"];
                NSString *token = jsonDictionary[@"token"];
                
                [self successfulLoginWithUsername:username token:token];
                
            } else {
                // TODO add status handling
                NSLog(@"poll request unknown status: %@", statusString);
            }
//            } else if ([@"REFUSED" isEqualToString:statusString]) {
//                
//                // TODO
//                
//            } else if ([@"ERROR" isEqualToString:statusString]) {
//                
//                // TODO
//                
//            }
        }
        
    }
    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"poll request %@ has failed %@ ", request, error);
        if (JSON) {
            NSLog(@"error contained a JSON: %@", JSON);
        }
    }];
    
    // reset previous timer if one existed
    [self.pollTimer invalidate];
    
    // create a GET reqest in seconds amount stored in pollTimeInterval
    self.pollTimer = [NSTimer scheduledTimerWithTimeInterval:pollTimeInterval
                                                       target:[NSBlockOperation blockOperationWithBlock:^{ [pollRequestOperation start]; NSLog(@"timer fired");}]
                                            selector:@selector(main) // send message main to NSBLockOperation
                                            userInfo:nil
                                             repeats:NO
    ];
}


-  (void)successfulLoginWithUsername:(NSString *)username token:(NSString *)token
{
    self.username = username;
    self.token = token;
    
    // initiate user creation 
    User * newUser = [User createUserWithId:username
                                      token:token
                                  inContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPrYvLocationDistanceIntervalDidChangeNotification
                                                        object:nil
                                                      userInfo:@{kPrYvLocationDistanceIntervalDidChangeNotificationUserInfoKey : newUser.locationDistanceInterval}];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPrYvLocationTimeIntervalDidChangeNotification
                                                        object:nil
                                                      userInfo:@{kPrYvLocationTimeIntervalDidChangeNotificationUserInfoKey : newUser.locationTimeInterval}];
    
    // start or restart the api Client with the new user upon successful start it would try to synchronize
    PPrYvApiClient *apiClient = [PPrYvApiClient sharedClient];
    [apiClient startClientWithUserId:newUser.userId
                          oAuthToken:newUser.userToken
                           channelId:kPrYvApplicationChannel successHandler:^(NSTimeInterval serverTime)
     {
         [self findExistingOrCreateNewFolderForUser];
     }
                        errorHandler:^(NSError *error)
     {
         [[[UIAlertView alloc] initWithTitle:nil
                                     message:NSLocalizedString(@"alertCantSynchronize", )
                                    delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"cancelButton", )
                           otherButtonTitles:nil] show];
     }];
    
}

#pragma mark - Target Actions

- (IBAction)close:(id)sender
{
    [self.pollTimer invalidate];
    // TODO
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"shouldStartLoadWithRequest ");
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.loadingActivityIndicatorView startAnimating];

    NSLog(@"webViewDidStartLoad ");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // TODO
    
    [self.loadingActivityIndicatorView stopAnimating];

    NSLog(@"webViewDidFinishLoad");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    // TODO create an alert to notify a user of an error
    
    [self.loadingActivityIndicatorView stopAnimating];

    NSLog(@"didFailLoadWithError %@", [error localizedDescription]);
}


#pragma mark - test and prepare user's folder structure

- (void)findExistingOrCreateNewFolderForUser
{
    NSLog(@"findExistingOrCreateNewFolderForUser");

    User * newUser = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
    
    // get list of all folders from API and if there is one with the same folderId use it
    [[PPrYvApiClient sharedClient] getFoldersWithSuccessHandler:^(NSArray *folderList){
        BOOL foundFolder = NO;
        for (Folder *folder in folderList) {
            if ([folder.folderId isEqualToString:newUser.folderId]) {
                NSLog(@"Found user's folder: %@", folder.name);
                newUser.folderName = folder.name;
                [[[PPrYvCoreDataManager sharedInstance] managedObjectContext] save:nil];
                foundFolder = YES;
                break;
            }
        }
        
        if (!foundFolder) {
            NSLog(@"folder was not found, creating one: %@", newUser.folderName);
            [self createFolder];
        } else {
            
            [self.pollTimer invalidate];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    } errorHandler:^(NSError *error) {
        
        NSLog(@"couldn't receive folders %@", error);
        /*
         [[[UIAlertView alloc] initWithTitle:nil
         message:NSLocalizedString(@"alertCantGetFolderList", )
         delegate:nil
         cancelButtonTitle:NSLocalizedString(@"cancelButton", )
         otherButtonTitles:nil] show];
         */
        
    }];
}

- (void)createFolder
{
    if (self.iteration > 10) {
        
        NSLog(@"error cannot create folder despite new name");
        
        // FIXME add an alert with failure
        [self.pollTimer invalidate];
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
        return;
    }
    //  create a folder for the current user
    User * newUser = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
    
    if (self.iteration > 0) {
        newUser.folderName = [newUser.folderName stringByAppendingString:[NSString stringWithFormat:@"%u",self.iteration]];
    }
    self.iteration++;
    
    [[PPrYvApiClient sharedClient] createFolderId:newUser.folderId
                                         withName:newUser.folderName
                                   successHandler:^(NSString *folderId, NSString *folderName) {
                                       
                                       // the folder for the current iPhone openUDID did not already exist. we created it.
                                       User *currentUser = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
                                       currentUser.folderName = folderName;
                                       
                                       [[[PPrYvCoreDataManager sharedInstance] managedObjectContext] save:nil];
                                       
                                       [self.pollTimer invalidate];
                                       [self dismissViewControllerAnimated:YES completion:nil];
                                       
                                   } errorHandler:^(NSError *error) {
                                       
                                       NSLog(@"couldn't create the folder based on openUDID error %@", error);
                                       
                                       [self createFolder];
                                   }];
}

@end