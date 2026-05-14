#import <UIKit/UIKit.h>

// --- interfaces para evitar warnings/errores de compilación ---
@interface WAMenuItemCell : UITableViewCell
@end

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

// --- CONFIGURACIÓN DEL CABEZAL (BANNER Y AVATAR) ---
- (void)setupHeaderView {
    UIView *headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 220)];
    headerContainer.backgroundColor = [UIColor clearColor];
    
    // Banner Rojo/Negro de fondo
    self.headerBannerView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, headerContainer.frame.size.width, 140)];
    self.headerBannerView.contentMode = UIViewContentModeScaleAspectFill;
    self.headerBannerView.clipsToBounds = YES;
    self.headerBannerView.image = [UIImage imageNamed:@"domidios_banner"];
    self.headerBannerView.backgroundColor = [UIColor blackColor];
    [headerContainer addSubview:self.headerBannerView];
    
    // Contenedor del Avatar (Círculo)
    self.avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 100, 80, 80)];
    self.avatarImageView.layer.cornerRadius = 40;
    self.avatarImageView.layer.borderWidth = 3.0;
    self.avatarImageView.layer.borderColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.07 alpha:1.0].CGColor;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.image = [UIImage imageNamed:@"domidios_avatar"];
    [headerContainer addSubview:self.avatarImageView];
    
    // Indicador En Línea (Punto Verde)
    self.onlineStatusDot = [[UIView alloc] initWithFrame:CGRectMake(82, 162, 14, 14)];
    self.onlineStatusDot.backgroundColor = [UIColor colorWithRed:0.20 green:0.78 blue:0.35 alpha:1.0];
    self.onlineStatusDot.layer.cornerRadius = 7;
    self.onlineStatusDot.layer.borderWidth = 2.0;
    self.onlineStatusDot.layer.borderColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.07 alpha:1.0].CGColor;
    [headerContainer addSubview:self.onlineStatusDot];
    
    // Etiqueta del Nombre (saint iOS)
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 185, headerContainer.frame.size.width - 40, 30)];
    self.nameLabel.text = @"saint iOS";
    self.nameLabel.textColor = [UIColor whiteColor];
    self.nameLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    [headerContainer addSubview:self.nameLabel];
    
    self.tableView.tableHeaderView = headerContainer;
}

#pragma mark - UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

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
    }
    else if (indexPath.section == 1) {
        cell.textLabel.text = @"Theme Settings";
        cell.detailTextLabel.text = @"Colors, icons, layout";
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        cell.imageView.image = [UIImage systemImageNamed:@"gearshape.fill"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (indexPath.section == 2) {
        cell.textLabel.text = @"About";
        cell.detailTextLabel.text = @"Developer, version, info";
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        cell.imageView.image = [UIImage systemImageNamed:@"info.circle.fill"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 10.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

// ============================================================================
// INYECTOR AUTOMÁTICO (CONSTRUCTOR NATIVO)
// Esto hace que la vista se muestre sola sin tocar otros archivos del proyecto
// ============================================================================
__attribute__((constructor)) static void inicializarMenuDomidios() {
    // Espera 2.5 segundos tras abrir la app para asegurar que WhatsApp cargó su interfaz base
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *windowPrincipal = nil;
        
        // Buscar la ventana activa en pantalla
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    for (UIWindow *window in scene.windows) {
                        if (window.isKeyWindow) {
                            windowPrincipal = window;
                            break;
                        }
                    }
                }
            }
        }
        
        // Si no se encuentra con el método moderno, usar el método clásico (compatibilidad iOS 12)
        if (!windowPrincipal) {
            for (UIWindow *window in [UIApplication sharedApplication].windows) {
                if (window.isKeyWindow) {
                    windowPrincipal = window;
                    break;
                }
            }
        }
        
        // Presentar el menú encima de la vista actual de WhatsApp
        if (windowPrincipal && windowPrincipal.rootViewController) {
            UIViewController *rootVC = windowPrincipal.rootViewController;
            
            // Si ya hay algo presentado en pantalla, buscar el controlador visible más alto
            while (rootVC.presentedViewController) {
                rootVC = rootVC.presentedViewController;
            }
            
            DOMIDIOSProfileViewController *profileVC = [[DOMIDIOSProfileViewController alloc] init];
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:profileVC];
            navController.modalPresentationStyle = UIModalPresentationFullScreen;
            
            [rootVC presentViewController:navController animated:YES completion:nil];
        }
    });
}
