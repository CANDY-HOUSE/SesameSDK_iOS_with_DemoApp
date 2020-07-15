# Purpose
Introducing how to implement the Widget (Today Extension) feature with the SesameSDK.

# 1. Configure AppGroup in Xcode
Under Project setting.
1. Choose **App target** > **Signing & Capabilities** > + Capability (**App Groups**)
2. Add your group identifier. e.g. group.candyhouse.widget
3. Choose **Widget target** > **Signing & Capabilities** > + Capability (**App Groups**)
4. Add as the same group identifier as the App target. e.g. group.candyhouse.widget
5. Create a .plist file named **CHConfiguration.plist** and add an attribute **CHAppGroupApp** as String type and set your group ID as Value. Make sure the Target Membership is checked for both `App` and the `Widget`.

# 2. Adopt SesameSDK to your App and Widget
[SesameSDK](https://github.com/CANDY-HOUSE/SesameSDK_iOS_with_DemoApp/blob/master/README.md)

# 3. Test
1. Open your App and register a Sesame device.
2. Go to the Today Extension and see if the Sesame device appears.
