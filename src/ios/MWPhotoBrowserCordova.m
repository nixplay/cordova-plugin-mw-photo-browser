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

#import <PopupDialog/PopupDialog-Swift.h>
#define LIGHT_BLUE_COLOR [UIColor colorWithRed:(99/255.0f)  green:(176/255.0f)  blue:(228.0f/255.0f) alpha:1.0]
#define OPTIONS_UIIMAGE [UIImage imageNamed:[NSString stringWithFormat:@"%@.bundle/%@", NSStringFromClass([self class]), @"images/options.png"]]
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
@synthesize rightBarbuttonItem = _rightBarbuttonItem;
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
    NSArray *captions = [options objectForKey:@"captions"];
    
    //    NSLog(@"data %@",_data);
    for (NSString* url in [options objectForKey:@"images"])
    {
        [images addObject:[MWPhoto photoWithURL:[NSURL URLWithString: url]]];
    }
    if(captions != nil){
        if([captions count] == [images count] ){
            [images enumerateObjectsUsingBlock:^(MWPhoto*  _Nonnull photo, NSUInteger idx, BOOL * _Nonnull stop) {
                photo.caption = [captions objectAtIndex:idx];
            }];
        }
        
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
    
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithImage: OPTIONS_UIIMAGE style:UIBarButtonItemStylePlain target:self action:@selector(home:)];
    newBackButton.tag = 0;
    browser.navigationItem.rightBarButtonItem = newBackButton;
    _rightBarbuttonItem = newBackButton;
    
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
    if(sender.tag == 0){
        
        //    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        __weak MWPhotoBrowserCordova *weakSelf = self;
        IBActionSheet *actionSheet = [[IBActionSheet alloc] initWithTitle:NSLocalizedString(@"Options", nil)
                                                                 callback:^(IBActionSheet *actionSheet, NSInteger buttonIndex) {
                                                                     if(buttonIndex == 0){
                                                                         if(!_browser.displaySelectionButtons){
                                                                             _browser.displaySelectionButtons = YES;
                                                                             [_browser reloadData];
                                                                             sender.tag = 1;
                                                                             [sender setImage:nil];
                                                                             [sender setTitle:NSLocalizedString(@"Cancel", nil)];
                                                                         }
                                                                         
                                                                     }else if (buttonIndex == 1){
                                                                         [weakSelf popupTextAreaDialog];
                                                                     }else if(buttonIndex > 0 && buttonIndex < actionSheet.numberOfButtons-1){
                                                                         
                                                                         NSLog(@"actionSheet %@ %li",actionSheet , (long)buttonIndex);
                                                                         NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
                                                                         IBActionSheetButton * button = [actionSheet.buttons objectAtIndex:buttonIndex];
                                                                         [dictionary setValue: button.currentTitle forKey:@"title"];
                                                                         CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary: dictionary];
                                                                         [weakSelf.commandDelegate sendPluginResult:result callbackId:_callbackId];
                                                                         
                                                                         [weakSelf buildDialogWithTitle:@"Test" text:@"Test content"];
                                                                     }else if(buttonIndex == NSNotFound){
                                                                         [actionSheet dismissWithClickedButtonIndex:-1 animated:NO];
                                                                     }
//                                                                     else{
//                                                                         
//                                                                         [actionSheet dismissWithClickedButtonIndex:0 animated:NO];
//                                                                         if(_browser.displaySelectionButtons){
//                                                                             _browser.displaySelectionButtons = NO;
//                                                                             [_browser reloadData];
//                                                                         }
//                                                                         //                                                                     if(_gridController != nil){
//                                                                         //                                                                     [_gridController  reloadData];
//                                                                         //                                                                     }
//                                                                         
//                                                                     }
                                                                 }
                                                        cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:nil, nil];
        
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Select Photos", nil)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Add Album to Playlist", nil)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit Album Name", nil)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Delete Album", nil)];
        [actionSheet setTitleTextColor:[UIColor blackColor]];
        //    [actionSheet rotateToCurrentOrientation];
        [actionSheet  showInView:_browser.navigationController.view ];
        self.actionSheet = actionSheet;
    }else{
        
        if(_browser.displaySelectionButtons){
            _browser.displaySelectionButtons = NO;
            _browser.displayActionButton = NO;
            [_browser reloadData];
            sender.tag = 0;
            [sender setImage:OPTIONS_UIIMAGE];
            [sender setTitle:nil];
        }

    }
}

-(void) buildDialogWithTitle:(NSString*) title text:(NSString*)text {
    __weak MWPhotoBrowserCordova *weakSelf = self;
    PopupDialog *popup = [[PopupDialog alloc] initWithTitle:title
                                                    message:text
                                                      image:nil
                                            buttonAlignment:UILayoutConstraintAxisHorizontal
                                            transitionStyle:PopupDialogTransitionStyleBounceUp
                                           gestureDismissal:YES
                                                 completion:nil];
    CancelButton *cancel = [[CancelButton alloc]initWithTitle:@"" height:32 dismissOnTap:YES action:^{
        
    }];
    
    DefaultButton *ok = [[DefaultButton alloc]initWithTitle:@"OK" height:32 dismissOnTap:YES action:^{
        
    }];
    
    [popup addButtons: @[cancel, ok]];
    
    [_browser.navigationController presentViewController:popup animated:YES completion:nil];

}

- (void)popupTextAreaDialog {
    
    __weak MWPhotoBrowserCordova *weakSelf = self;
//    self.dialogView =
//    [[XFDialogTextArea dialogWithTitle:@"Edit Album Name"
//                                 attrs:@{
//                                         XFDialogTitleViewBackgroundColor : [UIColor whiteColor],
//                                         XFDialogTitleColor: [UIColor blackColor],
//                                         XFDialogTitleFontSize: @(14.f),
//                                         XFDialogTitleAlignment: @(NSTextAlignmentLeft),
//                                         XFDialogTitleIsMultiLine: @(YES),
//                                         XFDialogTextAreaMargin: @(12.f),
//                                         XFDialogTextAreaHeight: @(32.0f),
//                                         XFDialogTextAreaPlaceholderKey: NSLocalizedString(@"Album Name", nil),
//                                         XFDialogTextAreaPlaceholderColorKey: [UIColor grayColor],
//                                         XFDialogTextAreaHintColor: [UIColor grayColor],
//                                         XFDialogLineColor: [UIColor grayColor],
//                                         XFDialogTextAreaFontSize: @(15),
//                                         XFDialogCancelButtonTitle: NSLocalizedString(@"Cancel", nil),
//                                         XFDialogCommitButtonTitle: NSLocalizedString(@"Confirm", nil)
//                                         }
//                        commitCallBack:^(NSString *inputText) {
//                            [weakSelf.dialogView hideWithAnimationBlock:nil];
////                            [XFUITool showToastWithTitle:[NSString stringWithFormat:@"输入的内容是: %@",inputText] complete:nil];
//                        }
//                         errorCallBack:^(NSString *errorMessage) {
//                             
//                         }] showWithAnimationBlock:nil];
//    [self.dialogView setCancelCallBack:^{
////        NSLog(@"用户取消输入！");
//    }];
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
    if(_rightBarbuttonItem != nil){
        photoBrowser.navigationItem.rightBarButtonItem = _rightBarbuttonItem;
        [photoBrowser.navigationItem.rightBarButtonItem setAction:@selector(home:)];
        [photoBrowser.navigationItem.rightBarButtonItem setTarget:self];
    }
    return YES;
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser hideGridController:(MWGridViewController*)gridController{
    _gridViewController = nil;
//    _rightBarbuttonItem = photoBrowser.navigationItem.rightBarButtonItem;
    photoBrowser.navigationItem.rightBarButtonItem = nil;
    
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
