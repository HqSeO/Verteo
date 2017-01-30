trigger BookDeskTrigger on Desk_Booking__c (
	before insert, 
	before update, 
	before delete, 
	after insert, 
	after update, 
	after delete, 
	after undelete) {

		if (Trigger.isBefore) {
	    	//call your handler.before method
	    	if(Trigger.isInsert || Trigger.isUpdate)
	    		BookDeskTriggerHandler.controlExistingBooking(Trigger.new, Trigger.oldMap);
	    
		} else if (Trigger.isAfter) {
	    	//call handler.after method
	    
		}
}