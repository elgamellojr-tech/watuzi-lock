#import <UIKit/UIKit.h>

%hook WABubbleView

- (void)layoutSubviews {
    %orig;

    // Obtenemos el color que el tema tiene asignado actualmente
    // 'tintColor' suele heredar el color del tema activo en WhatsApp
    UIColor *themeColor = self.tintColor;
    
    // Determinamos si es enviado o recibido por la posición
    BOOL isOutgoing = (self.frame.origin.x > 60);

    // Fondo con transparencia dinámica basado en el color del tema
    // Si prefieres fondo oscuro siempre, deja [UIColor blackColor]
    self.layer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4].CGColor;
    
    self.layer.borderWidth = 1.6;
    self.layer.cornerRadius = 14;
    self.layer.masksToBounds = YES;

    if (isOutgoing) {
        // El borde toma el color del tema actual (el que elijas en ajustes)
        self.layer.borderColor = themeColor.CGColor;
    } else {
        // Para recibidos, un gris adaptativo que funciona con modo claro/oscuro
        self.layer.borderColor = [[UIColor grayColor] colorWithAlphaComponent:0.5].CGColor;
    }

    // Forzar la eliminación de la cola del mensaje (estilo Reva)
    if ([self respondsToSelector:@selector(setTailStyle:)]) {
        [self setValue:@0 forKey:@"tailStyle"];
    }
}

%end

// Hook para asegurar que el color cambie inmediatamente al cambiar el tema
%hook WATheme
- (void)didUpdateTheme {
    %orig;
    // Notifica a las vistas que deben redibujarse con los nuevos colores
    [[NSNotificationCenter defaultCenter] postNotificationName:@"WAThemeChangedNotification" object:nil];
}
%end
