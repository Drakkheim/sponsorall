public with sharing class SponsorableAttributeController {
    
    @AuraEnabled(cacheable=true)
    public static List<Sponsorable_Attribute__c> getSponsorableAttributes(Id sponsorableId) {
        try {
            return [
                SELECT Id, Name,
                       Text_Value__c, Number_Value__c, Date_Value__c, 
                       Checkbox_Value__c, Picklist_Value__c,
                       Attribute_Type__c,
                       Attribute_Type__r.Id,
                       Attribute_Type__r.Name,
                       Attribute_Type__r.Data_Type__c,
                       Attribute_Type__r.Required__c,
                       Attribute_Type__r.Default_Value__c,
                       Attribute_Type__r.Picklist_Choices__c
                FROM Sponsorable_Attribute__c
                WHERE Sponsorable__c = :sponsorableId
                ORDER BY Attribute_Type__r.Name ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving sponsorable attributes: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void saveAttributes(Sponsorable_Attribute__c attributeData) {
        try {
            upsert attributeData;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating sponsorable attribute: ' + e.getMessage());
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
        switch on dataType {
            when 'Text', 'LongText' {
                attribute.Text_Value__c = defaultValue;
            }
            when 'Number' {
                try {
                    attribute.Number_Value__c = Decimal.valueOf(defaultValue);
                } catch (TypeException e) {
                    attribute.Number_Value__c = 0;
                }
            }
            when 'Date' {
                try {
                    attribute.Date_Value__c = Date.valueOf(defaultValue);
                } catch (TypeException e) {
                    attribute.Date_Value__c = Date.today();
                }
            }
            when 'Checkbox' {
                attribute.Checkbox_Value__c = Boolean.valueOf(defaultValue);
            }
            when 'Picklist' {
                attribute.Picklist_Value__c = defaultValue;
            }
        }
    }
}