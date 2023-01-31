public class OpportunityTriggerHandler {
    public static void beforeUpdateHandler(List<Opportunity> newOpportunities, Map<Id,Opportunity> oldOppMap){
        List<Opportunity> sendOpps = new List<Opportunity>();
        for(Opportunity o : newOpportunities){
            if(o.stageName == 'Closed Won' && oldOppMap.get(o.Id).StageName != 'Closed Won'){
                sendOpps.add(o);
            }
        }

        if(sendOpps.size() > 0){
            congaStarter(sendOpps[0].Id, 'Receipt');
        }
    }

    @future(callout=true) private static void congaStarter(Id oId, String settings_name){
        CongaEmailHelper emailSend = new CongaEmailHelper(oId, settings_name);
        emailSend.sendTemplateEmail();
    }
}