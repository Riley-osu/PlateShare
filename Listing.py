# This file creates a class for listings

import string
import FirebaseToFlutter #Uses this file to communicate between Flutter and Firebase


class listing: 
    #variables for each part of a listing
    postID:int = 0;
    foodType:string = "";
    availableReservations:int = 0;
    currentReservations:int = 0;
    headPicture:string = "lol not available" #currently a string until image passing is finished
    description:string = "yum yum time"
    location:string = "your moms house"
    organizationID:int = 67
    startTime:string = "3:00"
    endTime:string = "4:00"
    
    def __init__(self, max_Reservations: int, food_description: str, picture:str):
        #asks for number of reservations, description of the food, and a picture 
        
        #initializes with all reservations available
        self.availableReservations = max_Reservations
        
        #initializes with zero reservations
        self.currentReservations = 0
        
        self.food_description = food_description
        self.picture = picture
        
        # uses add_listing from FirebaseToFlutter 
        FirebaseToFlutter.add_listing(self.foodType,self.food_description,self.availableReservations,self.location,
                                      self.organizationID,self.startTime,self.endTime, self.headPicture)
        
    #function for adding user reservations using the current number of reservations
    def add_Reservation(self, amount: int) -> bool:
        
        # if currentReservation amount + new reservation is less than or equal to 
        # available reservations succesfully add reservation
        if self.currentReservations + amount <= self.available_Reservations:
            self.currentReservations += amount
            return True
        return False
    
    # Function for removing user reservation 
    def remove_Reservation(self,amount: int) -> bool:
        if self.current_Reservations - amount >= 0:
            self.current_Reservations -= amount
            return True
        self.current_reservations = 0
        return False
    
    #Function to pull remaining reservation spots
    def get_remaining_spots(self) -> int:
        return self.available_Reservations - self.current_Reservations
    

