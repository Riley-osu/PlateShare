# architure overview

PlateShare app follows a standard client-server architecture with hints of microservers. It consists of a mobile frontend used by both students and organizations, along with a centralized backend API for business logic and a non-relational database for storage.

## system components

### Frontend (Mobile App)
* **Framework:** 
* **Role:** 
* **State management**

### Backend (FastAPI)
* **Framework:** 
* **Role:** 
* **Hosting:** Render

### Database
* **System:** Firebase
* **Role:**

### Third-Party Services
* **Maps:**
* **AI:**
* **Email Notification:**

## 2. Core Data flows

To understand how the components interact, here are the primary system loops
### Flow A: Organization Posts leftover food
1. **Client:** Organization creates a 'listing', takes a photo and hits 'post'
2. **Client -> Backend** App sends a POST /listings request containing the food details, portion count and a picture of the food
3. **Backend -> DB** Server validates the user is an valid organization and saves the listing
4. **Backend -> User:** Server sends email notifications to student user about the new post.

### Flow B: Student reserves a portion
1. **Client:** Student taps "claim Portion" on a food listing
2. **Client -> backend** App sends a POST /reservation with the listingID
3. **Backend -> DB** Server checks for the listing and if there are aviliable ports decrments it by 1 before creating a reservation.
4. **Backend -> Client** Server returns a success message containing a conformation code.
5. **Client** shows the code to pick up food.

## Security and constraints

* **Campus verification:** Users can only register with a @okstate.edu email address
* **Stateless authenticaiton:** THe backend does not store session state or information, but the mobile app sends authentication with every requests 