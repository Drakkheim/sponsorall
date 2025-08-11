public with sharing class SponsorableAttributeController {
    
    @AuraEnabled(cacheable=true)
    public static List<AttributeWrapper> getSponsorableAttributes(Id recordId) {
        try {
            // Get all attribute definitions
            List<Sponsorable_Attribute_Definition__c> definitions = [
                SELECT Id, Name, Data_Type__c, Required__c, Default_Value__c, Picklist_Choices__c
                FROM Sponsorable_Attribute_Definition__c
                ORDER BY Name ASC
            ];
            
            // Get existing attributes for this sponsorable
            Map<Id, Sponsorable_Attribute__c> existingAttributes = new Map<Id, Sponsorable_Attribute__c>();
            for (Sponsorable_Attribute__c attr : [
                SELECT Id, Name, Text_Value__c, Number_Value__c, Date_Value__c, 
                       Checkbox_Value__c, Picklist_Value__c, Attribute_Type__c
                FROM Sponsorable_Attribute__c
                WHERE Sponsorable__c = :recordId
            ]) {
                existingAttributes.put(attr.Attribute_Type__c, attr);
            }
            
            // Build wrapper list
            List<AttributeWrapper> wrappers = new List<AttributeWrapper>();
            for (Sponsorable_Attribute_Definition__c def : definitions) {
                AttributeWrapper wrapper = new AttributeWrapper();
                wrapper.definition = def;
                wrapper.attribute = existingAttributes.get(def.Id);
                
                if (wrapper.attribute == null) {
                    // Create a placeholder attribute record
                    wrapper.attribute = new Sponsorable_Attribute__c(
                        Sponsorable__c = recordId,
                        Attribute_Type__c = def.Id
                    );
                    if (String.isNotBlank(def.Default_Value__c)) {
                        setDefaultValue(wrapper.attribute, def.Data_Type__c, def.Default_Value__c);
                    }
                }
                
                wrappers.add(wrapper);
            }
            
            return wrappers;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving sponsorable attributes: ' + e.getMessage());
        }
    }
    
    public class AttributeWrapper {
        @AuraEnabled public Sponsorable_Attribute_Definition__c definition;
        @AuraEnabled public Sponsorable_Attribute__c attribute;
    }
    
    @AuraEnabled
    public static void saveAttributes(List<Sponsorable_Attribute__c> attributesToUpdate) {
        try {
            upsert attributesToUpdate;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating sponsorable attributes: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<Sponsorable_Attribute__c> createMissingAttributes(Id sponsorableId) {
        try {
            List<Sponsorable_Attribute__c> existingAttributes = [
                SELECT Attribute_Type__c
                FROM Sponsorable_Attribute__c
                WHERE Sponsorable__c = :sponsorableId
            ];
            
            Set<Id> existingAttributeTypes = new Set<Id>();
            for (Sponsorable_Attribute__c attr : existingAttributes) {
                existingAttributeTypes.add(attr.Attribute_Type__c);
            }
            
            List<Sponsorable_Attribute_Definition__c> allDefinitions = [
                SELECT Id, Name, Data_Type__c, Default_Value__c
                FROM Sponsorable_Attribute_Definition__c
                WHERE Id NOT IN :existingAttributeTypes
            ];
            
            List<Sponsorable_Attribute__c> newAttributes = new List<Sponsorable_Attribute__c>();
            for (Sponsorable_Attribute_Definition__c def : allDefinitions) {
                Sponsorable_Attribute__c newAttr = new Sponsorable_Attribute__c(
                    Sponsorable__c = sponsorableId,
                    Attribute_Type__c = def.Id
                );
                
                if (String.isNotBlank(def.Default_Value__c)) {
                    setDefaultValue(newAttr, def.Data_Type__c, def.Default_Value__c);
                }
                
                newAttributes.add(newAttr);
            }
            
            if (!newAttributes.isEmpty()) {
                insert newAttributes;
            }
            
            return newAttributes;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error creating missing attributes: ' + e.getMessage());
        }
    }
    
    private static void setDefaultValue(Sponsorable_Attribute__c attribute, String dataType, String defaultValue) {
        if (String.isBlank(defaultValue)) {
            return;
        }
        
        switch on dataType {
            when 'Text', 'LongText' {
                attribute.Text_Value__c = defaultValue;
            }
            when 'Number' {
                try {
                    attribute.Number_Value__c = Decimal.valueOf(defaultValue);
                } catch (Exception e) {
                    attribute.Number_Value__c = 0;
                }
            }
            when 'Date' {
                try {
                    attribute.Date_Value__c = Date.valueOf(defaultValue);
                } catch (Exception e) {
                    // Don't set a default date if parsing fails
                }
            }
            when 'Checkbox' {
                try {
                    attribute.Checkbox_Value__c = Boolean.valueOf(defaultValue);
                } catch (Exception e) {
                    attribute.Checkbox_Value__c = false;
                }
            }
            when 'Picklist' {
                attribute.Picklist_Value__c = defaultValue;
            }
        }
    }
}