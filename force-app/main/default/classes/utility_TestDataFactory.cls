/**
    @author: Yang Yu
    @title: Salesforce Developer
    @company: Cansel
    @date: 2021-05-20
    @description: 
    Use this class to create sample data.
	//2022-08-04, add back method setupPlantUS()
*/
public with sharing class utility_TestDataFactory {
    
    public static Plant__c setupPlant() {         
        Plant__c plant = new Plant__c();
        plant.Name = '1001';
        plant.Plant_Name__c = 'Test Plant 1';
        plant.Address__c = '3900 North Fraser Way';
        plant.City__c = 'Burnaby';
        plant.Province__c = 'BC';
        plant.Postal_Code__c = 'V5J 5H6';
        plant.Region__c = 'West';
        plant.Country__c = 'CA';
        plant.Phone_Number__c = '604-111-1111';
        plant.Email_Address__c = 'testPlant1@abc.com';
        plant.Active__c = true;
        return plant;
    }
    
    public static Plant__c setupPlantUS() {         
        Plant__c plant = new Plant__c();
        plant.Name = '5000';
        plant.Plant_Name__c = 'Test Plant 5000';
        plant.Address__c = '3900 North Fraser Way';
        plant.City__c = 'Vancouver';
        plant.Province__c = 'WA';
        plant.Postal_Code__c = '48000';
        plant.Region__c = 'West';
        plant.Country__c = 'US';
        plant.Phone_Number__c = '222-111-1111';
        plant.Email_Address__c = 'testPlant5000@abc.com';
        plant.Active__c = true;
        return plant;
    }
    
    public static Account setupAccount(Plant__c plant){
        List<RecordType> accountRecordType = [SELECT Id, Name 
                                              FROM RecordType 
                                              WHERE SobjectType='Account' AND Name='Standard Account'];
        Account account = new Account();
        account.Plant__c = plant.Id;
        account.RecordTypeId = accountRecordType[0].Id;
        account.Name = 'Extreme Measures Inc';
        account.SILK_CustomerCode__c = 'SFDC';
        account.Primary_Industry__c = 'Miscellaneous';
        account.Secondary_Industry__c = 'Other';
        account.Language__c = 'EN';
        account.SAP_Tax_Classification__c = 'GST, PST (HST)';
        account.Currency__c = 'CAD';
        account.AccountType__c = 'CASH';
        account.SAP_Terms__c = 'NT00';
        return account;
    }

    public static Contact setupContact(Account account){
        Contact contact = new Contact();
        contact.FirstName = 'EP1';
        contact.LastName = 'Contact';
        contact.AccountId = account.Id;
        contact.Primary_Industry__c = 'Miscellaneous';
        contact.Contact_Role__c = 'All contact roles';
        contact.Portal_Access__c = 'No Access';
        contact.Email = 'CMEP1@test.com';
        return contact;
    }
    /*
    public static MC4SF__MC_Campaign__c setupMCCampaign(){
        Datetime dateLastMonth = System.today() - 30;
        String dateString = String.valueOf(dateLastMonth);
        MC4SF__MC_Campaign__c MCCampaign = new MC4SF__MC_Campaign__c();
        MCCampaign.MC4SF__MailChimp_ID__c = 'ea715d6342' + dateString;
        MCCampaign.MC4SF__Send_Time__c = dateLastMonth;
        return MCCampaign;
    }
    
    public static MC4SF__MC_Campaign_Hourly_Stats__c setupMCHourlyStats(MC4SF__MC_Campaign__c MCCampaign){
        Datetime dateLastMonth = System.today() - 30;
        String dateString = String.valueOf(dateLastMonth);
        MC4SF__MC_Campaign_Hourly_Stats__c MCHourlyStats = new MC4SF__MC_Campaign_Hourly_Stats__c();
        MCHourlyStats.MC4SF__MC_Campaign__c = MCCampaign.Id;
        MCHourlyStats.MC4SF__Statistics_Hour__c = System.today();
        MCHourlyStats.MC4SF__Recipients_Click__c = 2;
        MCHourlyStats.MC4SF__Unique_Opens__c = 5;
        return MCHourlyStats;
    }
    */
    //Product2
    public static Product2 setupProduct(){
        Product2 product = new Product2();
        product.Name = 'TestProduct CW1M';
        product.Family = '3M';
        product.IsActive = True;
        product.Item_Category__c = '25000';
        product.Cost__c = 100;
        product.List_Price__c = 100;
        product.SAP_Id__c = 'CW1M585655';
        return product;
    }

    // Price Book
    public static Pricebook2 setupPB(){
        Pricebook2 pb2 = new Pricebook2();
        pb2.Name = 'Standard Price Book';
        pb2.IsActive = true;
        //pb2.IsStandard = true;
        return pb2;
    }

    //PEB
    public static PricebookEntry setupPBE(String Product2Id, String Pricebook2Id){
        PricebookEntry peb = new PricebookEntry();
        //peb.Name = 'Test Bronze';
        peb.IsActive = true;
        peb.CurrencyIsoCode = 'CAD';
        peb.Pricebook2Id = Pricebook2Id;
        peb.Product2Id = Product2Id;
        peb.UnitPrice = 100;
        return peb;
    }

    //Opportunity
    public static Opportunity setupOpp(String AccountId, String PlantId, String Pricebook2Id){
        Opportunity opp = new Opportunity();
        opp.Name = 'Oppo Name';
        opp.StageName = 'Prospect';
        opp.AccountId = AccountId;
        opp.Plant__c = PlantId;
        opp.CloseDate = System.now().date().addDays(7); 
        opp.CurrencyIsoCode = 'CAD';
        opp.Pricebook2Id = Pricebook2Id;
        return opp;
    }

    //Quote
    public static Quote setupQuote(String ContactId, String OpportunityId, String Pricebook2Id){
        Quote quote = new Quote();
        quote.Name = 'Quote Name';
        quote.Status = 'Draft';
        quote.ExpirationDate = System.now().date().addDays(7); 
        quote.CurrencyIsoCode = 'CAD';
        quote.ContactId = ContactId;
        quote.Phone = '6045353535';
        quote.Email = 'cansel.test@cansel.com.invalid';
        quote.OpportunityId = OpportunityId;
        quote.Pricebook2Id = Pricebook2Id;
        return quote;
    }
    
    //SVMXC__Installed_Product__c
    public static SVMXC__Installed_Product__c setupInstalledProduct(Account account, Contact contact, Product2 product){
        SVMXC__Installed_Product__c installedProduct = new SVMXC__Installed_Product__c();
        installedProduct.SVMXC__Product__c = product.Id;
        installedProduct.SVMXC__Status__c = 'Installed';
        installedProduct.SVMXC__Company__c = account.Id;
        installedProduct.Name = product.Id;
        installedProduct.Z1_Contact_Email__c = contact.Email;
        return installedProduct;
    }
    
    //SVMXC__Warranty__c
    public static SVMXC__Warranty__c setupProductWarranty(SVMXC__Installed_Product__c installedProduct){
        SVMXC__Warranty__c productWarranty = new SVMXC__Warranty__c();
        productWarranty.SVMXC__Installed_Product__c = installedProduct.Id;
        return productWarranty;
    }
    
    public static SVMXC__Service_Order__c setupWorkOrder(String plantNum, SVMXC__Installed_Product__c installedProduct, Contact InputContact, SVMXC__Service_Group_Members__c Technician){
        SVMXC__Service_Order__c WorkOrder = new SVMXC__Service_Order__c();
       	WorkOrder.Planning_Plant__c = plantNum;
        WorkOrder.Repair_Plant__c = plantNum;
        WorkOrder.CurrencyIsoCode = 'CAD';
        WorkOrder.SVMXC__Order_Type__c = 'Field Service';
        WorkOrder.ServProd__c = 'NW-25000-1';
        WorkOrder.Customer_PO_Number__c = 'TestingPONumber';
        WorkOrder.SVMX_ERP_Billing_Type__c = 'Z003 - T/M (Paid)';
        WorkOrder.SVMXC__Group_Member__c = Technician.Id;
        WorkOrder.SVMXC__Contact__c = InputContact.Id;
        WorkOrder.SVMXC__Component__c = installedProduct.Id;
		return WorkOrder;
    }
     Public static Invoice__c setupInvoice(Account account, Contact contact){
        Invoice__c newInvoice = new Invoice__c();
        newInvoice.Account__c = account.Id;
        newInvoice.Name = '123 Test';
        newInvoice.Contact_Email__c=contact.Email;
        return newInvoice;
    }
    //builds only E-commerce type cases
    public static Case setupCaseWithInvoice(Invoice__c invoice){
        Case newCase = new Case();
        newCase.Subject='New case created for test';
        newCase.Invoice__c= invoice.Id;
        newCase.AccountId = invoice.Account__c;
        newCase.RecordTypeId ='0127A000000XiufQAC';
        return newCase;
    }
}