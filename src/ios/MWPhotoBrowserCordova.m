//
//  ImageViewer.m
//  Helper
//
//  Created by Calvin Lai on 7/11/13.
//
//

#import "MWPhotoBrowserCordova.h"
#import "MWPhotoBrowser.h"
#import "MWGridViewController.h"
#import <Cordova/CDVViewController.h>
#import "IBActionSheet.h"
#import "UIImage+MWPhotoBrowser.h"
#import <Cordova/CDVPlugin+Resources.h>
// #import <Cordova/CDVDebug.h>
#import "XFDialogBuilder.h"


@implementation MWPhotoBrowserCordova
@synthesize callbackId = _callbackId;
@synthesize callbackIds = _callbackIds;
@synthesize photos = _photos;
@synthesize thumbs = _thumbs;
@synthesize browser = _browser;
@synthesize data = _data;
@synthesize actionSheet = _actionSheet;
@synthesize navigationController = _navigationController;
@synthesize albumName = _albumName;
@synthesize gridViewController = _gridViewController;
- (NSMutableDictionary*)callbackIds {
    if(_callbackIds == nil) {
        _callbackIds = [[NSMutableDictionary alloc] init];
    }
    return _callbackIds;
}

- (void)showGallery:(CDVInvokedUrlCommand*)command {
    NSLog(@"showGalleryWith:%@", command.arguments);
    
    _callbackId = command.callbackId;
    [self.callbackIds setValue:command.callbackId forKey:@"showGallery"];
    
    NSDictionary *options = [command.arguments objectAtIndex:0];
    NSMutableArray *images = [[NSMutableArray alloc] init];
    NSMutableArray *thumbs = [[NSMutableArray alloc] init];
    NSUInteger photoIndex = [[options objectForKey:@"index"] intValue];
    _data = [options objectForKey:@"data"];
    _albumName = [options objectForKey:@"albumName"];
    
    //    NSLog(@"data %@",_data);
    for (NSString* url in [options objectForKey:@"images"])
    {
        [images addObject:[MWPhoto photoWithURL:[NSURL URLWithString: url]]];
    }
    for (NSString* url in [options objectForKey:@"thumbnails"])
    {
        [thumbs addObject:[MWPhoto photoWithURL:[NSURL URLWithString: url]]];
    }
    
    self.photos = images;
    if([thumbs count] == 0){
        self.thumbs = self.photos;
    }else{
        self.thumbs = thumbs;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrientationChanged:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    
    
    
    // Create & present browser
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate: self];
    _browser = browser;
    // Set options
    //    browser.wantsFullScreenLayout = NO; // Decide if you want the photo browser full screen, i.e. whether the status bar is affected (defaults to YES)
    browser.displayActionButton = NO; // Show action button to save, copy or email photos (defaults to NO)
    browser.startOnGrid = YES;
    browser.enableGrid = YES;
    browser.displayNavArrows = NO;
    
    [browser setCurrentPhotoIndex: photoIndex]; // Example: allows second image to be presented first
    
    // Modal
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
    _navigationController = nc;
    NSString* resourceIdentifier = [NSString stringWithFormat:@"%@.bundle/%@", NSStringFromClass([self class]), @"images/options.png"];
    
    [UIImage imageNamed:resourceIdentifier];
    
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithImage: [UIImage imageNamed:resourceIdentifier] style:UIBarButtonItemStylePlain target:self action:@selector(home:)];
    browser.navigationItem.rightBarButtonItem = newBackButton;
    
    
    _navigationController.delegate = self;
    
    CATransition *transition = [[CATransition alloc] init];
    transition.duration = 0.35;
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    [self.viewController.view.window.layer addAnimation:transition forKey:kCATransition];
    [self.viewController presentViewController:nc animated:NO completion:^{
        
    }];
    //    [self.viewController presentViewController:nc animated:YES completion:nil];
    
    //[nc release];
    
    // Release
    //[browser release];
    //[images release];
    
    
    
}

-(void)home:(UIBarButtonItem *)sender
{
    //    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    __weak MWPhotoBrowserCordova *weakSelf = self;
    IBActionSheet *actionSheet = [[IBActionSheet alloc] initWithTitle:NSLocalizedString(@"Options", nil)
                                                             callback:^(IBActionSheet *actionSheet, NSInteger buttonIndex) {
                                                                 if(buttonIndex > 0 &&buttonIndex < actionSheet.numberOfButtons){
                                                                     
                                                                     NSLog(@"actionSheet %@ %li",actionSheet , (long)buttonIndex);
                                                                     NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
                                                                     IBActionSheetButton * button = [actionSheet.buttons objectAtIndex:buttonIndex];
                                                                     [dictionary setValue: button.currentTitle forKey:@"title"];
                                                                     CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary: dictionary];
                                                                     [self.commandDelegate sendPluginResult:result callbackId:_callbackId];
                                                                     
                                                                     [self buildDialogWithTitle:@"Test" text:@"Test content"];
                                                                 }
                                                                 else if(buttonIndex == 0){
                                                                     if(!_browser.displaySelectionButtons){
                                                                         _browser.displaySelectionButtons = YES;
                                                                         [_browser reloadData];
                                                                     }

//                                                                     if(_gridController != nil){
//                                                                         [_gridController reloadData];
                                                                     
//                                                                     }
                                                                     
                                                                 }else{
                                                                     
                                                                     [actionSheet dismissWithClickedButtonIndex:0 animated:NO];
                                                                     if(_browser.displaySelectionButtons){
                                                                         _browser.displaySelectionButtons = NO;
                                                                         [_browser reloadData];
                                                                     }
//                                                                     if(_gridController != nil){
//                                                                     [_gridController  reloadData];
//                                                                     }
                                                                     
                                                                 }
                                                             }
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil, nil];
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Select Photos", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Add Album to Playlist", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit Album Name", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Delete Album", nil)];
    [actionSheet setTitleTextColor:[UIColor blackColor]];
//    [actionSheet rotateToCurrentOrientation];
    [actionSheet  showInView:_navigationController.view ];
    self.actionSheet = actionSheet;
}

-(void) buildDialogWithTitle:(NSString*) title text:(NSString*)text {
    __weak MWPhotoBrowserCordova *weakSelf = self;
    self.dialogView =
    [[[XFDialogNotice dialogWithTitle:title
                                attrs:@{
                                        XFDialogTitleViewBackgroundColor : [UIColor grayColor],
                                        XFDialogNoticeText:text,
                                        XFDialogLineColor : [UIColor darkGrayColor],
                                        }
                       commitCallBack:^(NSString *inputText) {
                           [weakSelf.dialogView hideWithAnimationBlock:nil];
                       }] showWithAnimationBlock:nil] setCancelCallBack:^{
                           
                       }];

}
-(void) onOrientationChanged:(UIInterfaceOrientation) orientation{
    if(_actionSheet != nil)
        [_actionSheet rotateToCurrentOrientation];
}

// -(void)action:(UIBarButtonItem *)sender
// {
//     _browser.displaySelectionButtons = !_browser.displaySelectionButtons;
//     [_browser setNeedsFocusUpdate];
//     NSLog(@"action %@",sender);
// }


#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    if([viewController isKindOfClass:[MWPhotoBrowser class] ]){
        // UIBarButtonItem *newActionButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"action", nil) style:UIBarButtonItemStylePlain target:self action:@selector(action:)];
        // viewController.navigationItem.rightBarButtonItem = newActionButton;
        
    }
    //else{
    //        [self.viewController dismissViewControllerAnimated:YES completion:nil];
    //    }
}


#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _photos.count;
}

- (MWPhoto *)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count)
        return [_photos objectAtIndex:index];
    return nil;
}
- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index{
    MWPhoto *photo = [self.thumbs objectAtIndex:index];
    return photo;
}
- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index {
    MWPhoto *photo = [self.photos objectAtIndex:index];
    MWCaptionView *captionView = [[MWCaptionView alloc] initWithPhoto:photo];
    return captionView;
}

-(void) photoBrowserDidFinishModalPresentation:(MWPhotoBrowser*) browser{
    [browser dismissViewControllerAnimated:YES completion:nil];
}

//- (NSString *)photoBrowser:(MWPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index{
//}
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index{
    NSLog(@"didDisplayPhotoAtIndex %lu", (unsigned long)index);
}
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index{
    NSLog(@"actionButtonPressedForPhotoAtIndex %lu", (unsigned long)index);
}
//- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index{}
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected{
    NSLog(@"photoAtIndex %lu selectedChanged %i", (unsigned long)index , selected);
}
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser showGridController:(MWGridViewController*)gridController{
    _gridViewController = gridController;
    return YES;
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser hideGridController:(MWGridViewController*)gridController{
    _gridViewController = nil;
    return YES;
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser setNavBarAppearance:(UINavigationBar *)navigationBar{
    
    //    UINavigationBar *navBar = self.navigationController.navigationBar;
    //    navBar.tintColor = [UIColor whiteColor];
    //    navBar.barTintColor = nil;
//    navigationBar.shadowImage = nil;
//    navigationBar.translucent = NO;
    photoBrowser.navigationItem.title = (_albumName != nil ) ? _albumName : @"Albums";
    navigationBar.barStyle = UIBarStyleDefault;
    [navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
//    [navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsLandscapePhone];
    return YES;
}

-(BOOL) photoBrowserSelectionMode{
    return _browser.displaySelectionButtons;
}
@end
