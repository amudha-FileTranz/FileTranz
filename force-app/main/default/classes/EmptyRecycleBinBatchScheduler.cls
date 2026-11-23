/*
 * Purpose : To schedule the EmptyRecycleBinBatch class
 * Author  : Giri
 */
public with sharing class EmptyRecycleBinBatchScheduler implements Schedulable{
    public Interface EmptyRecycleBinBatchSchedulerInterface{
        void execute(SchedulableContext sc);
    }    

    public void execute(SchedulableContext sc) {
        Database.executebatch(new EmptyRecycleBinBatch(), 200);
    }
}