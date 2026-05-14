#import <UIKit/UIKit.h>

@interface ProfileViewController : UIViewController
@property (nonatomic, strong) UIView *containerView;
@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    
    // Crear el contenedor principal estilo tarjeta (como en image_2.png)
    self.containerView = [[UIView alloc] initWithFrame:CGRectMake(20, 100, self.view.frame.size.width - 40, 500)];
    self.containerView.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.14 alpha:1.0];
    self.containerView.layer.cornerRadius = 20;
    self.containerView.clipsToBounds = YES;
    [self.view addSubview:self.containerView];
    
    // Header con imagen (Banner rojo de image_2.png)
    UIImageView *banner = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.containerView.frame.size.width, 120)];
    banner.backgroundColor = [UIColor darkGrayColor]; 
    banner.contentMode = UIViewContentModeScaleAspectFill;
    // banner.image = [UIImage imageNamed:@"tu_banner_rojo"]; 
    [self.containerView addSubview:banner];

    // Foto de perfil circular
    UIImageView *profilePic = [[UIImageView alloc] initWithFrame:CGRectMake(20, 90, 60, 60)];
    profilePic.layer.cornerRadius = 30;
    profilePic.layer.borderWidth = 3;
    profilePic.layer.borderColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.14 alpha:1.0].CGColor;
    profilePic.backgroundColor = [UIColor grayColor];
    profilePic.clipsToBounds = YES;
    [self.containerView addSubview:profilePic];

    // Nombre de usuario: saint iOS
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 155, 200, 30)];
    nameLabel.text = @"saint iOS ✎";
    nameLabel.textColor = [UIColor whiteColor];
    nameLabel.font = [UIFont boldSystemFontOfSize:22];
    [self.containerView addSubview:nameLabel];

    // --- SECCIÓN DE DATOS (UDID, KEY, EXPIRATION) ---
    
    [self addInfoRowWithIcon:@"🖥" title:@"UDID" value:@"••••••••-••••••••••••••••" yOffset:200];
    [self addInfoRowWithIcon:@"🔒" title:@"KEY" value:@"ABC-123-XYZ" yOffset:260];
    [self addInfoRowWithIcon:@"📅" title:@"EXPIRATION" value:@"27/01/2029" yOffset:320];

    // Botón de Cerrar
    UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(15, 15, 35, 35)];
    [closeBtn setTitle:@"<" forState:UIControlStateNormal];
    [closeBtn setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.5]];
    closeBtn.layer.cornerRadius = 17.5;
    [closeBtn addTarget:self action:@selector(dismissProfile) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:closeBtn];
}

- (void)addInfoRowWithIcon:(NSString *)icon title:(NSString *)title value:(NSString *)value yOffset:(CGFloat)y {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(20, y, self.containerView.frame.size.width - 40, 50)];
    
    UILabel *iconLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 30, 30)];
    iconLabel.text = icon;
    [row addSubview:iconLabel];
    
    UILabel *tLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 5, 200, 15)];
    tLabel.text = title;
    tLabel.font = [UIFont systemFontOfSize:10];
    tLabel.textColor = [UIColor lightGrayColor];
    [row addSubview:tLabel];
    
    UILabel *vLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 20, 250, 20)];
    vLabel.text = value;
    vLabel.font = [UIFont systemFontOfSize:14];
    vLabel.textColor = [UIColor whiteColor];
    [row addSubview:vLabel];
    
    [self.containerView addSubview:row];
}

- (void)dismissProfile {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end

// Hook para añadir el botón en la interfaz de WhatsApp (arriba a la derecha)
%hook WAChatViewController

- (void)viewDidLoad {
    %orig;
    
    UIButton *profileBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    profileBtn.frame = CGRectMake(0, 0, 40, 40);
    [profileBtn setImage:[UIImage systemImageNamed:@"person.circle.fill"] forState:UIControlStateNormal];
    [profileBtn addTarget:self action:@selector(openCustomProfile) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:profileBtn];
    self.navigationItem.rightBarButtonItems = [self.navigationItem.rightBarButtonItems arrayByAddingObject:item];
}

%new
- (void)openCustomProfile {
    ProfileViewController *vc = [[ProfileViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}
%end
