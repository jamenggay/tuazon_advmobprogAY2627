# tuazon_advmobprog

# Laboratory Activity 1

## Discussion

setState is a simple way to update the UI when something changes in just one widget. It's best
for small apps or when only a small part of the app needs to change. On the other hand, Provider is
used to manage and share data between different widgets more easily. It is more useful for bigger
apps because it helps keep the code cleaner and more organized


# Laboratory Activity 2

Discussion

The Product model is used to organize the data from the API. It uses Product.fromJson() to convert the JSON data into a Dart object. The ProductService is responsible for getting the data from the API using http.get() and returning a List<Product>, so the UI doesn't need to handle network requests. The ProductScreen calls the service in initState(), then uses setState() to update the screen and display the products.

The design pattern used is separation of concerns, where each file has its own responsibility. This makes the code easier to understand and maintain. It also uses a factory constructor for JSON conversion, Future and async/await for loading data without freezing the app, and the Provider pattern to manage the app's theme. 


# Laboratory Activity 3

Discussion

The three cart files each have their own function:
•	cart.dart turns the JSON data into Cart and CartProduct objects. 
•	cart_service.dart gets the cart data from GET /carts/user/1, reads the "carts" list, and converts it using Cart.fromJson(). 
•	cart_screen.dart calls the service when the screen opens, saves the result, and shows the loading, error, empty, or cart list screen. 

This keeps the same Screen → Service → Model structure: the screen doesn't handle the API URL, and the service doesn't handle the UI.

For the product details, the cart only passes the CartProduct.id to detail_screen.dart, and the detail screen uses that ID to get the full product. This allows both the product screen and cart to use the same detail screen. The cart total is calculated from the items because the user can change the quantity, which can make the API's original total outdated. CartProduct now allows quantity, total, and discountedTotal to change through updateQuantity(). This is a simple shortcut for now; in a bigger app, this changing data would usually be handled by a provider. Lastly, getCartById is simpler because GET /carts/1 gives one cart directly, so there is no need for the "carts" list or .map(). A cart ID is also different from a user ID—they only happen to look the same in DummyJSON's sample data.
DummyJSON's sample data.


