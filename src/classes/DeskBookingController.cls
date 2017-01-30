/*
Name:  DeskBookingController.cls
Copyright © 2016  Sylvain Picory
======================================================
======================================================
Purpose:
-------

This page will display the booking app which will be used to edit or create a desk booking

======================================================
======================================================
History
------- 
Ver. Author        	   Date        Detail
1.0  Sylvain Picory    2016-10-25  Initial draft of code.
*/
public with sharing class DeskBookingController {
	public Boolean isEdit {get; set;}
	public Boolean hasError {get; set;}

	public Desk_Booking__c currentRecord {get; set;}

	public List<SelectOption> floorsList {get; set;}
	public List<SelectOption> buildingsList {get; set;}

    public String selectedBuilding {get; set;}
    public String selectedFloor {get; set;}

    public Integer rowNumber {get; set;}
    public List<DeskWrapperRowDisplay> desksUIDisplay {get; set;}

    public String deskClickedId {get; set;}

    public String userName {get; set;}

    public ApexPages.StandardController controller {get; set;}

    //Constructor
	public DeskBookingController(ApexPages.StandardController controller) {
		currentRecord = (Desk_Booking__c) controller.getRecord();
		hasError = false;
		this.controller = controller;

		if(currentRecord.Id != null)
		{
			isEdit = true;

			//Refresh the record
			currentRecord = [SELECT Desk__c,Desk__r.Name, Booking_Day__c,User__c, User__r.Name FROM Desk_Booking__c Where Id = :currentRecord.Id limit 1];
			controlDateInput();
		}
		else{
			isEdit = false;
			currentRecord.Booking_Day__c = System.today();	
		}

    	userName = [Select Id, Name From User Where Id = :UserInfo.getUserId() Limit 1].Name;

    	rowNumber = Integer.valueOf(DeskBookingUIConfig__c.getInstance().Desk_per_Row__c);

    	buildingsList = new List<SelectOption>();
    	floorsList = new List<SelectOption>();
    	desksUIDisplay = new List<DeskWrapperRowDisplay>();

    	refreshBuildingList();

    }

    public void refreshFloorList(){
    	floorsList.clear();

    	//This should never happen but in case
    	if(selectedBuilding == null)
    		return;

    	Map<Id, Floor__c> floors = new Map<Id, Floor__c>([Select Id, Floor_Number__c From Floor__c Where Building__c = :selectedBuilding]);

    	if(floors == null || floors.size() == 0)
    	{
    		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Error system 2, please contact your administrator.'));
    		hasError = true;
    		return;
    	}

    	if(selectedFloor != null && !floors.containsKey(selectedFloor))
    	{
    		selectedFloor = null;
    	}

    	for(Floor__c floor :floors.values())
    	{
    		if(selectedFloor == null)
    		{
    			selectedFloor = floor.Id;
    		}

    		floorsList.add(new SelectOption(floor.Id, String.valueOf(floor.Floor_Number__c)));
    	}

    	refreshDeskList();
    }

    public void refreshBuildingList(){
    	List<Building__c> buildings = [SELECT Id, Name FROM Building__c];

    	if(buildings == null || buildings.size() == 0)
    	{
    		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Error system 1, please contact your administrator.'));
    		hasError = true;
    		return;
    	}

    	for(Building__c building :buildings)
    	{
    		if(selectedBuilding == null)
    		{
    			selectedBuilding = building.Id;
    		}

    		buildingsList.add(new SelectOption(building.Id, building.Name));
    	}

    	refreshFloorList();
    }

    public void refreshDeskList(){
    	//This should not happen
    	if(selectedFloor == null || selectedBuilding == null || currentRecord.Booking_Day__c == null)
    		return;

    	if(desksUIDisplay.size() > 0)
    		desksUIDisplay.clear();

    	List<Desk__c> desks = [SELECT Name, Id, Floor__c, Floor__r.Building__c, (SELECT Desk__c,Desk__r.Name, Booking_Day__c,User__c, User__r.Name FROM Desk_Bookings__r Where Booking_Day__c = :currentRecord.Booking_Day__c) FROM Desk__c where Floor__c = :selectedFloor And Floor__r.Building__c = :selectedBuilding ORDER BY Name ASC];

    	if(desks == null || desks.size() == 0)
    	{
    		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Error system 3, please contact your administrator.'));
    		hasError = true;
    		return;
    	}

    	Integer i = 1;
    	List<DeskWrapper> wrappersList = new List<DeskWrapper>();

    	for(Desk__c desk :desks)
    	{
    		if(desk.Desk_Bookings__r != null && desk.Desk_Bookings__r.size() == 1)
    		{
    			if(isEdit && desk.Desk_Bookings__r[0].Id == currentRecord.Id)
    			{
    				wrappersList.add(new DeskWrapper(currentRecord));
    			}
    			else{
    				wrappersList.add(new DeskWrapper(desk.Desk_Bookings__r[0]));
    			}
    		}
    		else
    		{
    			wrappersList.add(new DeskWrapper(desk, currentRecord.Booking_Day__c, userName));
    		}
    		if(i == rowNumber)
    		{
    			desksUIDisplay.add(new DeskWrapperRowDisplay(wrappersList));
    			wrappersList = new List<DeskWrapper>();
    			i = 1;
    		}
    		else{
    			i++;
    		}
    	}
    }

    public PageReference controlDateInput()
    {
    	if(currentRecord.Booking_Day__c < System.today())
    	{
    		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'You cannot select a past date'));
    		hasError = true;
    	}

    	if(!hasError)
    		refreshDeskList();

    	return null;
    }

   	public PageReference PreviousDay() { //user clicked previous button
   		currentRecord.Booking_Day__c = currentRecord.Booking_Day__c.addDays(-1);
      	refreshDeskList();
      	return null;
   	}

   	public PageReference NextDay() { //user clicked next button
   		currentRecord.Booking_Day__c = currentRecord.Booking_Day__c.addDays(1);
      	refreshDeskList();
      	return null;
   	}

   	public Boolean getDisablePreviousDay() { 
      	//this will disable the previous and beginning buttons
      	if (currentRecord.Booking_Day__c > system.today()) return false; else return true;
   	}

   	public PageReference refreshDeskPanel(){
   		refreshDeskList();
   		return null;
   	}

   	public PageReference refreshFloorPicklist(){
   		refreshFloorList();
   		return null;
   	}

   	public PageReference selectDesk(){
   		if(deskClickedId != null)
   		{
   			for(DeskWrapperRowDisplay deskInWrapperUI: desksUIDisplay)
   			{
   				for(DeskWrapper deskInWrapper :deskInWrapperUI.wrapperToDisplayInRow)
   				{
	   				if(deskInWrapper.deskBooking.Desk__c == deskClickedId && deskInWrapper.deskBooking.User__c == UserInfo.getUserId())
	   				{
	   					if(deskInWrapper.isBooked)
	   					{
	   						deskInWrapper.isBooked = false;
	   					}
	   					else{
	   						deskInWrapper.isBooked = true;
	   						currentRecord = (Desk_Booking__c) controller.getRecord();
					    	currentRecord.Desk__c = deskInWrapper.deskBooking.Desk__c;
					    	currentRecord.User__c = deskInWrapper.deskBooking.User__c;
					    	currentRecord.Name = 'Booking ' + deskInWrapper.deskBooking.User__r.Name + ' - ' + currentRecord.Booking_Day__c + ' Desk ' + deskInWrapper.deskBooking.Desk__r.Name;
	   					}
	   				}

	   				//Unselect previous desk if user click another desk
	   				if(deskInWrapper.isBooked == true && deskInWrapper.deskBooking.User__c == UserInfo.getUserId() && deskInWrapper.deskBooking.Desk__c != deskClickedId)
	   				{
	   					deskInWrapper.isBooked = false;
	   				}
	   			}
   			}
   		}
   		return null;
   	}

   	public with sharing class DeskWrapper{
   		public Boolean isBooked {get; set;}
   		public Desk_Booking__c deskBooking {get; set;}
   		public String userName {get; set;}

   		public DeskWrapper(Desk_Booking__c deskBooking)
   		{
   			this.isBooked = true;
   			this.deskBooking = deskBooking;
   			this.userName = deskBooking.User__r.Name;
   		}

   		public DeskWrapper(Desk__c desk, Date selectedDate, String userName)
   		{
   			this.isBooked = false;
   			this.deskBooking = new Desk_Booking__c();
   			deskBooking.Desk__c = desk.Id;
   			deskBooking.Desk__r = desk;
   			deskBooking.Booking_Day__c = selectedDate;
   			deskBooking.User__c = UserInfo.getUserId();
   			this.userName = userName;
   		}
   	}

   	public with sharing class DeskWrapperRowDisplay{
   		public List<DeskWrapper> wrapperToDisplayInRow {get; set;}

   		public DeskWrapperRowDisplay(List<DeskWrapper> wrappersList)
   		{
   			this.wrapperToDisplayInRow = wrappersList;
   		}
   	}

}