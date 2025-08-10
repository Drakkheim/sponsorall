@IsTest
public class SponsorableAttributeControllerTest {
    
    @TestSetup
    static void setupTestData() {
        Sponsorable__c sponsorable = new Sponsorable__c(
            Name = 'Test Sponsorable',
            Description__c = 'Test Description'
        );
        insert sponsorable;
        
        Sponsorable_Attribute_Definition__c textDef = new Sponsorable_Attribute_Definition__c(
            Name = 'Test Text Attribute',
            Data_Type__c = 'Text',
            Required__c = false,
            Default_Value__c = 'Default Text'
        );
        
        Sponsorable_Attribute_Definition__c numberDef = new Sponsorable_Attribute_Definition__c(
            Name = 'Test Number Attribute',
            Data_Type__c = 'Number',
            Required__c = true,
            Default_Value__c = '100'
        );
        
        Sponsorable_Attribute_Definition__c checkboxDef = new Sponsorable_Attribute_Definition__c(
            Name = 'Test Checkbox Attribute',
            Data_Type__c = 'Checkbox',
            Required__c = false,
            Default_Value__c = 'true'
        );
        
        insert new List<Sponsorable_Attribute_Definition__c>{textDef, numberDef, checkboxDef};
        
        Sponsorable_Attribute__c textAttr = new Sponsorable_Attribute__c(
            Sponsorable__c = sponsorable.Id,
            Attribute_Type__c = textDef.Id,
            Text_Value__c = 'Test Value'
        );
        
        Sponsorable_Attribute__c numberAttr = new Sponsorable_Attribute__c(
            Sponsorable__c = sponsorable.Id,
            Attribute_Type__c = numberDef.Id,
            Number_Value__c = 50.25
        );
        
        insert new List<Sponsorable_Attribute__c>{textAttr, numberAttr};
    }
    
    @IsTest
    static void testGetSponsorableAttributes() {
        Sponsorable__c sponsorable = [SELECT Id FROM Sponsorable__c LIMIT 1];
        
        Test.startTest();
        List<Sponsorable_Attribute__c> attributes = SponsorableAttributeController.getSponsorableAttributes(sponsorable.Id);
        Test.stopTest();
        
        System.assertEquals(2, attributes.size(), 'Should return 2 attributes');
        
        for (Sponsorable_Attribute__c attr : attributes) {
            System.assertNotEquals(null, attr.Attribute_Type__r.Name, 'Attribute type name should be populated');
            System.assertNotEquals(null, attr.Attribute_Type__r.Data_Type__c, 'Data type should be populated');
        }
    }
    
    @IsTest
    static void testUpdateSponsorableAttribute() {
        Sponsorable_Attribute__c attribute = [
            SELECT Id, Text_Value__c 
            FROM Sponsorable_Attribute__c 
            WHERE Text_Value__c = 'Test Value' 
            LIMIT 1
        ];
        
        attribute.Text_Value__c = 'Updated Value';
        
        Test.startTest();
        SponsorableAttributeController.updateSponsorableAttribute(attribute);
        Test.stopTest();
        
        Sponsorable_Attribute__c updatedAttr = [
            SELECT Id, Text_Value__c 
            FROM Sponsorable_Attribute__c 
            WHERE Id = :attribute.Id
        ];
        
        System.assertEquals('Updated Value', updatedAttr.Text_Value__c, 'Attribute should be updated');
    }
    
    @IsTest
    static void testCreateMissingAttributes() {
        Sponsorable__c sponsorable = [SELECT Id FROM Sponsorable__c LIMIT 1];
        
        Test.startTest();
        List<Sponsorable_Attribute__c> newAttributes = SponsorableAttributeController.createMissingAttributes(sponsorable.Id);
        Test.stopTest();
        
        System.assertEquals(1, newAttributes.size(), 'Should create 1 missing attribute (checkbox)');
        
        List<Sponsorable_Attribute__c> allAttributes = [
            SELECT Id 
            FROM Sponsorable_Attribute__c 
            WHERE Sponsorable__c = :sponsorable.Id
        ];
        
        System.assertEquals(3, allAttributes.size(), 'Should now have 3 total attributes');
    }
    
    @IsTest
    static void testGetSponsorableAttributesException() {
        Test.startTest();
        try {
            SponsorableAttributeController.getSponsorableAttributes(null);
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Error retrieving'), 'Should contain error message');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateSponsorableAttributeException() {
        Sponsorable_Attribute__c invalidAttribute = new Sponsorable_Attribute__c();
        
        Test.startTest();
        try {
            SponsorableAttributeController.updateSponsorableAttribute(invalidAttribute);
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Error updating'), 'Should contain error message');
        }
        Test.stopTest();
    }
}