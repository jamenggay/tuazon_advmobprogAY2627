# tuazon_advmobprog

# Laboratory Activity 3

Discussion

The three cart files each have their own function:
•	cart.dart turns the JSON data into Cart and CartProduct objects. 
•	cart_service.dart gets the cart data from GET /carts/user/1, reads the "carts" list, and converts it using Cart.fromJson(). 
•	cart_screen.dart calls the service when the screen opens, saves the result, and shows the loading, error, empty, or cart list screen. 

This keeps the same Screen → Service → Model structure: the screen doesn't handle the API URL, and the service doesn't handle the UI.

For the product details, the cart only passes the CartProduct.id to detail_screen.dart, and the detail screen uses that ID to get the full product. This allows both the product screen and cart to use the same detail screen. The cart total is calculated from the items because the user can change the quantity, which can make the API's original total outdated. CartProduct now allows quantity, total, and discountedTotal to change through updateQuantity(). This is a simple shortcut for now; in a bigger app, this changing data would usually be handled by a provider. Lastly, getCartById is simpler because GET /carts/1 gives one cart directly, so there is no need for the "carts" list or .map(). A cart ID is also different from a user ID—they only happen to look the same in DummyJSON's sample data.
DummyJSON's sample data.


