#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// --- Instancia global del botón flotante ---
static UIButton *floatingMenuButton = nil;

@interface DOMIDIOSProfileViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIImageView *headerBannerView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIView *onlineStatusDot;

// Variables persistentes para el cambio visual en caliente
@property (nonatomic, strong) NSString *currentVisualName;
@property (nonatomic, strong) UIColor *currentVisualAvatarColor;
@end

@implementation DOMIDIOSProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Inicializar valores por defecto si están vacíos
    if (!self.currentVisualName) self.currentVisualName = @"saint iOS";
    if (!self.currentVisualAvatarColor) self.currentVisualAvatarColor = [UIColor colorWithRed:0.18 green:0.18 blue:0.20 alpha:1.0];
    
    self.title = @"DOMIDIOS MENU";
    self.view.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.07 alpha:1.0];
    
    // Botón nativo superior para cerrar el menú y regresar a WhatsApp
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Minimize" 
                                                                    style:UIBarButtonItemStyleDone 
                                                                   target:self 
                                                                   action:@selector(dismissMenu)];
    closeButton.tintColor = [UIColor redColor];
    self.navigationItem.rightBarButtonItem = closeButton;
    
    // Configurar la Tabla
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    
    [self setupHeaderView];
}

- (void)dismissMenu {
    [self dismissViewControllerAnimated:YES completion:^{
        // Volver a mostrar el botón flotante al cerrar la interfaz completa
        if (floatingMenuButton) {
            floatingMenuButton.hidden = NO;
        }
    }];
}

- (void)setupHeaderView {
    UIView *headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 220)];
    headerContainer.backgroundColor = [UIColor clearColor];
    
    self.headerBannerView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, headerContainer.frame.size.width, 140)];
    self.headerBannerView.contentMode = UIViewContentModeScaleAspectFill;
    self.headerBannerView.clipsToBounds = YES;
    self.headerBannerView.backgroundColor = [UIColor blackColor];
    [headerContainer addSubview:self.headerBannerView];
    
    self.avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 100, 80, 80)];
    self.avatarImageView.layer.cornerRadius = 40;
    self.avatarImageView.layer.borderWidth = 3.0;
    self.avatarImageView.layer.borderColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.07 alpha:1.0].CGColor;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.backgroundColor = self.currentVisualAvatarColor;
    [headerContainer addSubview:self.avatarImageView];
    
    self.onlineStatusDot = [[UIView alloc] initWithFrame:CGRectMake(82, 162, 14, 14)];
    self.onlineStatusDot.backgroundColor = [UIColor colorWithRed:0.20 green:0.78 blue:0.35 alpha:1.0];
    self.onlineStatusDot.layer.cornerRadius = 7;
    self.onlineStatusDot.layer.borderWidth = 2.0;
    self.onlineStatusDot.layer.borderColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.07 alpha:1.0].CGColor;
    [headerContainer addSubview:self.onlineStatusDot];
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 185, headerContainer.frame.size.width - 40, 30)];
    self.nameLabel.text = self.currentVisualName;
    self.nameLabel.textColor = [UIColor whiteColor];
    self.nameLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    [headerContainer addSubview:self.nameLabel];
    
    self.tableView.tableHeaderView = headerContainer;
}

#pragma mark - UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { 
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 2;
    if (section == 1) return 3;
    if (section == 2) return 1;
    if (section == 3) return 1;
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"VISUAL MODIFICATIONS (ONLY)";
    if (section == 1) return @"LICENSE INFOMATION";
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
        header.textLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
        header.textLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"DOMIDIOSCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1.0];
        cell.layer.cornerRadius = 12;
        cell.textLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        cell.textLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
        cell.detailTextLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.imageView.image = nil;
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"PROFILE NAME";
            cell.detailTextLabel.text = self.currentVisualName;
            if (@available(iOS 13.0, *)) {
                cell.imageView.image = [UIImage systemImageNamed:@"pencil.circle.fill"];
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"PROFILE PICTURE";
            cell.detailTextLabel.text = @"Tap to Change Avatar Color (Visual)";
            if (@available(iOS 13.0, *)) {
                cell.imageView.image = [UIImage systemImageNamed:@"person.crop.circle.badge.plus"];
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"UDID";
            cell.detailTextLabel.text = @"••••••••-••••••••••••••••";
            if (@available(iOS 13.0, *)) {
                cell.imageView.image = [UIImage systemImageNamed:@"ipad.and.iphone"];
            }
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"KEY";
            cell.detailTextLabel.text = @"•••••";
            if (@available(iOS 13.0, *)) {
                cell.imageView.image = [UIImage systemImageNamed:@"lock.fill"];
            }
        } else if (indexPath.row == 2) {
            cell.textLabel.text = @"EXPIRATION";
            cell.detailTextLabel.text = @"27/01/2029";
            if (@available(iOS 13.0, *)) {
                cell.imageView.image = [UIImage systemImageNamed:@"calendar"];
            }
            
            UILabel *statusBadge = [[UILabel alloc] init];
            statusBadge.text = @"  Active  ";
            statusBadge.textColor = [UIColor colorWithRed:0.20 green:0.78 blue:0.35 alpha:1.0];
            statusBadge.backgroundColor = [UIColor colorWithRed:0.20 green:0.78 blue:0.35 alpha:0.15];
            statusBadge.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
            statusBadge.layer.cornerRadius = 6;
            statusBadge.clipsToBounds = YES;
            [statusBadge sizeToFit];
            
            CGRect frame = statusBadge.frame;
            frame.size.height = 24;
            statusBadge.frame = frame;
            cell.accessoryView = statusBadge;
        }
    } 
    else if (indexPath.section == 2) {
        cell.textLabel.text = @"Theme Settings";
        cell.detailTextLabel.text = @"Colors, icons, layout";
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"gearshape.fill"];
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.section == 3) {
        cell.textLabel.text = @"About";
        cell.detailTextLabel.text = @"Developer, version, info";
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"info.circle.fill"];
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath { return 60.0; }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Change Name" 
                                                                       message:@"Enter fake profile name (Visual Only)" 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = self.currentVisualName;
            textField.placeholder = @"e.g. DOMIDIOS VIP";
        }];
        
        UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Apply" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UITextField *input = alert.textFields.firstObject;
            if (input.text.length > 0) {
                self.currentVisualName = input.text;
                self.nameLabel.text = input.text;
                [self.tableView reloadData];
            }
        }];
        
        [alert addAction:confirm];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if (indexPath.section == 0 && indexPath.row == 1) {
        static int colorIndex = 0;
        colorIndex++;
        
        // Alternar colores puros de UIKit directamente para no requerir CoreGraphics en Clang
        UIColor *newColor = [UIColor colorWithRed:0.18 green:0.18 blue:0.20 alpha:1.0];
        if (colorIndex % 3 == 1) {
            newColor = [UIColor systemRedColor];
        } else if (colorIndex % 3 == 2) {
            newColor = [UIColor systemPurpleColor];
        }
        
        self.currentVisualAvatarColor = newColor;
        self.avatarImageView.backgroundColor = newColor;
        [self.tableView reloadData];
    }
}
@end


// ============================================================================
// CONSTRUCTOR FLOTANTE & ARRASTRABLE (SWIZZLING NATIVO)
// ============================================================================

static void handlePanGesture(UIPanGestureRecognizer *sender) {
    UIView *piece = floatingMenuButton;
    if (!piece) return;
    [piece.superview bringSubviewToFront:piece];
    CGPoint translation = [sender translationInView:piece.superview];
    
    if ([sender state] == UIGestureRecognizerStateChanged) {
        piece.center = CGPointMake(piece.center.x + translation.x, piece.center.y + translation.y);
        // Reseteo nativo manual equivalente a CGPointZero sin usar la macro del linker
        [sender setTranslation:CGPointTranslate(CGPointZero, 0, 0) inView:piece.superview];
    }
}

static void floatingButtonTapped() {
    UIWindow *windowPrincipal = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) { windowPrincipal = window; break; }
                }
            }
        }
    }
    if (!windowPrincipal) {
        windowPrincipal = [UIApplication sharedApplication].keyWindow;
    }
    
    UIViewController *rootVC = windowPrincipal.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    
    if (floatingMenuButton) {
        floatingMenuButton.hidden = YES;
    }
    
    DOMIDIOSProfileViewController *profileVC = [[DOMIDIOSProfileViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:profileVC];
    navController.modalPresentationStyle = UIModalPresentationFullScreen;
    [rootVC presentViewController:navController animated:YES completion:nil];
}

static void (*original_viewDidAppear)(id, SEL, BOOL);

void custom_viewDidAppear(id self, SEL _cmd, BOOL animated) {
    original_viewDidAppear(self, _cmd, animated);
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIViewController *currentVC = (UIViewController *)self;
        
        floatingMenuButton = [UIButton buttonWithType:UIButtonTypeCustom];
        floatingMenuButton.frame = CGRectMake(currentVC.view.frame.size.width - 75, currentVC.view.frame.size.height - 160, 55, 55);
        floatingMenuButton.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:0.9];
        floatingMenuButton.layer.cornerRadius = 27.5;
        floatingMenuButton.layer.shadowColor = [UIColor blackColor].CGColor;
        floatingMenuButton.layer.shadowOpacity = 0.5;
        floatingMenuButton.layer.shadowOffset = CGSizeMake(0, 3);
        floatingMenuButton.layer.borderWidth = 1.5;
        floatingMenuButton.layer.borderColor = [UIColor colorWithRed:0.20 green:0.20 blue:0.22 alpha:1.0].CGColor;
        
        if (@available(iOS 13.0, *)) {
            [floatingMenuButton setImage:[UIImage systemImageNamed:@"gearshape.fill"] forState:UIControlStateNormal];
        }
        floatingMenuButton.tintColor = [UIColor whiteColor];
        
        [floatingMenuButton addTarget:self action:@selector(floatingButtonAction) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:currentVC action:@selector(handlePanAction:)];
        [floatingMenuButton addGestureRecognizer:panGesture];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIWindow *keyWin = [UIApplication sharedApplication].keyWindow;
            if (keyWin) {
                [keyWin addSubview:floatingMenuButton];
            }
        });
    });
}

void dynamic_floatingButtonAction(id self, SEL _cmd) {
    floatingButtonTapped();
}

void dynamic_handlePanAction(id self, SEL _cmd, UIPanGestureRecognizer *sender) {
    handlePanGesture(sender);
}

__attribute__((constructor)) static void initInyectorForzado() {
    Class targetClass = NSClassFromString(@"WAVisualEffectsController");
    if (!targetClass) targetClass = NSClassFromString(@"WAMainViewController");
    if (!targetClass) targetClass = [UITabBarController class];
    
    class_addMethod(targetClass, @selector(floatingButtonAction), (IMP)dynamic_floatingButtonAction, "v@:");
    class_addMethod(targetClass, @selector(handlePanAction:), (IMP)dynamic_handlePanAction, "v@:@");
    
    SEL originalSelector = @selector(viewDidAppear:);
    Method originalMethod = class_getInstanceMethod(targetClass, originalSelector);
    
    original_viewDidAppear = (void *)method_getImplementation(originalMethod);
    method_setImplementation(originalMethod, (IMP)custom_viewDidAppear);
}
