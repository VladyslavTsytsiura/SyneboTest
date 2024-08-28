public inherited sharing class CaseTriggerHandler {

    public static void updateAccountCaseCounts(List<Case> newCases, Map<Id, Case> oldCaseMap) {
        Set<Id> accountIds = new Set<Id>();

        for (Case newCase : newCases) {
            Case oldCase = oldCaseMap?.get(newCase.Id);

            if (newCase.IsClosed != oldCase?.IsClosed || newCase.AccountId != oldCase?.AccountId) {
                if (oldCase?.AccountId != null) accountIds.add(oldCase.AccountId);
                if (newCase?.AccountId != null) accountIds.add(newCase.AccountId);
            }
        }

        updateCaseCountsForAccounts(accountIds);
    }

    @TestVisible
    private static void updateCaseCountsForAccounts(Set<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return;
        }

        Map<Id, Integer> closedCaseMap = new Map<Id, Integer>();
        Map<Id, Integer> openCaseMap = new Map<Id, Integer>();

        for (AggregateResult ar : [
            SELECT AccountId, IsClosed, COUNT(Id) CaseCount
            FROM Case
            WHERE AccountId IN :accountIds
            GROUP BY AccountId, IsClosed
        ]) {
            if ((Boolean)ar.get('IsClosed')) {
                closedCaseMap.put((Id)ar.get('AccountId'), (Integer)ar.get('CaseCount'));
            } else {
                openCaseMap.put((Id)ar.get('AccountId'), (Integer)ar.get('CaseCount'));
            }
        }

        List<Account> accountsToUpdate = new List<Account>();
        for (Id accountId : accountIds) {
            Account account = new Account(
                Id = accountId,
                ClosedCases__c = closedCaseMap.containsKey(accountId) ? closedCaseMap.get(accountId) : 0,
                OpenCases__c = openCaseMap.containsKey(accountId) ? openCaseMap.get(accountId) : 0
            );
            accountsToUpdate.add( account );
        }

        update accountsToUpdate;
    }
}