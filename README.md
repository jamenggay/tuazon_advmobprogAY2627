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

