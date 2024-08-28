@IsTest
public with sharing class TestDataFactory {
    public static List<Account> createAccounts(Integer numberOfAccounts, Boolean isInsert) {
        List<Account> accounts = new List<Account>();

        if (numberOfAccounts == 0) return accounts;

        for (Integer index = 0; index < numberOfAccounts; index++) {
            accounts.add(new Account(Name = 'Test Account ' + index));
        }

        if (isInsert) insert accounts;
        
        return accounts;
    }

    public static List<Case> createCasesOnAccounts(List<Account> accounts, Integer numberOfCases, String status, Boolean isInsert) {
        List<Case> cases = new List<Case>();

        if (numberOfCases == 0 || accounts.isEmpty()) return cases;

        for (Account acc : accounts) {
            for (Integer index = 0; index < numberOfCases; index++) {
                cases.add(new Case(Status = status, AccountId = acc.Id));
            }
        }

        if (isInsert) insert cases;
        
        return cases;
    }
}