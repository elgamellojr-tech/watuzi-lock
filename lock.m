#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// --- interfaces para evitar warnings/errores de compilación ---
@interface DOMIDIOSProfileViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIImageView *headerBannerView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIView *onlineStatusDot;
@end

@implementation DOMIDIOSProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Profile";
    self.view.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.07 alpha:1.0];
    
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
    [headerContainer addSubview:self.avatarImageView];
    
    self.onlineStatusDot = [[UIView alloc] initWithFrame:CGRectMake(82, 162, 14, 14)];
    self.onlineStatusDot.backgroundColor = [UIColor colorWithRed:0.20 green:0.78 blue:0.35 alpha:1.0];
    self.onlineStatusDot.layer.cornerRadius = 7;
    self.onlineStatusDot.layer.borderWidth = 2.0;
    self.onlineStatusDot.layer.borderColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.07 alpha:1.0].CGColor;
    [headerContainer addSubview:self.onlineStatusDot];
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 185, headerContainer.frame.size.width - 40, 30)];
    self.nameLabel.text = @"saint iOS";
    self.nameLabel.textColor = [UIColor whiteColor];
    self.nameLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    [headerContainer addSubview:self.nameLabel];
    
    self.tableView.tableHeaderView = headerContainer;
}

#pragma mark - UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 3; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 3;
    if (section == 1) return 1;
    if (section == 2) return 1;
    return 0;
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
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"UDID";
            cell.detailTextLabel.text = @"••••••••-••••••••••••••••";
            cell.imageView.image = [UIImage systemImageNamed:@"ipad.and.iphone"];
            
            UIButton *revealBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [revealBtn setImage:[UIImage systemImageNamed:@"eye.slash"] forState:UIControlStateNormal];
            revealBtn.frame = CGRectMake(0, 0, 25, 25);
            revealBtn.tintColor = [UIColor grayColor];
            cell.accessoryView = revealBtn;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"KEY";
            cell.detailTextLabel.text = @"•••••";
            cell.imageView.image = [UIImage systemImageNamed:@"lock.fill"];
            
            UIButton *revealBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [revealBtn setImage:[UIImage systemImageNamed:@"eye.slash"] forState:UIControlStateNormal];
            revealBtn.frame = CGRectMake(0, 0, 25, 25);
            revealBtn.tintColor = [UIColor grayColor];
            cell.accessoryView = revealBtn;
        } else if (indexPath.row == 2) {
            cell.textLabel.text = @"EXPIRATION";
            cell.detailTextLabel.text = @"27/01/2029";
            cell.imageView.image = [UIImage systemImageNamed:@"calendar"];
            
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
    } else if (indexPath.section == 1) {
        cell.textLabel.text = @"Theme Settings";
        cell.detailTextLabel.text = @"Colors, icons, layout";
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        cell.imageView.image = [UIImage systemImageNamed:@"gearshape.fill"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.section == 2) {
        cell.textLabel.text = @"About";
        cell.detailTextLabel.text = @"Developer, version, info";
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        cell.imageView.image = [UIImage systemImageNamed:@"info.circle.fill"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath { return 60.0; }
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section { return 10.0; }
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section { return 0.1; }
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { [tableView deselectRowAtIndexPath:indexPath animated:YES]; }
@end


// ============================================================================
// SWIZZLING DIRECTO (HOOK AUTOMÁTICO DESDE OBJC RUNTIME)
// ============================================================================

static void (*original_viewDidAppear)(id, SEL, BOOL);

void custom_viewDidAppear(id self, SEL _cmd, BOOL animated) {
    // 1. Ejecuta el viewDidAppear original de WhatsApp
    original_viewDidAppear(self, _cmd, animated);
    
    // 2. Ejecutar nuestra inyección en hilos seguros solo una vez para que no se duplique infinitamente
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIViewController *currentVC = (UIViewController *)self;
        
        // Creamos tu interfaz DOMIDIOS
        DOMIDIOSProfileViewController *profileVC = [[DOMIDIOSProfileViewController alloc] init];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:profileVC];
        navController.modalPresentationStyle = UIModalPresentationFullScreen;
        
        // La forzamos a aparecer inmediatamente sobre la primera pantalla que cargue la app
        [currentVC presentViewController:navController animated:YES completion:nil];
    });
}

__attribute__((constructor)) static void initInyectorForzado() {
    // Interceptamos la clase base de las pantallas de carga de WhatsApp
    Class targetClass = NSClassFromString(@"WAVisualEffectsController");
    if (!targetClass) {
        targetClass = NSClassFromString(@"WAMainViewController");
    }
    
    // Si la app usa estructuras distintas, agarramos la pantalla base universal de iOS (UITabBarController)
    if (!targetClass) {
        targetClass = [UITabBarController class];
    }
    
    SEL originalSelector = @selector(viewDidAppear:);
    Method originalMethod = class_getInstanceMethod(targetClass, originalSelector);
    
    // Reemplazamos el método nativo por el nuestro
    original_viewDidAppear = (void *)method_getImplementation(originalMethod);
    method_setImplementation(originalMethod, (IMP)custom_viewDidAppear);
}
