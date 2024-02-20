public class testing implements Database.Batchable<sObject>,Database.Stateful, Database.AllowsCallouts{
     //Card Psag_539 Start
    List<TAD_Order__c> processedTadOrderList = new List<TAD_Order__c>();
    public Date sevenDaysAgo = System.today().addDays(-9);
    public Set<Id> orderid = new Set<Id>();
    //Getting the updated tad order id from delacon String to callout the delacon api
    public DelaconStringBatch(Set<Id> orderidSet) {
        this.orderid = orderidSet;
        system.debug('orderidSet in batch-----'+orderidSet);
    }
     //Card Psag_539 
    public Database.QueryLocator start(Database.BatchableCOntext bc){
        List<TAD_Order__c> palsList = [SELECT Id,Name,Delacon_String__c,Delacon_Api_Status__c,Delacon_Sale_converted_Date__c,ordexp_master_status__c,ordexp_purchase_date__c FROM TAD_Order__c where Id =:orderid];
        system.debug('TadOrderList-----'+palsList);
        // return this.tadOrderList;
        return Database.getQueryLocator([SELECT Id,Name,Delacon_String__c,Delacon_Api_Status__c,Delacon_Sale_converted_Date__c,ordexp_master_status__c,ordexp_purchase_date__c FROM TAD_Order__c where Id =:orderid]);
        
    }
    public void execute(Database.BatchableContext bc,List<TAD_Order__c> newTadOrderList){
        system.debug('newTadOrderList under execute method---'+newTadOrderList);
        Map<Id,String> storeResponseMap =new Map<Id,String>();
        if(!newTadOrderList.isempty()){
            
            // Update the parent records with the concatenated values cardPsag_538
            for (TAD_Order__c tadrecord : newTadOrderList) {
                if (tadrecord.Delacon_String__c != null) {
                    //  tadorderRecord.Delacon_String__c = DelaconStringMap.get(tadorderRecord.Id);
                    String delaconString =tadrecord.Delacon_String__c;
                    List<String> splitedstringList = delaconString.split(';') ;
                    system.debug('splitedstringList---'+splitedstringList);
                    for(String delString : splitedstringList){
                        system.debug('Saperated delacon String---'+splitedstringList);                        
                        Http http = new Http();           
                        HttpRequest request = new HttpRequest();     
                        String endPointUrl = System.Label.DelaconTrackingUrl;          
                        String authToken = System.Label.DelaconAuth;
                        system.debug('endPointUrl----41->'+endPointUrl);
                        system.debug('authToken----41->'+authToken);
                        request.setEndpoint(endPointUrl);            
                        request.setMethod('POST');
                        request.setHeader('Auth', authToken);
                        request.setHeader('Content-Type', 'text/plain');                        
                        request.setBody(delString);
                        system.debug('request----41->'+request.getBody());
                        HttpResponse response = http.send(request);
                        // system.debug('response----39->'+response);                
                        String responseBody = response.getBody().trim();
                        system.debug('response--body string--39->'+responseBody);   
                        if (!storeResponseMap.containsKey(tadrecord.Id)) {                            
                            storeResponseMap.put(tadrecord.Id, responseBody);
                        } else {
                            // Append to existing values if the map already contains Delacon String                            
                            storeResponseMap.put(tadrecord.Id, storeResponseMap.get(tadrecord.Id) +';'+responseBody);
                        }                        
                        
                    }
                    
                    
                }      
            }
           
            
            // Update the Tad Order records with the concatenated values storeCasesMap
            for (TAD_Order__c tadorder : newTadOrderList) {
                if (storeResponseMap.containsKey(tadorder.Id)) {                    
                    tadorder.Delacon_Api_Status__c = storeResponseMap.get(tadorder.Id);                 
                    
                }
            }
                this.processedTadOrderList.addAll(newTadOrderList);
            system.debug('storeResponseMap---'+storeResponseMap); 
            system.debug('processedTadOrderList-in Execute mathod--'+this.processedTadOrderList);
                    
        }       
        
    }
    
    public void finish(Database.BatchableContext BC) {
        
        system.debug('processedTadOrderList-in finish mathod--'+processedTadOrderList); 
        // Update all the records accumulated in the static variable
          if (!this.processedTadOrderList.isEmpty()) {
               try{
              update this.processedTadOrderList;
            } catch(DmlException e) {
                System.debug('The following exception has occurred: ' + e.getMessage());
                HandleCustomException.LogException(e);
                
            } 

} 
        
        // Clear the static variable to avoid retaining data in subsequent batches
        // processedTadOrderList.clear();
        System.debug('Batch processing completed.');
        
    }
    
}