@IsTest
private class CaseTriggerHandlerTest {

    @TestSetup
    static void makeData() {
        List<Account> accounts = TestDataFactory.createAccounts(2, true);

        List<Case> cases = new List<Case>();
        cases.addAll(TestDataFactory.createCasesOnAccounts(accounts, 1, 'New', false));
        cases.addAll(TestDataFactory.createCasesOnAccounts(accounts, 1, 'Closed', false));

        insert cases;
    }

    @IsTest
    static void testUpdateAccountCaseCountsOnInsert() {
        List<Account> accounts = [SELECT Id, OpenCases__c, ClosedCases__c FROM Account];

        for (Account acc : accounts) {
            Assert.areEqual(1, acc.OpenCases__c, 'Open case count should be 1 initially');
            Assert.areEqual(1, acc.ClosedCases__c, 'Closed case count should be 1 initially');
        }
        
        Case newOpenCase = TestDataFactory.createCasesOnAccounts(accounts, 1, 'New', false)[0];
        Case newClosedCase = TestDataFactory.createCasesOnAccounts(accounts, 1, 'Closed', false)[0];
        
        Test.startTest();
        insert new List<Case>{ newOpenCase, newClosedCase };
        Test.stopTest();

        Account updatedAccount = [SELECT OpenCases__c, ClosedCases__c FROM Account WHERE Id =: accounts[0].Id];
        Assert.areEqual(2, updatedAccount.OpenCases__c, 'Open case count should be updated to 2');
        Assert.areEqual(2, updatedAccount.ClosedCases__c, 'Closed case count should be updated to 2');
    }

    @IsTest
    static void testUpdateAccountCaseCountsOnUpdateStatus() {
        List<Account> accounts = [SELECT Id FROM Account];
        List<Case> cases = [SELECT Id, Status, AccountId FROM Case WHERE AccountId =: accounts[0].Id];

        Case caseToUpdate = cases[0];
        caseToUpdate.Status = 'Closed';

        Test.startTest();
        update caseToUpdate;
        Test.stopTest();

        Account updatedAccount = [SELECT OpenCases__c, ClosedCases__c FROM Account WHERE Id =: accounts[0].Id];
        Assert.areEqual(0, updatedAccount.OpenCases__c, 'Open case count should be 0');
        Assert.areEqual(2, updatedAccount.ClosedCases__c, 'Closed case count should be updated to 2');
    }

    @IsTest
    static void testUpdateAccountCaseCountsOnUpdateAccountId() {
        List<Account> accounts = [SELECT Id FROM Account];
        List<Case> cases = [SELECT Id, Status, AccountId FROM Case WHERE AccountId =: accounts[0].Id];

        Case caseToUpdate = cases[0];
        caseToUpdate.Status = 'Closed';
        caseToUpdate.AccountId = accounts[1].Id;

        Test.startTest();
        update caseToUpdate;
        Test.stopTest();

        List<Account> updatedAccounts = [SELECT OpenCases__c, ClosedCases__c FROM Account];
        Assert.areEqual(0, updatedAccounts[0].OpenCases__c, 'Open case count should be 0');
        Assert.areEqual(2, updatedAccounts[1].ClosedCases__c, 'Closed case count of Account 2, should be updated to 2');
    }

    @IsTest
    static void testUpdateAccountCaseCountsOnDelete() {
        List<Account> accounts = [SELECT Id FROM Account];
        List<Case> cases = [SELECT Id, AccountId FROM Case WHERE AccountId =: accounts[0].Id];

        Test.startTest();
        delete cases[0];
        Test.stopTest();
        
        Account updatedAccount = [SELECT OpenCases__c, ClosedCases__c FROM Account WHERE Id =: accounts[0].Id];
        Assert.areEqual(0, updatedAccount.OpenCases__c, 'Open case count should be 0');
        Assert.areEqual(1, updatedAccount.ClosedCases__c, 'Closed case count should remain 1');
    }

    @IsTest
    static void testUpdateAccountCaseCountsOnUndelete() {
        List<Account> accounts = [SELECT Id FROM Account];
        List<Case> cases = [SELECT Id, AccountId FROM Case WHERE AccountId =: accounts[0].Id];
        delete cases;

        Test.startTest();
        Case[] savedAccts = [SELECT Id, AccountId FROM Case WHERE AccountId =: accounts[0].Id ALL ROWS];
        undelete savedAccts;
        Test.stopTest();
        
        Account updatedAccount = [SELECT OpenCases__c, ClosedCases__c FROM Account WHERE Id =: accounts[0].Id];
        Assert.areEqual(1, updatedAccount.OpenCases__c, 'Open case count should be 1');
        Assert.areEqual(1, updatedAccount.ClosedCases__c, 'Open case count should be 1');
    }

    @IsTest
    static void testBulkCaseHandling() {
        List<Account> accounts = TestDataFactory.createAccounts(201, true);

        List<Case> cases = new List<Case>();
        cases.addAll(TestDataFactory.createCasesOnAccounts(accounts, 1, 'New', false));
        cases.addAll(TestDataFactory.createCasesOnAccounts(accounts, 1, 'Closed', false));
        
        insert cases;

        List<Account> updatedAccounts = [SELECT Id, OpenCases__c, ClosedCases__c FROM Account WHERE Id IN: accounts];
        for (Account acc : updatedAccounts) {
            Assert.areEqual(1, acc.OpenCases__c, 'Open case count should be 1 for each account');
            Assert.areEqual(1, acc.ClosedCases__c, 'Closed case count should be 1 for each account');
        }

        for (Case c : cases) {
            c.Status = c.Status == 'New' ? 'Closed' : 'New';
        }

        Test.startTest();
        update cases;
        Test.stopTest();

        updatedAccounts = [SELECT OpenCases__c, ClosedCases__c FROM Account WHERE Id IN: accounts];
        for (Account acc : updatedAccounts) {
            Assert.areEqual(1, acc.OpenCases__c, 'Open case count should be 1 after update for each account');
            Assert.areEqual(1, acc.ClosedCases__c, 'Closed case count should be 1 after update for each account');
        }
    }

    @IsTest
    static void testBulkCaseHandling10CasesPerAccount() {
        List<Account> accounts = [SELECT Id FROM Account];

        List<Case> cases = new List<Case>();
        cases.addAll(TestDataFactory.createCasesOnAccounts(accounts, 5, 'New', false));
        cases.addAll(TestDataFactory.createCasesOnAccounts(accounts, 5, 'Closed', false));
        
        insert cases;

        List<Account> updatedAccounts = [SELECT Id, OpenCases__c, ClosedCases__c FROM Account WHERE Id IN: accounts];
        for (Account acc : updatedAccounts) {
            Assert.areEqual(6, acc.OpenCases__c, 'Open case count should be 6 for each account');
            Assert.areEqual(6, acc.ClosedCases__c, 'Closed case count should be 6 for each account');
        }

        for (Case c : cases) {
            c.Status = c.Status == 'New' ? 'Closed' : 'New';
            c.AccountId = c.AccountId == accounts[0].Id ? accounts[1].Id : accounts[0].Id;
        }

        Test.startTest();
        update cases;
        Test.stopTest();

        updatedAccounts = [SELECT OpenCases__c, ClosedCases__c FROM Account WHERE Id IN: accounts];
        for (Account acc : updatedAccounts) {
            Assert.areEqual(6, acc.OpenCases__c, 'Open case count should be 6 after update for each account');
            Assert.areEqual(6, acc.ClosedCases__c, 'Closed case count should be 6 after update for each account');
        }
    }

    @IsTest
    static void testBulkCaseHandlingWith20CasesForOneAccount() {
        List<Account> accounts = [SELECT Id FROM Account];

        List<Case> cases = new List<Case>();
        cases.addAll(TestDataFactory.createCasesOnAccounts(new List<Account>{accounts[0]}, 10, 'New', false));
        cases.addAll(TestDataFactory.createCasesOnAccounts(new List<Account>{accounts[0]}, 10, 'Closed', false));

        insert cases;

        LIst<Account> updatedAccounts = [SELECT OpenCases__c, ClosedCases__c FROM Account WHERE Id =: accounts];
        // +1 from makeData
        Assert.areEqual(11, updatedAccounts[0].OpenCases__c, 'Open case count should be 11');
        Assert.areEqual(11, updatedAccounts[0].ClosedCases__c, 'Closed case count should be 11');

        for (Case c : cases) {
            c.Status = c.Status == 'New' ? 'Closed' : 'New';
            c.AccountId = accounts[1].Id;
        }

        Test.startTest();
        update cases;
        Test.stopTest();

        updatedAccounts = [SELECT OpenCases__c, ClosedCases__c FROM Account WHERE Id =: accounts];
        // +1 from makeData
        Assert.areEqual(1, updatedAccounts[0].OpenCases__c, 'Open case count should be 1 for Account 1');
        Assert.areEqual(1, updatedAccounts[0].ClosedCases__c, 'Closed case count should be 1 for Account 1');
        Assert.areEqual(11, updatedAccounts[1].OpenCases__c, 'Open case count should be 11 after update for Account 2');
        Assert.areEqual(11, updatedAccounts[1].ClosedCases__c, 'Closed case count should be 11 after update for Account 2');
    }

    @IsTest
    static void testNoCasesAssociated() {
        Account account = TestDataFactory.createAccounts(1, true)[0];
        List<Case> cases = new List<Case>();

        Test.startTest();
        insert cases;
        Test.stopTest();

        Account updatedAccount = [SELECT OpenCases__c, ClosedCases__c FROM Account WHERE Id = :account.Id];
        
        Assert.areEqual(0, updatedAccount.OpenCases__c, 'Open case count should be 0');
        Assert.areEqual(0, updatedAccount.ClosedCases__c, 'Closed case count should be 0');
    }
}
