import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSponsorableAttributes from '@salesforce/apex/SponsorableAttributeController.getSponsorableAttributes';
import updateSponsorableAttribute from '@salesforce/apex/SponsorableAttributeController.updateSponsorableAttribute';

const SPONSORABLE_FIELDS = ['Sponsorable__c.Id', 'Sponsorable__c.Name'];

export default class SponsorableAttributeManager extends LightningElement {
    @api recordId;
    @track attributes = [];
    @track isLoading = true;
    @track editMode = {};

    @wire(getRecord, { recordId: '$recordId', fields: SPONSORABLE_FIELDS })
    sponsorable;

    connectedCallback() {
        this.loadAttributes();
    }

    loadAttributes() {
        this.isLoading = true;
        getSponsorableAttributes({ sponsorableId: this.recordId })
            .then(result => {
                this.attributes = result.map(attr => ({
                    ...attr,
                    editValue: this.getDisplayValue(attr)
                }));
                this.isLoading = false;
            })
            .catch(error => {
                this.showToast('Error', 'Failed to load attributes: ' + error.body.message, 'error');
                this.isLoading = false;
            });
    }

    getDisplayValue(attribute) {
        switch (attribute.Attribute_Type__r.Data_Type__c) {
            case 'Text':
            case 'LongText':
                return attribute.Text_Value__c || '';
            case 'Number':
                return attribute.Number_Value__c || 0;
            case 'Date':
                return attribute.Date_Value__c || '';
            case 'Checkbox':
                return attribute.Checkbox_Value__c || false;
            case 'Picklist':
                return attribute.Picklist_Value__c || '';
            default:
                return '';
        }
    }

    handleEdit(event) {
        const attributeId = event.target.dataset.id;
        this.editMode = { ...this.editMode, [attributeId]: true };
    }

    handleCancel(event) {
        const attributeId = event.target.dataset.id;
        const attribute = this.attributes.find(attr => attr.Id === attributeId);
        if (attribute) {
            attribute.editValue = this.getDisplayValue(attribute);
        }
        this.editMode = { ...this.editMode, [attributeId]: false };
    }

    handleInputChange(event) {
        const attributeId = event.target.dataset.id;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        
        const attribute = this.attributes.find(attr => attr.Id === attributeId);
        if (attribute) {
            attribute.editValue = value;
        }
    }

    handleSave(event) {
        const attributeId = event.target.dataset.id;
        const attribute = this.attributes.find(attr => attr.Id === attributeId);
        
        if (!attribute) return;

        const updateData = {
            Id: attributeId,
            Text_Value__c: null,
            Number_Value__c: null,
            Date_Value__c: null,
            Checkbox_Value__c: null,
            Picklist_Value__c: null
        };

        switch (attribute.Attribute_Type__r.Data_Type__c) {
            case 'Text':
            case 'LongText':
                updateData.Text_Value__c = attribute.editValue;
                break;
            case 'Number':
                updateData.Number_Value__c = parseFloat(attribute.editValue) || 0;
                break;
            case 'Date':
                updateData.Date_Value__c = attribute.editValue;
                break;
            case 'Checkbox':
                updateData.Checkbox_Value__c = attribute.editValue;
                break;
            case 'Picklist':
                updateData.Picklist_Value__c = attribute.editValue;
                break;
        }

        updateSponsorableAttribute({ attributeData: updateData })
            .then(() => {
                this.updateAttributeValue(attribute, attribute.editValue);
                this.editMode = { ...this.editMode, [attributeId]: false };
                this.showToast('Success', 'Attribute updated successfully', 'success');
            })
            .catch(error => {
                this.showToast('Error', 'Failed to update attribute: ' + error.body.message, 'error');
            });
    }

    updateAttributeValue(attribute, newValue) {
        switch (attribute.Attribute_Type__r.Data_Type__c) {
            case 'Text':
            case 'LongText':
                attribute.Text_Value__c = newValue;
                break;
            case 'Number':
                attribute.Number_Value__c = parseFloat(newValue) || 0;
                break;
            case 'Date':
                attribute.Date_Value__c = newValue;
                break;
            case 'Checkbox':
                attribute.Checkbox_Value__c = newValue;
                break;
            case 'Picklist':
                attribute.Picklist_Value__c = newValue;
                break;
        }
    }

    getInputType(dataType) {
        switch (dataType) {
            case 'Text':
                return 'text';
            case 'Number':
                return 'number';
            case 'Date':
                return 'date';
            case 'LongText':
                return 'textarea';
            default:
                return 'text';
        }
    }

    isCheckboxType(dataType) {
        return dataType === 'Checkbox';
    }

    isPicklistType(dataType) {
        return dataType === 'Picklist';
    }

    getPicklistOptions(attribute) {
        if (!attribute.Attribute_Type__r.Picklist_Choices__c) {
            return [];
        }
        
        return attribute.Attribute_Type__r.Picklist_Choices__c.split(';').map(choice => ({
            label: choice.trim(),
            value: choice.trim()
        }));
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    get hasAttributes() {
        return this.attributes && this.attributes.length > 0;
    }
}