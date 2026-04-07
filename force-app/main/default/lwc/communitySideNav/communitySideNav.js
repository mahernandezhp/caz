import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class CommunitySideNav extends NavigationMixin(LightningElement) {
    @api portalTitle = 'Portal Distribuidor';
    @api accountName = 'Distribuidora Norte';
    @api accountCode = 'DST-0092';
    @api activeKey = 'inicio';
    @api termsUrl = '/terminos';
    @api privacyUrl = '/privacidad';

    get inicioClass() {
        return this.getItemClass('inicio');
    }

    get cuentaClass() {
        return this.getItemClass('cuenta');
    }

    get ordenesClass() {
        return this.getItemClass('ordenes');
    }

    get facturasClass() {
        return this.getItemClass('facturas');
    }

    get casosClass() {
        return this.getItemClass('casos');
    }

    get pagosClass() {
        return this.getItemClass('pagos');
    }

    get perfilClass() {
        return this.getItemClass('perfil');
    }

    get faqsClass() {
        return this.getItemClass('faqs');
    }

    getItemClass(key) {
        return key === this.activeKey ? 'menu-item menu-item--active' : 'menu-item';
    }

    handleStaticClick(event) {
        const key = event.currentTarget.dataset.key;
        this.activeKey = key;

        const routes = {
            inicio: '/',
            cuenta: '/cuenta',
            ordenes: '/ordenes',
            facturas: '/facturas',
            casos: '/casos',
            pagos: '/pagos',
            perfil: '/perfil-ajustes',
            faqs: '/faqs'
        };

        const url = routes[key];

        if (url) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url
                }
            });
        }
    }
}