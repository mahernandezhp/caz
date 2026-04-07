import { LightningElement, api } from 'lwc';

export default class CazPortalSidebar extends LightningElement {
    static renderMode = 'light'; // Permite el uso de clases globales como TailwindCSS

    @api logoText = '+';
    @api brandName = 'Portal Distribuidor';

    @api titlePrincipal = 'PRINCIPAL';
    // Arreglo JSON por defecto basado en el mockup
    @api menuPrincipalJson = '[{"label":"Inicio","icon":"mdi-home-outline","url":"/","showChevron":false},{"label":"Cuenta","subLabel":"(Crédito)","icon":"mdi-account-cash-outline","url":"/cuenta","showChevron":true},{"label":"Órdenes","badge":"2","icon":"mdi-clipboard-text-outline","url":"/ordenes","showChevron":false},{"label":"Facturas","icon":"mdi-receipt-text-outline","url":"/facturas","showChevron":true},{"label":"Casos","icon":"mdi-briefcase-outline","url":"/casos","showChevron":true},{"label":"Pagos","icon":"mdi-credit-card-outline","url":"/pagos","showChevron":false}]';

    @api titleAjustes = 'AJUSTES & SOPORTE';
    @api menuAjustesJson = '[{"label":"Perfil & Ajustes","icon":"mdi-cog-outline","url":"/perfil"},{"label":"FAQ\'s","icon":"mdi-frequently-asked-questions","url":"/faqs"}]';

    @api showUserPanel = false;
    @api userName = 'Distribuidora Norte';
    @api userIdStr = 'ID: DST-0092';
    @api userInitials = 'DN';
    @api userAvatarUrl = '';
    
    @api terminosUrl = '/terminos';
    @api privacidadUrl = '/privacidad';

    // Getters para parsear el JSON configurado desde el Experience Builder
    get menuPrincipalParsed() {
        try {
            return this.menuPrincipalJson ? JSON.parse(this.menuPrincipalJson) : [];
        } catch(e) {
            console.error('Error parsing menuPrincipalJson', e);
            return [];
        }
    }

    get menuAjustesParsed() {
        try {
            return this.menuAjustesJson ? JSON.parse(this.menuAjustesJson) : [];
        } catch(e) {
            console.error('Error parsing menuAjustesJson', e);
            return [];
        }
    }
}