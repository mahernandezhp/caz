/**
 * cazDashboardDistribuidor
 * Componente orquestador: compone los 5 componentes hijos y maneja
 * la lógica de navegación SPA entre vistas.
 * 
 * Cada hijo recibe userId y hace sus propias llamadas Apex.
 */
import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class CazDashboardDistribuidor extends NavigationMixin(LightningElement) {
    @track currentView = 'home';

    // En el futuro, obtener dinámicamente del contexto de Experience Cloud
    get userId() {
        return null; // Se resolverá cuando se conecten los Apex controllers
    }

    // ── Vista SPA States ──
    get isHome() { return this.currentView === 'home'; }
    get isDevoluciones() { return this.currentView === 'mis_solicitudes'; }
    get isNuevaDevolucion() { return this.currentView === 'nueva_solicitud'; }

    // ── Eventos de navegación ──
    handleNavHome() {
        this.currentView = 'home';
    }

    handleNavDevoluciones() {
        this.currentView = 'mis_solicitudes';
    }

    handleSpaNavigation(event) {
        const target = event.detail.target;
        if (target) {
            this.currentView = target;
        }
    }

    // ── Eventos de componentes hijos ──
    handleQuickAction(event) {
        const actionId = event.detail.actionId;
        switch (actionId) {
            case 'devoluciones':
                this.currentView = 'mis_solicitudes';
                break;
            case 'nueva_orden':
                // Futuro: navegar a página de nueva orden
                break;
            case 'pagar_ordenes':
                // Futuro: navegar a página de pagos
                break;
            case 'aclaraciones':
                // Futuro: navegar a página de casos
                break;
            case 'ampliacion_credito':
                // Navegamos a la página de la comunidad donde se alojará el Flow
                this[NavigationMixin.Navigate]({
                    type: 'comm__namedPage',
                    attributes: {
                        name: 'SolicitudAmpliacionCredito__c' // El nombre de la página a crear en Experience Builder
                    }
                });
                break;
            default:
                break;
        }
    }

    handleKpiAction(event) {
        const action = event.detail.action;
        // Futuro: manejar acciones de KPI (ampliar, detalles, casos)
        console.log('KPI action:', action);
    }

    handleViewAllOrders() {
        // Futuro: navegar a vista de todas las órdenes
        console.log('View all orders');
    }
}