// --- HOOK DE VERIFICACIÓN REAL (MÉTODO DE DIBUJO) ---
@interface UILabel (DomidiosWA)
@end

@implementation UILabel (DomidiosWA)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Cambiamos 'setText:' por 'layoutSubviews' para asegurar que el check aparezca siempre
        Method original = class_getInstanceMethod([self class], @selector(layoutSubviews));
        Method swizzled = class_getInstanceMethod([self class], @selector(domidios_layoutSubviews));
        method_exchangeImplementations(original, swizzled);
    });
}

- (void)domidios_layoutSubviews {
    [self domidios_layoutSubviews]; // Llamada original obligatoria

    // Identificador único para no repetir el check infinitamente
    NSInteger badgeTag = 991122; 

    if (isVerifiedActive) {
        // Filtro para aplicar solo a nombres (evita labels gigantes o iconos pequeños)
        if (self.text.length > 0 && self.text.length < 30 && self.frame.size.height > 15) {
            
            // Si ya tiene el check, no lo volvemos a poner
            if ([self viewWithTag:badgeTag]) return;

            // Creamos el Badge como un UILabel pequeño e independiente
            UILabel *badge = [[UILabel alloc] init];
            badge.tag = badgeTag;
            badge.text = @"\u2714"; // El check real
            badge.textColor = [UIColor colorWithRed:0.00 green:0.64 blue:0.85 alpha:1.0]; // Azul WA
            badge.font = [UIFont systemFontOfSize:self.font.pointSize * 0.9 weight:UIFontWeightBold];
            [badge sizeToFit];

            // Calculamos la posición justo después del texto
            NSDictionary *attributes = @{NSFontAttributeName: self.font};
            CGSize textSize = [self.text sizeWithAttributes:attributes];
            
            // Ajustamos la posición X para que se pegue al final del nombre
            CGFloat badgeX = textSize.width + 5;
            if (badgeX > self.frame.size.width - 15) badgeX = self.frame.size.width - 15;

            badge.frame = CGRectMake(badgeX, (self.frame.size.height/2) - (badge.frame.size.height/2), badge.frame.size.width, badge.frame.size.height);
            
            [self addSubview:badge];
        }
    } else {
        // Si se desactiva, borramos todos los badges activos
        UIView *oldBadge = [self viewWithTag:badgeTag];
        if (oldBadge) [oldBadge removeFromSuperview];
    }
}
@end
