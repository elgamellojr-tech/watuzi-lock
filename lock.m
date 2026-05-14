#import <UIKit/UIKit.h>

// --- TRANSPARENCIA EN LA BARRA SUPERIOR (NAV BAR) ---
// Hookeamos el controlador del chat para modificar la barra de navegación
%hook WAChatViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    
    // Accedemos a la barra de navegación
    UINavigationBar *navBar = self.navigationController.navigationBar;
    
    // Eliminamos el fondo y la línea divisoria
    [navBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [navBar setShadowImage:[UIImage new]];
    [navBar setTranslucent:YES];
    [navBar setBackgroundColor:[UIColor clearColor]];
    
    // Forzamos a que el contenido del chat suba hasta arriba de la pantalla
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = YES;
}

%end

// --- TRANSPARENCIA EN LA BARRA DE ESCRITURA (INPUT BAR) ---
// Hookeamos la vista de entrada de mensajes
%hook WAMessageInputView

- (void)layoutSubviews {
    %orig;
    
    // Hacemos el fondo de la vista transparente
    [self setBackgroundColor:[UIColor clearColor]];
    [self setOpaque:NO];

    // Buscamos y ocultamos el fondo difuminado (UIVisualEffectView) que usa WhatsApp
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:NSClassFromString(@"UIVisualEffectView")] || 
            [subview isKindOfClass:NSClassFromString(@"_UIBarBackground")]) {
            [subview setHidden:YES];
            [subview setAlpha:0.0];
        }
    }
}

%end

// --- COMPATIBILIDAD CON EL CONTENEDOR DE LA BARRA ---
%hook WAMessageInputContainerView
- (void)layoutSubviews {
    %orig;
    [self setBackgroundColor:[UIColor clearColor]];
    [self setOpaque:NO];
}
%end
