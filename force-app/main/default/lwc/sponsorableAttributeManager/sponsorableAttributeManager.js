import { LightningElement, api } from 'lwc';
import getAttributes from '@salesforce/apex/SponsorableAttributeController.getSponsorableAttributes';
import saveAttributes from '@salesforce/apex/SponsorableAttributeController.saveAttributes';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SponsorableAttributeManager extends LightningElement {
    @api recordId;
    @api cardTitle = 'Sponsorable Attributes';
    _attributes = [];
    _originalAttributes = [];
    _isLoading = true;
    _isEditMode = false;
    _hasChanges = false;
    
    // Getter for isLoading
    get isLoading() {
        return this._isLoading;
    }
    
    // Getter for hasAttributes
    get hasAttributes() {
        return this._attributes.length > 0;
    }
    
    // Getter for hasChanges
    get hasChanges() {
        return this._hasChanges;
    }
    
    get isChangesMissing() {
        return !this._hasChanges;
    }
    
    get isEditMode() {
        return this._isEditMode;
    }
    // Getter for attributes with computed properties
    get attributes() {
        return this._attributes.map(attr => {
            const dataType = attr.Attribute_Type__r?.Data_Type__c || '';
            return {
                ...attr,
                isCheckbox: dataType === 'Checkbox',
                isText: dataType === 'Text',
                isLongText: dataType === 'LongText',
                isPicklist: dataType === 'Picklist',
                isNumber: dataType === 'Number',
                isDate: dataType === 'Date',
                checkboxIconName: attr.editValue ? 'utility:check' : 'utility:close',
                picklistOptions: this.getPicklistOptions(attr)
            };
        });
    }
    
    connectedCallback() {
        this.loadAttributes();
    }

    getDisplayValue(attribute, definition = null) {
        const dataType = definition?.Data_Type__c || attribute.Attribute_Type__r?.Data_Type__c;
        switch (dataType) {
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
    
    async loadAttributes() {
        try {
            this._isLoading = true;
            const result = await getAttributes({ recordId: this.recordId });
            
            this._attributes = result.map((wrapper, index) => {
                const attr = wrapper.attribute;
                const def = wrapper.definition;
                // Use a unique identifier for edit mode tracking
                const uniqueId = attr.Id || `temp_${def.Id}_${index}`;
                return {
                    ...attr,
                    uniqueId: uniqueId,
                    Attribute_Type__r: {
                        Id: def.Id,
                        Name: def.Name,
                        Data_Type__c: def.Data_Type__c,
                        Required__c: def.Required__c,
                        Default_Value__c: def.Default_Value__c,
                        Picklist_Choices__c: def.Picklist_Choices__c
                    },
                    editValue: this.getDisplayValue(attr, def)
                };
            });
            
            // Deep clone for tracking changes
            this._originalAttributes = JSON.parse(JSON.stringify(this._attributes));
            this._isLoading = false;
        } catch (error) {
            this.handleError(error);
            this._isLoading = false;
        }
    }
    
    handleEdit() {
        this._isEditMode = true;
    }
    
    handleCancel() {
        // Revert all changes back to original values
        this._attributes = this._originalAttributes.map(original => ({
            ...original,
            editValue: this.getDisplayValue(original)
        }));
        this._isEditMode = false;
        this._hasChanges = false;
    }
    
    handleCheckboxChange(event) {
        const uniqueId = event.target.dataset.uniqueid;
        const checked = event.target.checked;
        
        this.updateAttributeValue(uniqueId, checked);
    }
    
    handleTextChange(event) {
        const uniqueId = event.target.dataset.uniqueid;
        const value = event.target.value;
        
        this.updateAttributeValue(uniqueId, value);
    }
    
    handleNumberChange(event) {
        const uniqueId = event.target.dataset.uniqueid;
        const value = parseFloat(event.target.value);
        
        this.updateAttributeValue(uniqueId, value);
    }
    
    handleDateChange(event) {
        const uniqueId = event.target.dataset.uniqueid;
        const value = event.target.value;
        
        this.updateAttributeValue(uniqueId, value);
    }
    
    handlePicklistChange(event) {
        const uniqueId = event.target.dataset.uniqueid;
        const value = event.target.value;
        
        this.updateAttributeValue(uniqueId, value);
    }
    
    updateAttributeValue(uniqueId, value) {
        const attributeIndex = this._attributes.findIndex(attr => attr.uniqueId === uniqueId);
        
        if (attributeIndex !== -1) {
            // Create a new modified array
            const updatedAttributes = [...this._attributes];
            updatedAttributes[attributeIndex] = {
                ...updatedAttributes[attributeIndex],
                editValue: value
            };
            this._attributes = updatedAttributes;
            this.checkForChanges();
        }
    }
    
    checkForChanges() {
        this._hasChanges = this._attributes.some(attr => {
            const originalAttr = this._originalAttributes.find(origAttr => origAttr.Id === attr.Id);
            return originalAttr && attr.editValue !== this.getDisplayValue(originalAttr);
        });
    }
    
    async handleSave() {
        try {
            this._isLoading = true;
            
            const updatedAttributes = this._attributes.map(attr => {
                const updateData = {
                    Id: attr.Id,
                    Sponsorable__c: this.recordId,
                    Attribute_Type__c: attr.Attribute_Type__r?.Id,
                    Text_Value__c: null,
                    Number_Value__c: null,
                    Date_Value__c: null,
                    Checkbox_Value__c: null,
                    Picklist_Value__c: null
                };

                switch (attr.Attribute_Type__r?.Data_Type__c) {
                    case 'Text':
                    case 'LongText':
                        updateData.Text_Value__c = attr.editValue;
                        break;
                    case 'Number':
                        updateData.Number_Value__c = parseFloat(attr.editValue) || 0;
                        break;
                    case 'Date':
                        updateData.Date_Value__c = attr.editValue;
                        break;
                    case 'Checkbox':
                        updateData.Checkbox_Value__c = attr.editValue;
                        break;
                    case 'Picklist':
                        updateData.Picklist_Value__c = attr.editValue;
                        break;
                }

                return updateData;
            });
            
            await saveAttributes({ attributesToUpdate: updatedAttributes });
            
            // Update original values to match current
            this._originalAttributes = JSON.parse(JSON.stringify(this._attributes));
            this._hasChanges = false;
            this._isEditMode = false;
            
            this.showToast('Success', 'Attributes updated successfully', 'success');
            this._isLoading = false;
        } catch (error) {
            this.handleError(error);
            this._isLoading = false;
        }
    }
    
    handleError(error) {
        let message = 'Unknown error';
        if (error.body && error.body.message) {
            message = error.body.message;
        } else if (typeof error.message === 'string') {
            message = error.message;
        }
        this.showToast('Error', message, 'error');
    }
    
    getPicklistOptions(attribute) {
        const choices = attribute.Attribute_Type__r?.Picklist_Choices__c;
        if (!choices) {
            return [];
        }
        
        return choices.split(';').map(choice => ({
            label: choice.trim(),
            value: choice.trim()
        }));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}
