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
    self.view.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.07 alpha:1.0]; // Fondo oscuro Premium
    
    // Configurar la Tabla
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone; // Estilo limpio sin líneas feas
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
    self.headerBannerView.image = [UIImage imageNamed:@"domidios_banner"]; // Asegúrate de tenerlo en tus Assets
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
    return 3; // Sección 1: Licencia (UDID/Key/Exp) | Sección 2: Themes | Sección 3: About
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 3; // UDID, KEY, EXPIRATION
    if (section == 1) return 1; // Theme Settings
    if (section == 2) return 1; // About
    return 0
