import { LightningElement, api } from 'lwc';
import getAttributes from '@salesforce/apex/SponsorableAttributeController.getSponsorableAttributes';
import saveAttributes from '@salesforce/apex/SponsorableAttributeController.saveAttributes';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SponsorableAttributeManager extends LightningElement {
    @api recordId;
    _attributes = [];
    _originalAttributes = [];
    _isLoading = true;
    _editModeMap = {};
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
    // Getter for attributes with computed properties
    get attributes() {
        return this._attributes.map(attr => {
            const dataType = attr.Attribute_Type__r?.Data_Type__c || '';
            return {
                ...attr,
                isEditing: !!this._editModeMap[attr.Id],
                isCheckbox: dataType === 'Boolean',
                isText: ['Text', 'Picklist', 'TextArea'].includes(dataType),
                isNumber: ['Number', 'Currency'].includes(dataType),
                isDate: ['Date', 'DateTime'].includes(dataType),
                checkboxIconName: attr.editValue ? 'utility:check' : 'utility:close'
            };
        });
    }
    
    connectedCallback() {
        this.loadAttributes();
    }
    
    async loadAttributes() {
        try {
            this._isLoading = true;
            const result = await getAttributes({ recordId: this.recordId });
            
            this._attributes = result.map(attr => {
                return {
                    ...attr,
                    editValue: attr.Value__c
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
    
    handleEditClick(event) {
        const attributeId = event.currentTarget.dataset.id;
        this._editModeMap = { ...this._editModeMap, [attributeId]: true };
    }
    
    handleSaveClick(event) {
        const attributeId = event.currentTarget.dataset.id;
        this._editModeMap = { ...this._editModeMap, [attributeId]: false };
        this.checkForChanges();
    }
    
    handleCancelClick(event) {
        const attributeId = event.currentTarget.dataset.id;
        
        // Revert to original value
        const attributeIndex = this._attributes.findIndex(attr => attr.Id === attributeId);
        const originalAttribute = this._originalAttributes.find(attr => attr.Id === attributeId);
        
        if (attributeIndex !== -1 && originalAttribute) {
            // Create a new modified array
            const updatedAttributes = [...this._attributes];
            updatedAttributes[attributeIndex] = {
                ...updatedAttributes[attributeIndex],
                editValue: originalAttribute.Value__c
            };
            this._attributes = updatedAttributes;
        }
        
        // Remove from edit mode
        this._editModeMap = { ...this._editModeMap, [attributeId]: false };
        this.checkForChanges();
    }
    
    handleCheckboxChange(event) {
        const attributeId = event.target.dataset.id;
        const checked = event.target.checked;
        
        this.updateAttributeValue(attributeId, checked);
    }
    
    handleTextChange(event) {
        const attributeId = event.target.dataset.id;
        const value = event.target.value;
        
        this.updateAttributeValue(attributeId, value);
    }
    
    handleNumberChange(event) {
        const attributeId = event.target.dataset.id;
        const value = parseFloat(event.target.value);
        
        this.updateAttributeValue(attributeId, value);
    }
    
    handleDateChange(event) {
        const attributeId = event.target.dataset.id;
        const value = event.target.value;
        
        this.updateAttributeValue(attributeId, value);
    }
    
    updateAttributeValue(attributeId, value) {
        const attributeIndex = this._attributes.findIndex(attr => attr.Id === attributeId);
        
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
            return originalAttr && attr.editValue !== originalAttr.Value__c;
        });
    }
    
    async handleSaveAll() {
        try {
            this._isLoading = true;
            
            const updatedAttributes = this._attributes.map(attr => {
                return {
                    Id: attr.Id,
                    Value__c: attr.editValue
                };
            });
            
            await saveAttributes({ attributesToUpdate: updatedAttributes });
            
            // Update original values to match current
            this._originalAttributes = JSON.parse(JSON.stringify(this._attributes));
            this._hasChanges = false;
            this._editModeMap = {}; // Clear edit mode
            
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
