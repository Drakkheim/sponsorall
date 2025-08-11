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
        
        Sponsorable_Attribute_Definition__c picklistDef = new Sponsorable_Attribute_Definition__c(
            Name = 'Test Picklist Attribute',
            Data_Type__c = 'Picklist',
            Required__c = false,
            Picklist_Choices__c = 'Option1;Option2;Option3'
        );
        
        Sponsorable_Attribute_Definition__c dateDef = new Sponsorable_Attribute_Definition__c(
            Name = 'Test Date Attribute',
            Data_Type__c = 'Date',
            Required__c = false
        );
        
        insert new List<Sponsorable_Attribute_Definition__c>{textDef, numberDef, checkboxDef, picklistDef, dateDef};
        
        // Only create attributes for some definitions to test both existing and missing scenarios
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
        List<SponsorableAttributeController.AttributeWrapper> wrappers = SponsorableAttributeController.getSponsorableAttributes(sponsorable.Id);
        Test.stopTest();
        
        System.assertEquals(5, wrappers.size(), 'Should return 5 attribute definitions');
        
        Integer existingAttributes = 0;
        Integer placeholderAttributes = 0;
        
        for (SponsorableAttributeController.AttributeWrapper wrapper : wrappers) {
            // Verify definition is populated
            System.assertNotEquals(null, wrapper.definition, 'Definition should be populated');
            System.assertNotEquals(null, wrapper.definition.Name, 'Definition name should be populated');
            System.assertNotEquals(null, wrapper.definition.Data_Type__c, 'Data type should be populated');
            
            // Verify attribute is populated (either existing or placeholder)
            System.assertNotEquals(null, wrapper.attribute, 'Attribute should be populated');
            System.assertEquals(sponsorable.Id, wrapper.attribute.Sponsorable__c, 'Sponsorable should be set');
            System.assertEquals(wrapper.definition.Id, wrapper.attribute.Attribute_Type__c, 'Attribute type should match');
            
            if (wrapper.attribute.Id != null) {
                existingAttributes++;
            } else {
                placeholderAttributes++;
            }
        }
        
        System.assertEquals(2, existingAttributes, 'Should have 2 existing attributes');
        System.assertEquals(3, placeholderAttributes, 'Should have 3 placeholder attributes');
    }
    
    @IsTest
    static void testSaveAttributes() {
        Sponsorable__c sponsorable = [SELECT Id FROM Sponsorable__c LIMIT 1];
        Sponsorable_Attribute_Definition__c textDef = [
            SELECT Id FROM Sponsorable_Attribute_Definition__c 
            WHERE Data_Type__c = 'Text' LIMIT 1
        ];
        
        List<Sponsorable_Attribute__c> attributesToUpdate = new List<Sponsorable_Attribute__c>();
        
        // Update existing attribute
        Sponsorable_Attribute__c existingAttr = [
            SELECT Id, Text_Value__c 
            FROM Sponsorable_Attribute__c 
            WHERE Text_Value__c = 'Test Value' 
            LIMIT 1
        ];
        existingAttr.Text_Value__c = 'Updated Value';
        attributesToUpdate.add(existingAttr);
        
        // Create new attribute
        Sponsorable_Attribute__c newAttr = new Sponsorable_Attribute__c(
            Sponsorable__c = sponsorable.Id,
            Attribute_Type__c = textDef.Id,
            Text_Value__c = 'New Value'
        );
        attributesToUpdate.add(newAttr);
        
        Test.startTest();
        SponsorableAttributeController.saveAttributes(attributesToUpdate);
        Test.stopTest();
        
        // Verify existing attribute was updated
        Sponsorable_Attribute__c updatedAttr = [
            SELECT Id, Text_Value__c 
            FROM Sponsorable_Attribute__c 
            WHERE Id = :existingAttr.Id
        ];
        System.assertEquals('Updated Value', updatedAttr.Text_Value__c, 'Existing attribute should be updated');
        
        // Verify new attribute was created
        List<Sponsorable_Attribute__c> allTextAttrs = [
            SELECT Id, Text_Value__c 
            FROM Sponsorable_Attribute__c 
            WHERE Attribute_Type__c = :textDef.Id
        ];
        System.assertEquals(2, allTextAttrs.size(), 'Should have 2 text attributes after upsert');
    }
    
    @IsTest
    static void testCreateMissingAttributes() {
        Sponsorable__c sponsorable = [SELECT Id FROM Sponsorable__c LIMIT 1];
        
        Test.startTest();
        List<Sponsorable_Attribute__c> newAttributes = SponsorableAttributeController.createMissingAttributes(sponsorable.Id);
        Test.stopTest();
        
        // Should create 3 missing attributes (checkbox, picklist, date - text and number already exist)
        System.assertEquals(3, newAttributes.size(), 'Should create 3 missing attributes');
        
        List<Sponsorable_Attribute__c> allAttributes = [
            SELECT Id 
            FROM Sponsorable_Attribute__c 
            WHERE Sponsorable__c = :sponsorable.Id
        ];
        
        System.assertEquals(5, allAttributes.size(), 'Should now have 5 total attributes');
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
    static void testSaveAttributesException() {
        List<Sponsorable_Attribute__c> invalidAttributes = new List<Sponsorable_Attribute__c>{
            new Sponsorable_Attribute__c() // Missing required fields
        };
        
        Test.startTest();
        try {
            SponsorableAttributeController.saveAttributes(invalidAttributes);
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Error updating'), 'Should contain error message');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testDefaultValueHandling() {
        Sponsorable__c sponsorable = [SELECT Id FROM Sponsorable__c LIMIT 1];
        
        // Create definition with default values
        Sponsorable_Attribute_Definition__c defWithDefaults = new Sponsorable_Attribute_Definition__c(
            Name = 'Test Default Values',
            Data_Type__c = 'Number',
            Required__c = false,
            Default_Value__c = '42.5'
        );
        insert defWithDefaults;
        
        Test.startTest();
        List<SponsorableAttributeController.AttributeWrapper> wrappers = SponsorableAttributeController.getSponsorableAttributes(sponsorable.Id);
        Test.stopTest();
        
        // Find the wrapper with default values
        SponsorableAttributeController.AttributeWrapper testWrapper = null;
        for (SponsorableAttributeController.AttributeWrapper wrapper : wrappers) {
            if (wrapper.definition.Name == 'Test Default Values') {
                testWrapper = wrapper;
                break;
            }
        }
        
        System.assertNotEquals(null, testWrapper, 'Should find test wrapper');
        System.assertEquals(42.5, testWrapper.attribute.Number_Value__c, 'Should set default number value');
    }
    
    @IsTest
    static void testInvalidDefaultValueHandling() {
        Sponsorable__c sponsorable = [SELECT Id FROM Sponsorable__c LIMIT 1];
        
        // Create definition with invalid default values
        Sponsorable_Attribute_Definition__c defWithInvalidDefaults = new Sponsorable_Attribute_Definition__c(
            Name = 'Test Invalid Defaults',
            Data_Type__c = 'Number',
            Required__c = false,
            Default_Value__c = 'not-a-number'
        );
        insert defWithInvalidDefaults;
        
        Test.startTest();
        List<SponsorableAttributeController.AttributeWrapper> wrappers = SponsorableAttributeController.getSponsorableAttributes(sponsorable.Id);
        Test.stopTest();
        
        // Find the wrapper with invalid default values
        SponsorableAttributeController.AttributeWrapper testWrapper = null;
        for (SponsorableAttributeController.AttributeWrapper wrapper : wrappers) {
            if (wrapper.definition.Name == 'Test Invalid Defaults') {
                testWrapper = wrapper;
                break;
            }
        }
        
        System.assertNotEquals(null, testWrapper, 'Should find test wrapper');
        System.assertEquals(0, testWrapper.attribute.Number_Value__c, 'Should default to 0 for invalid number');
    }
}