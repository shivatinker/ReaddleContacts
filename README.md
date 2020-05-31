# ReaddleContacts
Test task for Readdle 2020 internship

ReaddleContacts application, developed by Andrii Zinoviev (Telegram: @shivatinker)

## Installation
* Download zip
* Use 'pod install' in project directory
* Open project using workspace file

## Features
* Asynchronous contacts provider, that works in separate background `DispatchQueue`
* `MockContactsProvider`, that behaves like network API
* GravatarAPI implementation
* Random contact generation using [randomuser.me](https://randomuser.me)
* All async processes wrapped using [PromiseKit](https://github.com/mxcl/PromiseKit)
* Model-View-Presenter architecture for both `AllContacts` and `SingleContact` view controllers
* Error handling using `ErrorHandler` protocol
* Custom thread-safe `CachedStorage<K, V>` class, that supports auto-load of requested objects using provider closure, maximum cached objects and automatic cache clearing
* Avatars and contact info real-time cache, so even with 10000 contacts app not consuming more than 40Mb and running super smoothly (Come and test it!)
* Prefetched `TableView` and `CollectionView` subclasses, designed for smooth contacts displaying from cache
* Custom `AvatarView` combining avatar image and online status indicator
* Alamofire networking
* Custom push and pop animations of detailed info view. Pop animation is also interactive. Check it, it is very cool!
* Custom container view, that can contain both table and collection view
* Custom animation on transitioning between contact views: avatar go to a new place
* All animations implemented by-hand using `UIView.animate`, no animation frameworks
* Swipe gestures view change control
* Activity indication, driven by presenter with thread-safe task counting
* Dark theme support
* iPad support
* UI implemented **fully** in code using AutoLayout. Storyboard completely deleted
* No singletons. Dependency injection used (see `SceneDelegate`)
* SwiftLint code-style control. No warning in current build
* Unit tests, testing async API's
* Self-explaining and clean code (at least I tried :) ), comments in important places
* Markdown documentation in public methods in API
* Code formatted

Feel free to ask me about my code by zinoviev@stud.onu.edu.ua or Telegram
