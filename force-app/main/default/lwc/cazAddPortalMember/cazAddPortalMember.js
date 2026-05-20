import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFormData from '@salesforce/apex/CAZ_PortalMemberController.getFormData';
import createPortalMember from '@salesforce/apex/CAZ_PortalMemberController.createPortalMember';

export default class CazAddPortalMember extends LightningElement {
    @track firstName = '';
    @track lastName = '';
    @track email = '';
    @track profileId = '';
    @track roleId = '';
    @track permissionSetIds = [];

    profileOptions = [];
    roleOptions = [];
    permissionSetOptions = [];
    accountId;
    accountName;

    isLoading = false;
    error;

    @wire(getFormData)
    wiredFormData({ data, error }) {
        if (data) {
            this.profileOptions = data.profiles || [];
            this.roleOptions = data.roles || [];
            this.permissionSetOptions = data.permissionSets || [];
            this.accountId = data.accountId;
            this.accountName = data.accountName;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Error cargando datos';
        }
    }

    handleChange(event) {
        const field = event.target.dataset.field;
        if (field === 'permissionSets') {
            this.permissionSetIds = event.detail.value;
        } else {
            this[field] = event.target.value;
        }
    }

    get isFormInvalid() {
        return !this.lastName || !this.email || !this.profileId;
    }

    async handleSave() {
        if (this.isFormInvalid) {
            this.showToast('Error', 'Completa los campos requeridos.', 'error');
            return;
        }
        this.isLoading = true;
        try {
            await createPortalMember({
                firstName: this.firstName,
                lastName: this.lastName,
                email: this.email,
                profileId: this.profileId,
                roleId: this.roleId,
                permissionSetIds: this.permissionSetIds,
                accountId: this.accountId
            });
            this.showToast('Éxito', 'Solicitud enviada. El usuario se creará en unos segundos.', 'success');
            this.resetForm();
        } catch (e) {
            this.showToast('Error', e.body ? e.body.message : e.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    resetForm() {
        this.firstName = '';
        this.lastName = '';
        this.email = '';
        this.profileId = '';
        this.roleId = '';
        this.permissionSetIds = [];
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
