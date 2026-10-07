# This file creates a class for listings
import firebaseToFlutter #Uses this file to communicate between Flutter and Firebase
from dataclasses import dataclass

@dataclass #dataclass so that editing a varible in one listing will not affect another
class listing: 
    #variables for each part of a listing
    postID:str = ""
    foodType:str = ""
    availableReservations:int = 0
    currentReservations:int = 0
    headPicture:str = "" #currently a string until image passing is finished
    description:str = ""
    location:str = ""
    organizationID:str = ""
    startTime:str = ""
    endTime:str = ""
    
    def __init__(self, maxReservations: int, foodDescription:str, foodType:str, location:str, organizationID:int, startTime:str, endTime:str, picture):
        """Add a new listing object and update the database with the given information. Returns false if it failed to update the database.
            Pass time using the following:
            from datatime import datetime
            startTime = datetime(time).isoformat()"""
        self.availableReservations = maxReservations
        self.currentReservations = 0
        self.description = foodDescription
        self.headPicture = picture
        self.foodType = foodType
        self.location = location
        self.organizationID = organizationID
        self.startTime = startTime
        self.endTime = endTime
        self.postID = str(organizationID) + location + startTime

        firebaseToFlutter.add_listing(self.foodType,self.description,self.availableReservations,self.location,
                                      self.organizationID,self.startTime,self.endTime, self.headPicture)
        
    #function for adding user reservations using the current number of reservations
    def add_Reservation(self, amount: int) -> bool:
        """Updates both the object and the database. Returns false if it failed to do so"""
        
        # if currentReservation amount + new reservation is less than or equal to 
        # available reservations succesfully add reservation
        if self.currentReservations + amount <= self.available_Reservations:
            self.currentReservations += amount
            return firebaseToFlutter.edit_listing(self.postID, "quantity", self.availableReservations-self.current_Reservations)
        return False
    
    # Function for removing user reservation 
    def remove_Reservation(self,amount: int) -> bool:
        """Updates both the object and the database. Returns false if it failed to do so"""
        if self.current_Reservations - amount >= 0:
            self.current_Reservations -= amount
            return firebaseToFlutter.edit_listing(self.postID, "quantity", self.availableReservations-self.current_Reservations)
        
        self.current_reservations = 0
        return False
    
    #Function to pull remaining reservation spots
    def get_remaining_spots(self) -> int:
        """Gets the remaining spots available in the given listing."""
        return firebaseToFlutter.get_database_field(listing, self.postID, "quantity")
        #return self.available_Reservations - self.current_Reservations
    
    def get_time_until_start(self) -> str:
        return ""

    def get_time_until_end(self) -> str:
        return ""

