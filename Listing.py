import string
import FirebaseToFlutter

from datetime import datetime


class listing: 
    postID:string = "";
    foodType:string = "";
    availableReservations:int = 0;
    currentReservations:int = 0;
    headPicture:string = "lol not available" #currently a string until image passing is finished
    description:string = "yum yum time"
    location:string = "your moms house"
    organizationID:int = 67
    startTime:string = datetime().now.isoformat()
    endTime:string = datetime(2026,10,20,15).isoformat()
    
    def __init__(self, maxReservations: int, foodDescription:str, foodType:str, location:str, organizationID:int, startTime:str, endTime:str, picture:str) -> bool:
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

        return FirebaseToFlutter.add_listing(self.foodType,self.food_description,self.availableReservations,self.location,
                                      self.organizationID,self.startTime,self.endTime, self.headPicture)
        
    def add_Reservation(self, amount: int) -> bool:
        """Updates both the object and the database"""
        if self.currentReservations + amount <= self.available_Reservations:
            self.currentReservations += amount
            return FirebaseToFlutter.edit_listing(self.postID, "quantity", self.availableReservations-self.current_Reservations)
        return False
    
    def remove_Reservation(self,amount: int) -> bool:
        if self.current_Reservations - amount >= 0:
            self.current_Reservations -= amount
            return FirebaseToFlutter.edit_listing(self.postID, "quantity", self.availableReservations-self.current_Reservations)
        
        self.current_reservations = 0
        return False
    
    def get_remaining_spots(self) -> int:
        return FirebaseToFlutter.get_database_field(listing, self.postID, "quantity")
        #return self.available_Reservations - self.current_Reservations
    
    def get_time_until_start(self) -> str:
        return ""

    def get_time_until_end(self) -> str:
        return ""

