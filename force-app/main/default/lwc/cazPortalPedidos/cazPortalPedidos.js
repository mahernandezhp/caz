import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getMyOrdersContext from '@salesforce/apex/CAZ_PortalPedidosController.getMyOrdersContext';

export default class CazPortalPedidos extends NavigationMixin(LightningElement) {
    showModal = false;
    errorMessage;

    userName;
    accountId;
    accountName;
    contactId;

    orders = [];
    isLoading = true;

    defaultStatus = 'Borrador';

    columns = [
        {
            label: 'Número',
            type: 'button',
            typeAttributes: {
                label: { fieldName: 'orderNumber' },
                name: 'view_order',
                variant: 'base'
            }
        },
        {
            label: 'Fecha efectiva',
            fieldName: 'effectiveDate',
            type: 'date'
        },
        {
            label: 'Estatus',
            fieldName: 'status',
            type: 'text'
        },
        {
            label: 'Total',
            fieldName: 'totalAmount',
            type: 'currency'
        },
        {
            label: 'Descripción',
            fieldName: 'description',
            type: 'text'
        }
    ];

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        this.isLoading = true;
        this.errorMessage = undefined;

        try {
            const data = await getMyOrdersContext();

            this.userName = data.userName;
            this.accountId = data.accountId;
            this.accountName = data.accountName;
            this.contactId = data.contactId;
            this.orders = data.orders || [];
        } catch (error) {
            this.userName = undefined;
            this.accountId = undefined;
            this.accountName = undefined;
            this.contactId = undefined;
            this.orders = [];
            this.errorMessage = this.reduceError(error);
        } finally {
            this.isLoading = false;
        }
    }

    get hasContext() {
        return !!this.accountId;
    }

    get hasOrders() {
        return Array.isArray(this.orders) && this.orders.length > 0;
    }

    get ordersCount() {
        return Array.isArray(this.orders) ? this.orders.length : 0;
    }

    get totalAmount() {
        if (!Array.isArray(this.orders) || this.orders.length === 0) {
            return 0;
        }

        return this.orders.reduce((sum, row) => {
            return sum + (row.totalAmount || 0);
        }, 0);
    }

    get formattedTotalAmount() {
        return new Intl.NumberFormat('es-MX', {
            style: 'currency',
            currency: 'MXN',
            maximumFractionDigits: 2
        }).format(this.totalAmount);
    }

    get draftOrdersCount() {
        if (!Array.isArray(this.orders) || this.orders.length === 0) {
            return 0;
        }

        return this.orders.filter(row => row.status === 'Borrador').length;
    }

    openModal() {
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
    }

    handleSubmit(event) {
        event.preventDefault();

        const fields = { ...event.detail.fields };

        fields.AccountId = this.accountId;
        fields.CAZ_Contacto__c = this.contactId;
        fields.Status = this.defaultStatus;

        event.target.submit(fields);
    }

    async handleSuccess(event) {
        const newOrderId = event.detail.id;

        this.showModal = false;

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Orden creada',
                message: 'La orden se creó correctamente.',
                variant: 'success'
            })
        );

        await this.loadData();

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: newOrderId,
                objectApiName: 'Order',
                actionName: 'view'
            }
        });
    }

    handleError(event) {
        const message =
            event?.detail?.detail ||
            event?.detail?.message ||
            'Ocurrió un error al guardar la orden.';

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message,
                variant: 'error'
            })
        );
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'view_order' && row?.orderId) {
            this.navigateToOrderDetail(row.orderId);
        }
    }

    navigateToOrderDetail(orderId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: orderId,
                objectApiName: 'Order',
                actionName: 'view'
            }
        });
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map(e => e.message).join(', ');
        }

        if (typeof error?.body?.message === 'string') {
            return error.body.message;
        }

        if (typeof error?.message === 'string') {
            return error.message;
        }

        return 'Ocurrió un error inesperado.';
    }
}