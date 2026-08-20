# tuazon_advmobprog

# Laboratory Activity 4

Discussion

The user feature is divided into three parts, with each part handling a specific responsibility.
 
•	models/user.dart holds the user data, with User.fromJson() converting the API response into a User object and displayName combining the first and last name. 
•	services/user_service.dart handles the API and saved user data: loginUser() sends the username and password to POST /auth/login, then saves the returned user details and token in SharedPreferences. 
•	screens/profile_screen.dart does not handle HTTP or JSON. It simply gets the saved user through getUser(), stores it in _user, and displays the profile information. Since the user data is saved on the phone during login, the profile can load the information quickly and even without an internet connection.

UserService also handles login persistence. isLoggedIn() checks if a token exists, while logout() clears the saved data. This allows the app to skip the sign-in form when a user is already logged in. The saved user ID also fixes the cart issue: instead of using a hardcoded current user from the DummyJson.  cart_screen.dart gets the logged-in user through getUser() and passes user.id to getCartsByUserId(), so each account gets its own cart. The two services do not directly call each other—the screen connects them by getting the user ID from UserService and passing it to CartService, while SharedPreferences stores the user data between screens.



