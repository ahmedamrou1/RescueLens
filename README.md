**RescueLens - An IOS app for identifying injured animals and recieving immediate care instructions**

I developed this app to improve my IOS app development skills. It was built in XCode and is entirely written in Swift. The app allows users to take or upload a photo of an injured animal where MobileNetV2, a robust machine learning model, will perform image classificaiton to determine what animal the photo contains (assuming, of course, that the user does not know what animal they are dealing with). The model will then pass the name of the animal to an OpenAI query with a prewritten prompt to generate immediate care instructions. Querying AI for such a critical matter could be seen as dangerous, but GPT4 is a well trained and is not supposed to put users in dangerous situations. Moreover, this project was more of an opportunity to get better at Swift than it is to be pushed out to users. 
