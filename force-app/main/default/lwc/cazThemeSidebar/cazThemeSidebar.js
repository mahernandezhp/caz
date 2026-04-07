import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

export default class CazThemeSidebar extends LightningElement {
    @api item1Label = 'Inicio'; @api item1Icon = 'utility:home'; @api item1Url = '/';
    @api item2Label = 'Cuenta'; @api item2Icon = 'utility:groups'; @api item2Url = '/cuenta';
    @api item3Label = 'Órdenes'; @api item3Icon = 'utility:clipboard'; @api item3Url = '/ordenes';
    @api item4Label = 'Facturas'; @api item4Icon = 'utility:file'; @api item4Url = '/facturas';
    @api item5Label = 'Casos'; @api item5Icon = 'utility:case'; @api item5Url = '/casos';
    @api item6Label = 'Pagos'; @api item6Icon = 'utility:card'; @api item6Url = '/pagos';

    @track _currentPath = '/';

    /**
     * Wire property (no method) — se asigna directamente y dispara reactividad.
     * En Experience Cloud, pageRef.state contiene info de la página actual.
     */
    _pageRef;

    @wire(CurrentPageReference)
    setPageReference(pageRef) {
        this._pageRef = pageRef;
        if (pageRef) {
            this._currentPath = this._resolveCurrentPath();
        }
    }

    connectedCallback() {
        this._currentPath = this._resolveCurrentPath();
    }

    /**
     * Lee la URL actual del browser y extrae la ruta relativa.
     * Experience Cloud genera URLs con diferentes patrones:
     *   /s/                    → Home
     *   /s/pagina              → Página
     *   /NombreSitio/s/pagina  → Con prefijo de sitio
     *   /pagina                → Sin /s/ en algunos casos
     */
    _resolveCurrentPath() {
        try {
            const fullPath = window.location.pathname || '/';

            // Patrón típico de Experience Cloud: buscar /s/ y extraer después
            const sMatch = fullPath.match(/\/s(\/.*)?$/i);
            if (sMatch) {
                return sMatch[1] || '/';
            }

            // Si no hay /s/, intentar extraer la parte final de la URL
            // (después del base path del sitio)
            const segments = fullPath.split('/').filter(Boolean);
            if (segments.length > 0) {
                // El último segmento suele ser la página
                return '/' + segments[segments.length - 1];
            }

            return '/';
        } catch (e) {
            return '/';
        }
    }

    /**
     * Compara la URL de un item del menú vs la URL actual.
     * Home (/) solo matchea exacto; el resto por prefijo.
     */
    _isActive(itemUrl) {
        if (!itemUrl) return false;

        const normalizedItem = (itemUrl || '/').toLowerCase().replace(/\/+$/, '') || '/';
        const normalizedCurrent = (this._currentPath || '/').toLowerCase().replace(/\/+$/, '') || '/';

        // Home: solo exacto
        if (normalizedItem === '/') {
            return normalizedCurrent === '/';
        }

        // Resto: prefijo o exacto
        return normalizedCurrent === normalizedItem ||
               normalizedCurrent.startsWith(normalizedItem + '/');
    }

    _itemClass(url) {
        return this._isActive(url)
            ? 'slds-nav-vertical__item slds-is-active'
            : 'slds-nav-vertical__item';
    }

    _ariaCurrent(url) {
        return this._isActive(url) ? 'page' : undefined;
    }

    get menuItems() {
        // Forzar dependencia reactiva en _currentPath
        const _path = this._currentPath; // eslint-disable-line no-unused-vars

        const items = [];
        const configs = [
            { id: 1, label: this.item1Label, icon: this.item1Icon || 'utility:home', url: this.item1Url },
            { id: 2, label: this.item2Label, icon: this.item2Icon || 'utility:groups', url: this.item2Url, subLabel: '(Crédito)' },
            { id: 3, label: this.item3Label, icon: this.item3Icon || 'utility:clipboard', url: this.item3Url, badge: '2' },
            { id: 4, label: this.item4Label, icon: this.item4Icon || 'utility:file', url: this.item4Url },
            { id: 5, label: this.item5Label, icon: this.item5Icon || 'utility:case', url: this.item5Url },
            { id: 6, label: this.item6Label, icon: this.item6Icon || 'utility:card', url: this.item6Url }
        ];

        for (const cfg of configs) {
            if (cfg.label) {
                items.push({
                    ...cfg,
                    itemClass: this._itemClass(cfg.url),
                    ariaCurrent: this._ariaCurrent(cfg.url)
                });
            }
        }
        return items;
    }
}