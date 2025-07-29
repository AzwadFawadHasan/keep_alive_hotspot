# 📶 keep_alive_hotspot
A Flutter app to keep your iPhone's hotspot connection truly alive—just like Android.
No more random disconnects. No more "why did my hotspot drop again?" moments.

## Why I Built This
Ever had your iPhone randomly disconnect from a hotspot for no good reason? Me too.
I used to commute by bus, juggling two old iPhones—an iPhone X (my main phone) and an iPhone 8+ (my dedicated hotspot). The problem: iOS loves to "save battery" by dropping hotspot connections if the device goes idle, even for a moment. Super annoying, especially when you're relying on a steady connection for work, streaming, or just staying sane on the road.

Android users don’t really have this issue—their hotspot connections stay rock solid.
So, I decided to build a fix for iOS and help anyone else suffering from this hotspot headache.

## What does keep_alive_hotspot do?
keep_alive_hotspot is a cross-platform Flutter app that helps prevent your iPhone's hotspot from disconnecting due to inactivity. It works by quietly keeping your hotspot session "alive" in the background, mimicking regular traffic, so iOS thinks the connection is always in use.

🟢 Keeps your iPhone hotspot active

🕹️ Works in the background

🔇 Silent operation (uses tricks like silent audio playback—no, you won’t hear anything!)

🥷 Low impact (minimal resource usage, battery-friendly as possible)

📱 Works for both iPhone and Android hotspots (but mainly fixes iOS's aggressive disconnects)

## How does it work?
The app uses a combination of background network requests and (optionally) silent audio playback to keep the host device "awake" in the eyes of iOS. You just launch the app, connect to your iPhone hotspot, and let it do its thing.
No jailbreak or complicated setup needed.

### Getting Started
Clone this repo
`git clone https://github.com/AzwadFawadHasan/keep_alive_hotspot.git`


`cd keep_alive_hotspot`

Install dependencies


`flutter pub get`
Run the app

On iOS or Android:


`flutter run`
Or open in your IDE of choice and click "Run"

### Usage:

Connect your primary device (e.g., iPhone X) to the hotspot of your secondary device (e.g., iPhone 8+)

Launch the app and let it run in the background

That’s it. Your connection should now stay alive much longer!

### Screenshots

<img width="1080" height="2220" alt="Screenshot_20250729_222435" src="https://github.com/user-attachments/assets/5c80df72-7039-40d1-98e2-f5b1d2d1c4ab" />

<img width="1080" height="2220" alt="Screenshot_20250729_222406" src="https://github.com/user-attachments/assets/ca4f6a00-0e10-4456-a98c-c0e6082dc660" />


#### Current Status
 Basic hotspot keep-alive for iOS

 Silent audio workaround for iOS disconnect bug

 Basic cross-platform support (Flutter)

 Advanced settings (interval, notifications, etc.) pending

 Release on App Store/Play Store pending


#### Contributing
Contributions, ideas, and bug reports are welcome!
Open an issue or pull request—or just drop a suggestion. Let’s make the iOS hotspot experience less painful for everyone.

#### Credits
## Credits

Built with ❤️ by [Azwad Fawad Hasan](https://azwadfawadhasan.github.io/resume/)  
iOS bug squasher: [Taiseer Rakiin Ahad](https://github.com/Taiseer517)



#### Fun fact
Yes, this project was born out of sheer frustration on a crowded bus somewhere in Dhaka.


