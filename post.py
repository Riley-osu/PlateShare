

import string

postID:int = 0;
foodType:string = "";
availableSlots:int = 0;
currentReservations:int = 0;
headPicture:string #current a string until image passing is finished



def Add_Reservation(amount:int) -> bool:
    """Add a Reservation(s), returns false if post is full"""
    if availableSlots > currentReservations + amount:
        currentReservations += amount;
        return True;
    return False;

def Remove_Reservation(amount:int) -> bool:
    """Remove a Reservation(s), returns false if told to go negative"""
    if currentReservations - amount >= 0:
        currentReservations -= amount;
        return True;
    
    #Reservation was told to be negative
    currentReservations = 0;
    return False;

def Get_Remaining_Spots() -> int:
    return availableSlots;

def Make_Post(maxSize:int, foodType:string, picture:string) -> bool:
    """Make a post, defining size, foodtype, and passing an image.
picture variable currently accepts only strings until pictures are finished"""
    availableSlots = maxSize;
    foodType = foodType;
    headPicture = picture;

    return True;

