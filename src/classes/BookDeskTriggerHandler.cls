public with sharing class BookDeskTriggerHandler {
	
	public static void controlExistingBooking(List<SObject> newList, Map<Id, SObject> oldMap)
	{
		List<Desk_Booking__c> objs = (List<Desk_Booking__c>) newList;

		Boolean isUpdate = false;

		if(oldMap != null)
		{
			isUpdate = true;
		}

		//Control if all the records has a user

		//We need to control  all record inside the list if they get same day booking
		//And then query if existing record exist with same User and same day

		Map<Integer, Date> dateBookingByIndexTriggerList = new Map<Integer, Date>();
		Map<Integer, String> userIdByIndexTriggerList = new Map<Integer, String>(); 		
		
		Integer i = 0;
		Integer j = 0;

		for(i = 0; i < objs.size(); i++)
		{
			Desk_Booking__c obj = objs[i];

			dateBookingByIndexTriggerList.put(i, obj.Booking_Day__c);

			if(obj.User__c == null)
			{
				obj.addError('User is required for a booking.');
				continue;
			}

			if(obj.Booking_Day__c == null)
			{
				obj.addError('Booking Date is required for a booking.');
				continue;
			}

			userIdByIndexTriggerList.put(i, obj.User__c);

			for(j = 0; j < objs.size(); j++)
			{
				Desk_Booking__c obj2 = objs[j];
				if(obj2.User__c == null)
				{
					obj2.addError('User is required for a booking');
				}

				if(obj2.Booking_Day__c == null)
				{
					obj2.addError('Booking date is required for a booking');
				}

				if(i != j)
				{
				
					if(obj.Booking_Day__c == obj2.Booking_Day__c && obj.User__c == obj2.User__c)
					{
						obj.addError('Duplicate value found in the batch');
						obj2.addError('Duplicate value found in the batch');
					}
				}
			}
			
		}

		List<Desk_Booking__c> existingBookings = [Select Id,User__c, Booking_Day__c From Desk_Booking__c Where Booking_Day__c IN :dateBookingByIndexTriggerList.values() AND User__c IN :userIdByIndexTriggerList.values()];
		
		i = 0;

		//Find any Duplicates
		for(Desk_Booking__c existingBooking :existingBookings)
		{
			if(existingBooking.User__c == objs[i].User__c && existingBooking.Booking_Day__c == objs[i].Booking_Day__c)
			{
				objs[i].addError('Existing booking found for the same day. Please Edit the existing book or delete it (ID of duplicate:' + existingBooking.Id +').');
			}

			i++;
		}
	}
}